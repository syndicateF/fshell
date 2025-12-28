pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Recorder Service - Reactive file-watching architecture
// State: ~/.local/state/caelestia/record/state.json
// Updated by caelestia record (Python)
// UI reactively updates via FileView watchChanges (inotify)
Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed

    // State file path
    readonly property string statePath: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/caelestia/record/state.json`

    // Start recording - uses execDetached for reliable execution
    function start(extraArgs): void {
        const args = extraArgs || [];
        let cmd = ["caelestia", "record"];
        if (args.length > 0) {
            cmd = cmd.concat(args);
        }
        Quickshell.execDetached(cmd);
    }

    // Stop recording (toggle)
    function stop(): void {
        Quickshell.execDetached(["caelestia", "record"]);
    }

    // Toggle pause
    function togglePause(): void {
        Quickshell.execDetached(["caelestia", "record", "-p"]);
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0
        property real startTime: 0

        reloadableId: "recorder"
    }

    // Internal: parse state JSON from file
    function _parseState(text: string): void {
        if (!text || !text.trim()) return;
        
        try {
            const state = JSON.parse(text);
            
            // Only update if actually changed to prevent unnecessary binding triggers
            if (props.running !== (state.running ?? false)) {
                props.running = state.running ?? false;
            }
            if (props.paused !== (state.paused ?? false)) {
                props.paused = state.paused ?? false;
            }
            if (props.startTime !== (state.startTime ?? 0)) {
                props.startTime = state.startTime ?? 0;
            }
            
            // Calculate elapsed time if running
            if (props.running && props.startTime > 0) {
                props.elapsed = Math.floor(Date.now() / 1000 - props.startTime);
            } else if (!props.running) {
                props.elapsed = 0;
            }
        } catch (e) {
            console.warn("Recorder: Failed to parse state:", e);
        }
    }

    // Reactive FileView with inotify-based file watching
    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true  // inotify - kernel event, NOT polling!
        
        onFileChanged: debounceTimer.restart()
        onLoaded: root._parseState(text())
        
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound) {
                console.warn("Recorder: Failed to load state:", err);
            }
        }
    }
    
    // Debounce timer to prevent rapid state changes from multiple inotify events
    Timer {
        id: debounceTimer
        interval: 50
        repeat: false
        onTriggered: stateFile.reload()
    }

    // Update elapsed time every second while running
    Connections {
        target: Time
        enabled: props.running && !props.paused

        function onSecondsChanged(): void {
            if (props.startTime > 0) {
                props.elapsed = Math.floor(Date.now() / 1000 - props.startTime);
            } else {
                props.elapsed++;
            }
        }
    }
}
