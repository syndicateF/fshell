pragma Singleton

import qs.utils
import XShell
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
    
    // Cache state from backend (fresh/stale/unavailable)
    property string cacheState: ""
    property string lastError: ""
    
    // Status properties
    property bool loading: false
    property bool hasError: false
    readonly property bool hasData: Object.keys(events).length > 0
    readonly property bool isStale: cacheState === "stale"

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

    // NOTE: daysUntil and isToday are computed by x-fetch backend
    // x-fetch holidays has a systemd timer that runs at midnight to refresh these values
    // UI is pure subscriber - no time computation here

    // Get meta (icon + color) based on event type from api.co.id
    // Types: "Public Holiday", "Joint Holiday", "Observance", "National Holiday"
    function getEventMeta(event: var): var {
        if (!event) return { icon: "event", color: Colours.palette.m3outline, type: "none" };
        
        const eventType = event.type || "";
        
        // LIBUR (is_holiday = true) - gets primary color (MERAH/accent)
        if (event.isHoliday) {
            return { icon: "event_available", color: Colours.palette.m3primary, type: "holiday" };
        }
        
        // CUTI BERSAMA (is_joint_holiday = true) - gets secondary color
        if (event.isJointHoliday) {
            return { icon: "event_note", color: Colours.palette.m3secondary, type: "joint" };
        }
        
        // OBSERVANCE (is_observance = true) - gets tertiary/muted color
        if (event.isObservance) {
            return { icon: "calendar_today", color: Colours.palette.m3tertiary, type: "observance" };
        }
        
        // Fallback
        return { icon: "event", color: Colours.palette.m3outline, type: "other" };
    }
    
    // Force refresh from network (user clicked refresh button)
    function forceRefresh(): void {
        triggerRefresh("manual");
    }
    
    // Trigger refresh with reason
    // UI only emits reason, backend decides based on policy table
    function triggerRefresh(reason: string): void {
        if (helperProc.running) return;
        helperProc.command = [root.helperPath, "holidays", "--reason=" + reason];
        helperProc.running = true;
    }
    
    // Pre-computed arrays from backend - UI is PURE SUBSCRIBER
    property var allEvents: []         // All events for the year
    property var upcomingEvents: []    // Next 10 upcoming events
    property var topUpcomingEvents: [] // Next 3 upcoming events (for main panel)
    property var thisMonthEvents: []
    property var todayEvent: null
    
    // Helper to convert snake_case JSON to camelCase object
    // All values come from cache - UI is pure subscriber
    function _mapEvent(ev: var): var {
        return {
            date: ev.date,
            dateFormatted: ev.date_formatted,
            name: ev.name,
            type: ev.type,
            daysUntil: ev.days_until,        // From cache (refreshed by x-fetch timer)
            dayNum: ev.day_num,
            monthShort: ev.month_short,
            isToday: ev.is_today,            // From cache (refreshed by x-fetch timer)
            isHoliday: ev.is_holiday,
            isJointHoliday: ev.is_joint_holiday,
            isObservance: ev.is_observance
        };
    }
    
    // Internal: parse cache JSON - map snake_case to camelCase
    function _parseCache(text: string): void {
        if (!text || !text.trim()) return;
        
        try {
            const json = JSON.parse(text);
            
            // Read cache metadata
            cacheState = json.state || "";
            lastError = json.last_error || "";
            
            // Map all events to camelCase
            const allRaw = json.all_events || [];
            const upcomingRaw = json.upcoming_events || [];
            const topUpcomingRaw = json.top_upcoming_events || [];
            const thisMonthRaw = json.this_month_events || [];
            const todayRaw = json.today_event;
            
            upcomingEvents = upcomingRaw.map(_mapEvent);
            topUpcomingEvents = topUpcomingRaw.map(_mapEvent);
            thisMonthEvents = thisMonthRaw.map(_mapEvent);
            allEvents = allRaw.map(_mapEvent);
            todayEvent = todayRaw ? _mapEvent(todayRaw) : null;
            
            // Keep events map for getEvent() lookup
            const newEvents = {};
            for (const ev of allRaw) {
                newEvents[ev.date] = _mapEvent(ev);
            }
            events = newEvents;
            
            hasError = false;
            loading = false;
        } catch (e) {
            console.warn("Holidays: Failed to parse cache:", e);
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
    
    // NOTE: Resume and startup refresh now handled by x-network daemon
    // Triggers x-fetch (weather + holidays) when IPv4 is assigned
    
    // Load cache on startup (refresh handled by x-network)
    Component.onCompleted: {
        cacheFile.reload();
    }
}
