pragma Singleton

import qs.config
import qs.utils
import XShell
import Quickshell
import Quickshell.Io
import QtQuick

// Weather Service - Reactive file-watching architecture
// Cache: ~/.cache/x-shell/weather.json
// Data updated by x-fetch daemon (systemd timer)
// UI reactively updates via FileView watchChanges
// NOTE: Pure subscriber - all logic in backend, UI just reads
Singleton {
    id: root

    // Current weather data from cache
    property string city: ""
    property int tempC: 0
    property int feelsLikeC: 0
    property int humidity: 0
    property int weatherCode: 0
    property string description: ""
    property bool isDay: true           // NEW: for day/night icons
    property real windSpeedKmh: 0       // NEW
    property real uvIndex: 0            // NEW
    
    // Daily forecast (7 days) - array of objects
    property var dailyForecast: []
    
    // Hourly forecast (24 hours) - array of objects
    property var hourlyForecast: []
    
    // Version counter to force reactive binding updates when arrays change
    property int forecastVersion: 0
    
    // Convenience accessors for today's data from daily[0]
    readonly property string sunrise: dailyForecast[0]?.sunrise ?? ""
    readonly property string sunset: dailyForecast[0]?.sunset ?? ""
    readonly property int todayTempMax: dailyForecast[0]?.temp_max_c ?? 0
    readonly property int todayTempMin: dailyForecast[0]?.temp_min_c ?? 0
    
    // Cache state from backend (fresh/stale/unavailable)
    property string cacheState: ""  // Backend decides, UI just reads
    property string lastError: ""   // Reason for stale state
    
    // Status properties
    property bool loading: false
    property bool hasError: false
    readonly property bool hasData: city !== ""
    readonly property bool isStale: cacheState === "stale"
    
    // Computed properties for display
    readonly property string icon: hasData ? Icons.getWeatherIcon(weatherCode, isDay) : (hasError ? "cloud_off" : "cloud_alert")
    readonly property string temp: `${tempC}°C`
    readonly property string feelsLike: `${feelsLikeC}°C`
    readonly property string displayDescription: hasData ? description : (hasError ? qsTr("Offline") : qsTr("Loading..."))

    // Cache file path
    readonly property string cachePath: `${Paths.home}/.cache/x-shell/weather.json`
    readonly property string helperPath: `${Paths.home}/.local/bin/x-fetch`
    
    // Get daily forecast by day offset (0 = today)
    function getDailyForecast(dayOffset) {
        if (dayOffset >= 0 && dayOffset < dailyForecast.length) {
            return dailyForecast[dayOffset];
        }
        return null;
    }
    
    // Force refresh from network (user clicked refresh button)
    // Uses reason=manual which always bypasses policy
    function forceRefresh(): void {
        triggerRefresh("manual");
    }
    
    // Trigger refresh with reason
    // UI only emits reason, backend decides based on policy table
    // Valid reasons: startup, resume, popout, manual
    function triggerRefresh(reason: string): void {
        if (helperProc.running) return;
        
        let cmd = [root.helperPath, "weather", "--reason=" + reason];
        const hasConfigLocation = Config.services.weatherLocation && Config.services.weatherLocation !== "";
        if (hasConfigLocation) {
            cmd.push("--city=" + Config.services.weatherLocation);
        }
        
        helperProc.command = cmd;
        helperProc.running = true;
    }
    
    // Internal: parse cache JSON (read-only, no logic)
    function _parseCache(text: string): void {
        if (!text || !text.trim()) return;
        
        try {
            const json = JSON.parse(text);
            const data = json.data;
            
            // Read cache metadata (backend decides state, UI just reads)
            cacheState = json.state || "";
            lastError = json.last_error || "";
            
            if (data) {
                city = data.city || "";
                tempC = data.temp_c || 0;
                feelsLikeC = data.feels_like_c || 0;
                humidity = data.humidity || 0;
                weatherCode = data.weather_code || 0;
                description = data.description || "";
                isDay = data.is_day ?? true;
                windSpeedKmh = data.wind_speed_kmh || 0;
                uvIndex = data.uv_index || 0;
                hasError = false;
                loading = false;
            }
            
            // Read forecast arrays and increment version to trigger reactive binding updates
            dailyForecast = json.daily || [];
            hourlyForecast = json.hourly || [];
            forecastVersion++;
            
        } catch (e) {
            console.warn("Weather: Failed to parse cache:", e);
        }
    }

    // Reactive FileView with inotify-based file watching
    FileView {
        id: cacheFile
        path: root.cachePath
        watchChanges: true  // inotify watching!
        
        onFileChanged: {
            // Debounce: multiple inotify events can fire for single write
            debounceTimer.restart();
        }
        
        onLoaded: {
            root._parseCache(text());
        }
        
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound) {
                console.warn("Weather: Failed to load cache:", err);
            }
            // File not found is normal on first run - x-fetch timer will create it
        }
    }
    
    // Debounce timer to prevent rapid reloads from multiple inotify events
    Timer {
        id: debounceTimer
        interval: 150  // 150ms debounce
        repeat: false
        onTriggered: {
            cacheFile.reload();
        }
    }
    
    // Helper process for force refresh only
    Process {
        id: helperProc
        
        onExited: (code, status) => {
            root.loading = false;
            if (code !== 0 && !root.hasData) {
                root.hasError = true;
            }
            // FileView will automatically pick up new cache via watchChanges
        }
    }
    
    // NOTE: Resume refresh now handled by x-network daemon
    // See: internal/netlink/watcher.go - triggers x-fetch on IPv4 assignment after resume
    
    // NOTE: Startup refresh also handled by x-network daemon
    // Triggers x-fetch when first IPv4 is assigned after boot
    
    // Load cache on startup (refresh handled by x-network)
    Component.onCompleted: {
        cacheFile.reload();
    }
}
