pragma Singleton

import qs.config
import qs.utils
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

// Weather Service - Reactive file-watching architecture
// Cache: ~/.cache/x-shell/weather.json
// Data updated by x-fetch daemon (systemd timer)
// UI reactively updates via FileView watchChanges
Singleton {
    id: root

    // Weather data from cache
    property string city: ""
    property int tempC: 0
    property int tempF: 0
    property int feelsLikeC: 0
    property int feelsLikeF: 0
    property int humidity: 0
    property int weatherCode: 0
    property string description: ""
    
    // Status properties
    property bool loading: false
    property bool hasError: false
    readonly property bool hasData: city !== ""
    
    // Computed properties for display
    readonly property string icon: hasData ? Icons.getWeatherIcon(weatherCode) : (hasError ? "cloud_off" : "cloud_alert")
    readonly property string temp: Config.services.useFahrenheit ? `${tempF}°F` : `${tempC}°C`
    readonly property string feelsLike: Config.services.useFahrenheit ? `${feelsLikeF}°F` : `${feelsLikeC}°C`
    readonly property string displayDescription: hasData ? description : (hasError ? qsTr("Offline") : qsTr("Loading..."))

    // Cache file path
    readonly property string cachePath: `${Paths.home}/.cache/x-shell/weather.json`
    readonly property string helperPath: `${Paths.home}/.local/bin/x-fetch`
    
    // Force refresh from network (bypasses cache TTL)
    // Only needed for manual refresh button - normal updates are via timer
    function forceRefresh(): void {
        if (helperProc.running) return;
        loading = true;
        hasError = false;
        
        let cmd = [root.helperPath, "weather", "--force"];
        const hasConfigLocation = Config.services.weatherLocation && Config.services.weatherLocation !== "";
        if (hasConfigLocation) {
            cmd.push("--city=" + Config.services.weatherLocation);
        }
        
        helperProc.command = cmd;
        helperProc.running = true;
    }
    
    // Internal: parse cache JSON
    function _parseCache(text: string): void {
        if (!text || !text.trim()) return;
        
        try {
            const json = JSON.parse(text);
            const data = json.data;
            
            if (data) {
                city = data.city || "";
                tempC = data.temp_c || 0;
                tempF = data.temp_f || 0;
                feelsLikeC = data.feels_like_c || 0;
                feelsLikeF = data.feels_like_f || 0;
                humidity = data.humidity || 0;
                weatherCode = data.weather_code || 0;
                description = data.description || "";
                hasError = false;
                loading = false;
            }
        } catch (e) {
            console.warn("Weather: Failed to parse cache:", e);
            // Don't set hasError - cache parse failure != network failure
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
    
    // Load cache on startup (sync with existing data if available)
    Component.onCompleted: {
        cacheFile.reload();
    }
}
