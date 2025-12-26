pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

// Planify Service - Reactive file-watching architecture
// Cache: ~/.cache/x-shell/planify.json
// Data exported by x-fetch daemon from Planify SQLite database
// UI reactively updates via FileView watchChanges
Singleton {
    id: root

    // Today's tasks from Planify
    property var todayTasks: []
    property bool loading: false
    property bool hasError: false
    readonly property bool hasData: todayTasks.length > 0

    // Cache file path
    readonly property string cachePath: `${Paths.home}/.cache/x-shell/planify.json`
    readonly property string helperPath: `${Paths.home}/.local/bin/x-fetch`

    // Force refresh (re-export from SQLite)
    function forceRefresh(): void {
        if (helperProc.running) return;
        loading = true;
        hasError = false;
        helperProc.command = [root.helperPath, "planify", "--force"];
        helperProc.running = true;
    }

    // Internal: parse cache JSON
    function _parseCache(text: string): void {
        if (!text || !text.trim()) return;
        
        try {
            const json = JSON.parse(text);
            const items = json.data || [];
            
            root.todayTasks = items.map(item => ({
                id: item.id,
                content: item.content,
                dueDate: item.due_date || "",
                priority: item.priority || 0,
                isToday: item.is_today || false,
                hasDate: item.has_date || false
            }));
            
            hasError = false;
            loading = false;
        } catch (e) {
            console.warn("Planify: Failed to parse cache:", e);
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
                console.warn("Planify: Failed to load cache:", err);
            }
            // File not found is normal if Planify not installed
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
