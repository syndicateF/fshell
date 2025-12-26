// Package cache handles reading and writing cache files with TTL awareness.
package cache

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"time"

	"x-fetch/internal/models"
)

// Common errors
var (
	ErrCacheNotFound = errors.New("cache file not found")
	ErrCacheExpired  = errors.New("cache expired")
	ErrCacheInvalid  = errors.New("cache file is invalid")
)

// Config represents the x-fetch configuration.
type Config struct {
	// WeatherLocation is the user's preferred location for weather.
	// Can be a city name (e.g., "Parepare") or coordinates (e.g., "-4.0135,119.6255").
	// If empty, automatic detection via GeoClue/IP is used.
	WeatherLocation string `json:"weather_location"`
}

// Manager handles cache operations for x-fetch.
type Manager struct {
	baseDir    string
	configDir  string
	userConfig *Config
}

// NewManager creates a new cache manager.
// It ensures the cache directory exists.
func NewManager() (*Manager, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	baseDir := filepath.Join(home, ".cache", "x-shell")
	if err := os.MkdirAll(baseDir, 0755); err != nil {
		return nil, err
	}

	configDir := filepath.Join(home, ".config", "x-shell")
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return nil, err
	}

	mgr := &Manager{baseDir: baseDir, configDir: configDir}
	mgr.loadConfig()

	return mgr, nil
}

// loadConfig loads user configuration from ~/.config/x-shell/config.json
func (m *Manager) loadConfig() {
	data, err := os.ReadFile(m.ConfigPath())
	if err != nil {
		m.userConfig = &Config{}
		return
	}

	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		m.userConfig = &Config{}
		return
	}

	m.userConfig = &cfg
}

// GetConfig returns the user configuration.
func (m *Manager) GetConfig() *Config {
	return m.userConfig
}

// ConfigPath returns the path to the config file.
func (m *Manager) ConfigPath() string {
	return filepath.Join(m.configDir, "config.json")
}

// BaseDir returns the cache base directory.
func (m *Manager) BaseDir() string {
	return m.baseDir
}

// WeatherPath returns the path to the weather cache file.
func (m *Manager) WeatherPath() string {
	return filepath.Join(m.baseDir, "weather.json")
}

// HolidaysPath returns the path to the holidays cache file.
func (m *Manager) HolidaysPath() string {
	return filepath.Join(m.baseDir, "holidays.json")
}

// PlanifyPath returns the path to the planify cache file.
func (m *Manager) PlanifyPath() string {
	return filepath.Join(m.baseDir, "planify.json")
}

// ReadWeather reads and validates the weather cache.
// Returns ErrCacheNotFound if file doesn't exist.
// Returns ErrCacheExpired if TTL has passed.
func (m *Manager) ReadWeather() (*models.WeatherCache, error) {
	data, err := os.ReadFile(m.WeatherPath())
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrCacheNotFound
	}
	if err != nil {
		return nil, err
	}

	var cache models.WeatherCache
	if err := json.Unmarshal(data, &cache); err != nil {
		return nil, ErrCacheInvalid
	}

	if cache.IsExpired() {
		return &cache, ErrCacheExpired
	}

	return &cache, nil
}

// ReadHolidays reads and validates the holidays cache.
// Returns ErrCacheNotFound if file doesn't exist.
// Returns ErrCacheExpired if TTL has passed.
func (m *Manager) ReadHolidays() (*models.HolidaysCache, error) {
	data, err := os.ReadFile(m.HolidaysPath())
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrCacheNotFound
	}
	if err != nil {
		return nil, err
	}

	var cache models.HolidaysCache
	if err := json.Unmarshal(data, &cache); err != nil {
		return nil, ErrCacheInvalid
	}

	if cache.IsExpired() {
		return &cache, ErrCacheExpired
	}

	return &cache, nil
}

// ReadPlanify reads and validates the planify cache.
// Returns ErrCacheNotFound if file doesn't exist.
// Returns ErrCacheExpired if TTL has passed.
func (m *Manager) ReadPlanify() (*models.PlanifyCache, error) {
	data, err := os.ReadFile(m.PlanifyPath())
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrCacheNotFound
	}
	if err != nil {
		return nil, err
	}

	var cache models.PlanifyCache
	if err := json.Unmarshal(data, &cache); err != nil {
		return nil, ErrCacheInvalid
	}

	if cache.IsExpired() {
		return &cache, ErrCacheExpired
	}

	return &cache, nil
}

// WriteWeather atomically writes weather data to cache.
func (m *Manager) WriteWeather(data models.WeatherData, ttlSeconds int) error {
	cache := models.WeatherCache{
		CacheMeta: models.CacheMeta{
			GeneratedAt: time.Now().UTC(),
			TTLSeconds:  ttlSeconds,
			SchemaVer:   1,
		},
		Data: data,
	}

	return m.writeJSON(m.WeatherPath(), cache)
}

// WriteHolidays atomically writes holidays data to cache.
func (m *Manager) WriteHolidays(data []models.HolidayEvent, ttlSeconds int) error {
	cache := models.HolidaysCache{
		CacheMeta: models.CacheMeta{
			GeneratedAt: time.Now().UTC(),
			TTLSeconds:  ttlSeconds,
			SchemaVer:   1,
		},
		Data: data,
	}

	return m.writeJSON(m.HolidaysPath(), cache)
}

// WritePlanify atomically writes planify data to cache.
func (m *Manager) WritePlanify(data []models.PlanifyTask, ttlSeconds int) error {
	cache := models.PlanifyCache{
		CacheMeta: models.CacheMeta{
			GeneratedAt: time.Now().UTC(),
			TTLSeconds:  ttlSeconds,
			SchemaVer:   1,
		},
		Data: data,
	}

	return m.writeJSON(m.PlanifyPath(), cache)
}

// writeJSON atomically writes JSON data to a file.
// Uses temp file + fsync + rename for crash safety.
func (m *Manager) writeJSON(path string, v any) error {
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return err
	}

	// Create temp file in same directory (required for atomic rename)
	f, err := os.CreateTemp(m.baseDir, "tmp-*.json")
	if err != nil {
		return err
	}
	tmpPath := f.Name()

	// Write data
	if _, err := f.Write(data); err != nil {
		f.Close()
		os.Remove(tmpPath)
		return err
	}

	// Sync to disk before rename (crash safety)
	if err := f.Sync(); err != nil {
		f.Close()
		os.Remove(tmpPath)
		return err
	}
	f.Close()

	// Atomic rename
	return os.Rename(tmpPath, path)
}
