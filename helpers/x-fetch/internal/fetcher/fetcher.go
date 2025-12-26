// Package fetcher handles HTTP requests to external APIs and location services.
package fetcher

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"x-fetch/internal/models"
)

const (
	// API endpoints
	wttrURL      = "https://wttr.in/%s?format=j1"
	hariLiburURL = "https://hari-libur-api.vercel.app/api?year=%d"

	// Timeouts
	httpTimeout = 10 * time.Second
)

// Fetcher performs HTTP requests to external APIs.
type Fetcher struct {
	client *http.Client
}

// New creates a new Fetcher with sensible defaults.
func New() *Fetcher {
	return &Fetcher{
		client: &http.Client{
			Timeout: httpTimeout,
		},
	}
}

// FetchLocation detects the user's location using GeoClue D-Bus, with IP fallback.
// Returns coordinates as "lat,long" string for wttr.in API.
func (f *Fetcher) FetchLocation(ctx context.Context) (string, error) {
	// Strategy 1: Try GeoClue via gdbus (OS-grade location)
	coords, err := fetchGeoClueLocation(ctx)
	if err == nil && coords != "" {
		return coords, nil
	}

	// Strategy 2: Fallback to IP-based geolocation (less accurate)
	return f.fetchIPLocation(ctx)
}

// fetchGeoClueLocation queries GeoClue D-Bus service for coordinates.
// Uses gdbus command to avoid adding D-Bus dependencies.
func fetchGeoClueLocation(ctx context.Context) (string, error) {
	// Create GeoClue client via D-Bus
	cmd := exec.CommandContext(ctx, "gdbus", "call", "--system",
		"--dest", "org.freedesktop.GeoClue2",
		"--object-path", "/org/freedesktop/GeoClue2/Manager",
		"--method", "org.freedesktop.GeoClue2.Manager.GetClient")

	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("geoclue GetClient failed: %w", err)
	}

	// Parse client path from output like "('/org/freedesktop/GeoClue2/Client/1',)"
	clientPath := strings.Trim(string(output), "(')\n, ")

	// Set DesktopId (required by GeoClue)
	cmd = exec.CommandContext(ctx, "gdbus", "call", "--system",
		"--dest", "org.freedesktop.GeoClue2",
		"--object-path", clientPath,
		"--method", "org.freedesktop.DBus.Properties.Set",
		"org.freedesktop.GeoClue2.Client", "DesktopId",
		"<'x-fetch'>")
	cmd.Run() // Ignore errors

	// Start location updates
	cmd = exec.CommandContext(ctx, "gdbus", "call", "--system",
		"--dest", "org.freedesktop.GeoClue2",
		"--object-path", clientPath,
		"--method", "org.freedesktop.GeoClue2.Client.Start")
	cmd.Run()

	// Wait a moment for location fix
	time.Sleep(500 * time.Millisecond)

	// Get location
	cmd = exec.CommandContext(ctx, "gdbus", "call", "--system",
		"--dest", "org.freedesktop.GeoClue2",
		"--object-path", clientPath,
		"--method", "org.freedesktop.DBus.Properties.Get",
		"org.freedesktop.GeoClue2.Client", "Location")
	output, err = cmd.Output()
	if err != nil {
		return "", fmt.Errorf("geoclue get Location failed: %w", err)
	}

	// Parse location object path
	locPath := strings.Trim(string(output), "(<>'\n, )")

	if locPath == "" || locPath == "/" {
		return "", fmt.Errorf("no location available")
	}

	// Get latitude
	cmd = exec.CommandContext(ctx, "gdbus", "call", "--system",
		"--dest", "org.freedesktop.GeoClue2",
		"--object-path", locPath,
		"--method", "org.freedesktop.DBus.Properties.Get",
		"org.freedesktop.GeoClue2.Location", "Latitude")
	latOut, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("get latitude failed: %w", err)
	}

	// Get longitude
	cmd = exec.CommandContext(ctx, "gdbus", "call", "--system",
		"--dest", "org.freedesktop.GeoClue2",
		"--object-path", locPath,
		"--method", "org.freedesktop.DBus.Properties.Get",
		"org.freedesktop.GeoClue2.Location", "Longitude")
	lonOut, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("get longitude failed: %w", err)
	}

	// Parse lat/long from output like "(<1.234>,)"
	lat := parseGdbusDouble(string(latOut))
	lon := parseGdbusDouble(string(lonOut))

	if lat == 0 && lon == 0 {
		return "", fmt.Errorf("invalid coordinates")
	}

	// Stop client
	cmd = exec.CommandContext(ctx, "gdbus", "call", "--system",
		"--dest", "org.freedesktop.GeoClue2",
		"--object-path", clientPath,
		"--method", "org.freedesktop.GeoClue2.Client.Stop")
	cmd.Run()

	return fmt.Sprintf("%.6f,%.6f", lat, lon), nil
}

// parseGdbusDouble parses a double from gdbus output like "(<-4.0135>,)"
func parseGdbusDouble(s string) float64 {
	s = strings.TrimSpace(s)
	s = strings.Trim(s, "(<>',)\n")
	v, _ := strconv.ParseFloat(s, 64)
	return v
}

// fetchIPLocation falls back to IP-based geolocation.
func (f *Fetcher) fetchIPLocation(ctx context.Context) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://ipinfo.io/json", nil)
	if err != nil {
		return "", fmt.Errorf("create request: %w", err)
	}

	resp, err := f.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("fetch location: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read body: %w", err)
	}

	var result struct {
		City string `json:"city"`
		Loc  string `json:"loc"` // "lat,long"
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("parse json: %w", err)
	}

	// Prefer coordinates if available, fallback to city name
	if result.Loc != "" {
		return result.Loc, nil
	}
	if result.City != "" {
		return result.City, nil
	}
	return "", fmt.Errorf("empty location in response")
}

// FetchWeather fetches weather data for a given location (city name or coordinates).
// Returns WeatherData with proper city name extracted from API response.
func (f *Fetcher) FetchWeather(ctx context.Context, location string) (models.WeatherData, error) {
	// URL-encode only spaces in city names, preserve commas for coordinates
	encodedLoc := strings.ReplaceAll(location, " ", "+")
	apiURL := fmt.Sprintf(wttrURL, encodedLoc)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, apiURL, nil)
	if err != nil {
		return models.WeatherData{}, fmt.Errorf("create request: %w", err)
	}

	resp, err := f.client.Do(req)
	if err != nil {
		return models.WeatherData{}, fmt.Errorf("fetch weather: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return models.WeatherData{}, fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return models.WeatherData{}, fmt.Errorf("read body: %w", err)
	}

	var wttr models.WttrResponse
	if err := json.Unmarshal(body, &wttr); err != nil {
		return models.WeatherData{}, fmt.Errorf("parse json: %w", err)
	}

	if len(wttr.CurrentCondition) == 0 {
		return models.WeatherData{}, fmt.Errorf("no weather data in response")
	}

	// Extract city name from API response (works for both city and coordinate queries)
	city := extractCityName(wttr)

	cc := wttr.CurrentCondition[0]
	desc := ""
	if len(cc.WeatherDesc) > 0 {
		desc = cc.WeatherDesc[0].Value
	}

	return models.WeatherData{
		City:        city,
		TempC:       mustAtoi(cc.TempC),
		TempF:       mustAtoi(cc.TempF),
		FeelsLikeC:  mustAtoi(cc.FeelsLikeC),
		FeelsLikeF:  mustAtoi(cc.FeelsLikeF),
		Humidity:    mustAtoi(cc.Humidity),
		WeatherCode: mustAtoi(cc.WeatherCode),
		Description: desc,
	}, nil
}

// extractCityName gets the city name from wttr.in response.
func extractCityName(wttr models.WttrResponse) string {
	if len(wttr.NearestArea) == 0 {
		return "Unknown"
	}
	area := wttr.NearestArea[0]

	if len(area.AreaName) > 0 && area.AreaName[0].Value != "" {
		return area.AreaName[0].Value
	}
	if len(area.Region) > 0 && area.Region[0].Value != "" {
		return area.Region[0].Value
	}
	return "Unknown"
}

// FetchHolidays fetches holidays for a given year.
func (f *Fetcher) FetchHolidays(ctx context.Context, year int) ([]models.HolidayEvent, error) {
	apiURL := fmt.Sprintf(hariLiburURL, year)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, apiURL, nil)
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	resp, err := f.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch holidays: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read body: %w", err)
	}

	var apiEvents []models.HariLiburEvent
	if err := json.Unmarshal(body, &apiEvents); err != nil {
		return nil, fmt.Errorf("parse json: %w", err)
	}

	// Convert to our model
	events := make([]models.HolidayEvent, 0, len(apiEvents))
	for _, e := range apiEvents {
		events = append(events, models.HolidayEvent{
			Date:              e.EventDate,
			Name:              e.EventName,
			IsNationalHoliday: e.IsNationalHoliday,
		})
	}

	return events, nil
}

// mustAtoi converts string to int, returns 0 on error.
func mustAtoi(s string) int {
	v, _ := strconv.Atoi(s)
	return v
}
