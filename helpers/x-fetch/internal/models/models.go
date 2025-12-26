// Package models defines the data structures for cache files.
// These structures serve as the contract between the Go helper and QML.
package models

import "time"

// CacheMeta contains metadata about a cache file.
type CacheMeta struct {
	GeneratedAt time.Time `json:"generated_at"`
	TTLSeconds  int       `json:"ttl_seconds"`
	SchemaVer   int       `json:"schema_version"`
}

// IsExpired checks if the cache has exceeded its TTL.
func (m CacheMeta) IsExpired() bool {
	expiry := m.GeneratedAt.Add(time.Duration(m.TTLSeconds) * time.Second)
	return time.Now().After(expiry)
}

// WeatherCache represents the cached weather data.
type WeatherCache struct {
	CacheMeta
	Data WeatherData `json:"data"`
}

// WeatherData contains the actual weather information.
type WeatherData struct {
	City        string `json:"city"`
	TempC       int    `json:"temp_c"`
	TempF       int    `json:"temp_f"`
	FeelsLikeC  int    `json:"feels_like_c"`
	FeelsLikeF  int    `json:"feels_like_f"`
	Humidity    int    `json:"humidity"`
	WeatherCode int    `json:"weather_code"`
	Description string `json:"description"`
}

// HolidaysCache represents the cached holidays data.
type HolidaysCache struct {
	CacheMeta
	Data []HolidayEvent `json:"data"`
}

// HolidayEvent represents a single holiday or observance.
type HolidayEvent struct {
	Date              string `json:"date"`
	Name              string `json:"name"`
	IsNationalHoliday bool   `json:"is_national_holiday"`
}

// WttrResponse represents the response from wttr.in API.
type WttrResponse struct {
	CurrentCondition []WttrCondition `json:"current_condition"`
	NearestArea      []WttrArea      `json:"nearest_area"`
}

// WttrArea represents location info from wttr.in API.
type WttrArea struct {
	AreaName []WttrTextValue `json:"areaName"`
	Region   []WttrTextValue `json:"region"`
	Country  []WttrTextValue `json:"country"`
}

// WttrTextValue is a common pattern in wttr.in for text values.
type WttrTextValue struct {
	Value string `json:"value"`
}

// WttrCondition represents a single weather condition from wttr.in.
type WttrCondition struct {
	TempC       string            `json:"temp_C"`
	TempF       string            `json:"temp_F"`
	FeelsLikeC  string            `json:"FeelsLikeC"`
	FeelsLikeF  string            `json:"FeelsLikeF"`
	Humidity    string            `json:"humidity"`
	WeatherCode string            `json:"weatherCode"`
	WeatherDesc []WttrWeatherDesc `json:"weatherDesc"`
}

// WttrWeatherDesc represents weather description from wttr.in.
type WttrWeatherDesc struct {
	Value string `json:"value"`
}

// HariLiburEvent represents an event from hari-libur-api.
type HariLiburEvent struct {
	EventDate         string `json:"event_date"`
	EventName         string `json:"event_name"`
	IsNationalHoliday bool   `json:"is_national_holiday"`
}

// IPInfoResponse represents the response from ipinfo.io for location detection.
type IPInfoResponse struct {
	City string `json:"city"`
}

// PlanifyCache represents the cached planify tasks.
type PlanifyCache struct {
	CacheMeta
	Data []PlanifyTask `json:"data"`
}

// PlanifyTask represents a single task from Planify.
type PlanifyTask struct {
	ID       string `json:"id"`
	Content  string `json:"content"`
	DueDate  string `json:"due_date"`
	Priority int    `json:"priority"`
	IsToday  bool   `json:"is_today"`
	HasDate  bool   `json:"has_date"`
}
