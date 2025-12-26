// x-fetch is a one-shot helper for fetching and caching external data.
// Designed for systemd timer execution with file locking.
//
// Usage:
//
//	x-fetch weather                    Fetch weather data
//	x-fetch holidays                   Fetch holidays data
//	x-fetch planify                    Export Planify tasks to cache
//	x-fetch daemon                     Check all resources, fetch if expired
//	x-fetch all                        Fetch all resources (force)
//	x-fetch weather --force            Force refresh even if cache is valid
//	x-fetch weather --city=Parepare    Use specific city
//
// Environment:
//
//	X_FETCH_CITY    Override city for weather (e.g., export X_FETCH_CITY=Parepare)
//
// Exit codes:
//
//	0  Success (cache was valid or updated successfully)
//	1  Fetch failed (network error, API error)
//	2  Invalid arguments
//	3  Lock conflict (another instance running)
package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"x-fetch/internal/cache"
	"x-fetch/internal/fetcher"
)

const (
	// TTL values
	weatherTTL  = 30 * 60      // 30 minutes
	holidaysTTL = 24 * 60 * 60 // 24 hours
	planifyTTL  = 5 * 60       // 5 minutes (local data, cheap to refresh)
)

// Exit codes
const (
	exitSuccess      = 0
	exitFetchFailed  = 1
	exitInvalidArgs  = 2
	exitLockConflict = 3
)

func main() {
	os.Exit(run(os.Args[1:]))
}

func run(args []string) int {
	if len(args) == 0 {
		printUsage()
		return exitInvalidArgs
	}

	cmd := args[0]
	force := false
	city := "" // Will be resolved with priority chain

	// Parse additional args
	for _, arg := range args[1:] {
		if arg == "--force" {
			force = true
		} else if strings.HasPrefix(arg, "--city=") {
			city = strings.TrimPrefix(arg, "--city=")
		}
	}

	mgr, err := cache.NewManager()
	if err != nil {
		fmt.Fprintf(os.Stderr, "cache init failed: %v\n", err)
		return exitFetchFailed
	}

	// Location priority chain: CLI arg > env var > config file
	if city == "" {
		city = os.Getenv("X_FETCH_CITY")
	}
	if city == "" {
		cfg := mgr.GetConfig()
		if cfg != nil && cfg.WeatherLocation != "" {
			city = cfg.WeatherLocation
		}
	}

	// Acquire lock for daemon/all commands to prevent concurrent runs
	if cmd == "daemon" || cmd == "all" {
		lockPath := filepath.Join(mgr.BaseDir(), "x-fetch.lock")
		unlock, err := acquireLock(lockPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "lock failed: %v\n", err)
			return exitLockConflict
		}
		defer unlock()
	}

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	f := fetcher.New()

	switch cmd {
	case "weather":
		if err := fetchWeather(ctx, mgr, f, force, city); err != nil {
			fmt.Fprintf(os.Stderr, "weather: %v\n", err)
			return exitFetchFailed
		}
	case "holidays":
		if err := fetchHolidays(ctx, mgr, f, force); err != nil {
			fmt.Fprintf(os.Stderr, "holidays: %v\n", err)
			return exitFetchFailed
		}
	case "planify":
		if err := fetchPlanify(mgr, force); err != nil {
			fmt.Fprintf(os.Stderr, "planify: %v\n", err)
			return exitFetchFailed
		}
	case "daemon":
		// Daemon mode: check all resources, only fetch if expired
		// Designed for systemd timer - runs periodically
		var anyErr error

		if err := fetchWeather(ctx, mgr, f, false, city); err != nil {
			fmt.Fprintf(os.Stderr, "daemon weather: %v\n", err)
			anyErr = err
		}

		if err := fetchHolidays(ctx, mgr, f, false); err != nil {
			fmt.Fprintf(os.Stderr, "daemon holidays: %v\n", err)
			anyErr = err
		}

		if err := fetchPlanify(mgr, false); err != nil {
			fmt.Fprintf(os.Stderr, "daemon planify: %v\n", err)
			anyErr = err
		}

		if anyErr != nil {
			return exitFetchFailed
		}
	case "all":
		// Fetch all, report any errors (force mode)
		var weatherErr, holidaysErr, planifyErr error
		weatherErr = fetchWeather(ctx, mgr, f, force, city)
		holidaysErr = fetchHolidays(ctx, mgr, f, force)
		planifyErr = fetchPlanify(mgr, force)

		if weatherErr != nil {
			fmt.Fprintf(os.Stderr, "weather: %v\n", weatherErr)
		}
		if holidaysErr != nil {
			fmt.Fprintf(os.Stderr, "holidays: %v\n", holidaysErr)
		}
		if planifyErr != nil {
			fmt.Fprintf(os.Stderr, "planify: %v\n", planifyErr)
		}
		if weatherErr != nil || holidaysErr != nil || planifyErr != nil {
			return exitFetchFailed
		}
	default:
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", cmd)
		printUsage()
		return exitInvalidArgs
	}

	return exitSuccess
}

// acquireLock attempts to acquire an exclusive lock on the given file.
// Returns an unlock function and nil on success, or error if lock is held.
func acquireLock(path string) (func(), error) {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0644)
	if err != nil {
		return nil, err
	}

	// Try non-blocking exclusive lock
	err = syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB)
	if err != nil {
		f.Close()
		return nil, fmt.Errorf("another instance is running")
	}

	return func() {
		syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
		f.Close()
	}, nil
}

func fetchWeather(ctx context.Context, mgr *cache.Manager, f *fetcher.Fetcher, force bool, city string) error {
	// Check cache first
	if !force {
		_, err := mgr.ReadWeather()
		if err == nil {
			// Cache is valid, nothing to do
			return nil
		}
		// Only proceed if cache is expired or not found
		if !errors.Is(err, cache.ErrCacheExpired) && !errors.Is(err, cache.ErrCacheNotFound) && !errors.Is(err, cache.ErrCacheInvalid) {
			return err
		}
	}

	// Strategy 1: Use configured city if provided
	if city == "" {
		// Strategy 2: Fallback to IP-based location
		var err error
		city, err = f.FetchLocation(ctx)
		if err != nil {
			return fmt.Errorf("detect location: %w", err)
		}
	}

	// Fetch weather by city name
	data, err := f.FetchWeather(ctx, city)
	if err != nil {
		return fmt.Errorf("fetch: %w", err)
	}

	// Write to cache
	if err := mgr.WriteWeather(data, weatherTTL); err != nil {
		return fmt.Errorf("write cache: %w", err)
	}

	return nil
}

func fetchHolidays(ctx context.Context, mgr *cache.Manager, f *fetcher.Fetcher, force bool) error {
	// Check cache first
	if !force {
		_, err := mgr.ReadHolidays()
		if err == nil {
			// Cache is valid, nothing to do
			return nil
		}
		// Only proceed if cache is expired or not found
		if !errors.Is(err, cache.ErrCacheExpired) && !errors.Is(err, cache.ErrCacheNotFound) && !errors.Is(err, cache.ErrCacheInvalid) {
			return err
		}
	}

	// Fetch current year and next year
	year := time.Now().Year()

	currentEvents, err := f.FetchHolidays(ctx, year)
	if err != nil {
		return fmt.Errorf("fetch year %d: %w", year, err)
	}

	nextEvents, err := f.FetchHolidays(ctx, year+1)
	if err != nil {
		// Next year might not be available yet, that's OK
		nextEvents = nil
	}

	// Merge events
	allEvents := append(currentEvents, nextEvents...)

	// Write to cache
	if err := mgr.WriteHolidays(allEvents, holidaysTTL); err != nil {
		return fmt.Errorf("write cache: %w", err)
	}

	return nil
}

func fetchPlanify(mgr *cache.Manager, force bool) error {
	// Check cache first
	if !force {
		_, err := mgr.ReadPlanify()
		if err == nil {
			// Cache is valid, nothing to do
			return nil
		}
		// Only proceed if cache is expired or not found
		if !errors.Is(err, cache.ErrCacheExpired) && !errors.Is(err, cache.ErrCacheNotFound) && !errors.Is(err, cache.ErrCacheInvalid) {
			return err
		}
	}

	// Fetch from local Planify database
	tasks, err := fetcher.FetchPlanifyTasks()
	if err != nil {
		return fmt.Errorf("fetch: %w", err)
	}

	// Write to cache
	if err := mgr.WritePlanify(tasks, planifyTTL); err != nil {
		return fmt.Errorf("write cache: %w", err)
	}

	return nil
}

func printUsage() {
	fmt.Fprintln(os.Stderr, "Usage: x-fetch <command> [options]")
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "Commands:")
	fmt.Fprintln(os.Stderr, "  weather    Fetch weather data")
	fmt.Fprintln(os.Stderr, "  holidays   Fetch holidays data")
	fmt.Fprintln(os.Stderr, "  planify    Export Planify tasks to cache")
	fmt.Fprintln(os.Stderr, "  daemon     Check all resources, fetch if expired (for systemd timer)")
	fmt.Fprintln(os.Stderr, "  all        Fetch all resources")
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "Options:")
	fmt.Fprintln(os.Stderr, "  --force          Force refresh even if cache is valid")
	fmt.Fprintln(os.Stderr, "  --city=NAME      Use specific city (e.g., --city=Parepare)")
	fmt.Fprintln(os.Stderr, "")
	fmt.Fprintln(os.Stderr, "Environment:")
	fmt.Fprintln(os.Stderr, "  X_FETCH_CITY     Override city for weather")
}
