pragma Singleton

import qs.utils
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

// Holidays Service - Reactive file-watching architecture
// Cache: ~/.cache/x-shell/holidays.json
// Data updated by x-fetch daemon (systemd timer)
// UI reactively updates via FileView watchChanges
Singleton {
    id: root

    // All events map: "YYYY-MM-DD" -> { name, isNationalHoliday }
    property var events: ({})
    
    // Status properties
    property bool loading: false
    property bool hasError: false
    readonly property bool hasData: Object.keys(events).length > 0

    // Cache file path
    readonly property string cachePath: `${Paths.home}/.cache/x-shell/holidays.json`
    readonly property string helperPath: `${Paths.home}/.local/bin/x-fetch`

    // Get event for specific date
    function getEvent(date: date): var {
        const key = Qt.formatDate(date, "yyyy-MM-dd");
        return events[key] || null;
    }

    // Check if date has any event
    function hasEvent(date: date): bool {
        return getEvent(date) !== null;
    }

    // Check if date is a national holiday (libur resmi)
    function isNationalHoliday(date: date): bool {
        const ev = getEvent(date);
        return ev !== null && ev.isNationalHoliday;
    }

    // Get today's event if any
    function getTodayEvent(): var {
        return getEvent(new Date());
    }

    // Get meta (icon + color) based on is_national_holiday
    function getEventMeta(event: var): var {
        if (!event) return { icon: "event", color: Colours.palette.m3outline };
        
        if (event.isNationalHoliday) {
            return { 
                icon: "flag", 
                color: Colours.palette.m3primary 
            };
        }
        
        return { 
            icon: "event", 
            color: Colours.palette.m3outline 
        };
    }
    
    // Force refresh from network (bypasses cache TTL)
    function forceRefresh(): void {
        if (helperProc.running) return;
        loading = true;
        hasError = false;
        helperProc.command = [root.helperPath, "holidays", "--force"];
        helperProc.running = true;
    }
    
    // Internal: parse cache JSON
    function _parseCache(text: string): void {
        if (!text || !text.trim()) return;
        
        try {
            const json = JSON.parse(text);
            const newEvents = {};
            
            for (const ev of json.data || []) {
                newEvents[ev.date] = {
                    name: ev.name,
                    isNationalHoliday: ev.is_national_holiday
                };
            }
            
            events = newEvents;
            hasError = false;
            loading = false;
        } catch (e) {
            console.warn("Holidays: Failed to parse cache:", e);
            // Don't set hasError - cache parse failure != network failure
        }
    }

    // Events this month (computed, re-evaluates when events changes)
    readonly property var thisMonthEvents: {
        const today = new Date();
        const year = today.getFullYear();
        const month = today.getMonth();
        const todayStr = Qt.formatDate(today, "yyyy-MM-dd");
        const result = [];
        
        const dates = Object.keys(events).sort();
        
        for (const dateStr of dates) {
            const d = new Date(dateStr);
            if (d.getFullYear() === year && d.getMonth() === month) {
                result.push({
                    date: dateStr,
                    displayDate: Qt.formatDate(d, "d MMM"),
                    dayName: Qt.locale().dayName(d.getDay()).substring(0, 3),
                    name: events[dateStr].name,
                    isNationalHoliday: events[dateStr].isNationalHoliday,
                    isPast: dateStr < todayStr,
                    isToday: dateStr === todayStr
                });
            }
        }
        
        return result;
    }

    // Upcoming events (next 5 from today)
    readonly property var upcomingEvents: {
        const today = new Date();
        const todayStr = Qt.formatDate(today, "yyyy-MM-dd");
        const result = [];
        
        const dates = Object.keys(events).sort();
        
        for (const dateStr of dates) {
            if (dateStr > todayStr && result.length < 5) {
                result.push({
                    date: dateStr,
                    displayDate: Qt.formatDate(new Date(dateStr), "d MMM"),
                    name: events[dateStr].name,
                    isNationalHoliday: events[dateStr].isNationalHoliday
                });
            }
        }
        
        return result;
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
                console.warn("Holidays: Failed to load cache:", err);
            }
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
    
    // Load cache on startup
    Component.onCompleted: {
        cacheFile.reload();
    }
}
