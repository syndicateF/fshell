pragma Singleton

import qs.components.misc
import qs.config
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // =====================================================
    // PROPERTIES
    // =====================================================

    // All connected monitors from Hyprland
    readonly property var monitors: Hypr.monitors
    
    // Helper: monitor count (ObjectModel doesn't have .count, use .values.length)
    readonly property int monitorCount: monitors?.values?.length ?? 0

    // Currently selected monitor for settings
    property var selectedMonitor: null
    property string selectedMonitorName: selectedMonitor?.name ?? ""

    // Loading/applying state
    property bool applying: false
    property string applyError: ""

    // Pending changes (not yet applied)
    property var pendingChanges: ({})

    // Cached monitor data from hyprctl (includes availableModes)
    property var monitorData: ({})
    
    // =====================================================
    // GLOBAL DISPLAY SETTINGS & INFO
    // =====================================================
    
    // Global VRR setting (misc:vrr in Hyprland)
    property int globalVrr: 0
    
    // Global display info
    property var globalInfo: ({
        // Hyprland version
        hyprlandVersion: "",
        hyprlandCommit: "",
        hyprlandBranch: "",
        
        // System info
        systemName: "",
        kernelVersion: "",
        
        // Total monitors
        totalMonitors: 0,
        activeMonitors: 0,
        disabledMonitors: 0,
        
        // Total resolution (combined)
        totalWidth: 0,
        totalHeight: 0,
        
        // Global options
        directScanout: false,
        tearingEnabled: false,
        
        // Libraries
        aquamarineVersion: "",
        mesaVersion: ""
    })

    // =====================================================
    // PREVIEW & CONFIRMATION SYSTEM
    // =====================================================
    
    // Preview state
    property bool inPreviewMode: false
    property int previewCountdown: 15  // seconds before auto-revert
    property string previewConfigBackup: ""  // backup of original config
    property var previewMonitorBackup: ({})  // backup of original monitor data
    property int previewVrrBackup: 0  // backup VRR for preview
    
    // Confirmation dialog state
    property bool showConfirmDialog: false
    property string confirmDialogTitle: ""
    property string confirmDialogMessage: ""
    property var confirmDialogCallback: null
    property string confirmDialogType: "warning"  // "warning", "danger", "info"

    // Transform names mapping
    readonly property var transformNames: [
        qsTr("Normal"),           // 0
        qsTr("90°"),              // 1
        qsTr("180°"),             // 2
        qsTr("270°"),             // 3
        qsTr("Flipped"),          // 4
        qsTr("Flipped 90°"),      // 5
        qsTr("Flipped 180°"),     // 6
        qsTr("Flipped 270°")      // 7
    ]

    // VRR mode names (misc:vrr in Hyprland - GLOBAL setting)
    readonly property var vrrModes: [
        { value: 0, name: qsTr("Off"), description: qsTr("Variable refresh rate disabled") },
        { value: 1, name: qsTr("On"), description: qsTr("Always enabled - adapts to application frame rate") },
        { value: 2, name: qsTr("Fullscreen only"), description: qsTr("Only active for fullscreen applications") }
    ]

    // =====================================================
    // MONITOR CAPABILITIES
    // =====================================================
    
    // Check if any monitor supports VRR (high refresh rate as heuristic)
    readonly property bool anyMonitorSupportsVrr: {
        // Check if any monitor has refresh rate > 60Hz (likely VRR capable)
        for (const name of Object.keys(monitorData)) {
            const mon = monitorData[name];
            if (checkMonitorVrrCapable(mon)) {
                return true;
            }
        }
        return false;
    }
    
    // Check if a specific monitor likely supports VRR
    function checkMonitorVrrCapable(monData: var): bool {
        if (!monData) return false;
        
        // Check 1: If monitor has modes with refresh rate > 60Hz, likely VRR capable
        const modes = monData.availableModes ?? [];
        for (const mode of modes) {
            const match = mode.match(/@([\d.]+)Hz/);
            if (match && parseFloat(match[1]) > 65) {
                return true;
            }
        }
        
        // Check 2: Current refresh rate > 60Hz
        if ((monData.refreshRate ?? 60) > 65) {
            return true;
        }
        
        // Check 3: Detect known non-VRR types from description/make
        const desc = (monData.description ?? "").toLowerCase();
        const make = (monData.make ?? "").toLowerCase();
        
        // Projectors typically don't support VRR
        if (desc.includes("projector") || make.includes("projector") ||
            desc.includes("benq") && desc.includes("proj")) {
            return false;
        }
        
        // Most modern monitors support VRR, default to true if unclear
        return false; // Conservative: only enable if we detect high refresh rate
    }
    
    // Get monitor capabilities summary
    function getMonitorCapabilities(monitor: var): var {
        if (!monitor) return {};
        
        const cached = monitorData[monitor.name];
        if (!cached) return {};
        
        const modes = cached.availableModes ?? [];
        let maxRefresh = 60;
        let minRefresh = 999;
        
        for (const mode of modes) {
            const match = mode.match(/@([\d.]+)Hz/);
            if (match) {
                const rate = parseFloat(match[1]);
                maxRefresh = Math.max(maxRefresh, rate);
                minRefresh = Math.min(minRefresh, rate);
            }
        }
        
        return {
            // VRR capability (heuristic)
            vrrCapable: checkMonitorVrrCapable(cached),
            vrrReason: maxRefresh > 65 ? qsTr("High refresh rate detected") : qsTr("Standard refresh rate only"),
            
            // Refresh rate range
            maxRefreshRate: maxRefresh,
            minRefreshRate: minRefresh === 999 ? 60 : minRefresh,
            isHighRefresh: maxRefresh > 65,
            
            // Display type detection
            isInternal: monitor.name.startsWith("eDP"),
            isExternal: !monitor.name.startsWith("eDP"),
            connectionType: getConnectionType(monitor.name),
            
            // Features
            supportsHDR: false, // Hyprland doesn't expose HDR capability easily
            supports10bit: cached.currentFormat?.includes("10") ?? false,
            
            // Resolution info
            resolutionCount: getAvailableResolutions(monitor).length,
            modeCount: modes.length
        };
    }
    
    // Get connection type from monitor name
    function getConnectionType(name: string): string {
        if (name.startsWith("eDP")) return "Internal";
        if (name.startsWith("HDMI")) return "HDMI";
        if (name.startsWith("DP")) return "DisplayPort";
        if (name.startsWith("VGA")) return "VGA";
        if (name.startsWith("DVI")) return "DVI";
        return "Unknown";
    }

    // =====================================================
    // SIGNALS
    // =====================================================

    signal monitorConfigApplied(string monitorName)
    signal monitorConfigFailed(string monitorName, string error)
    signal monitorDataRefreshed()
    signal previewStarted()
    signal previewEnded(bool kept)
    signal confirmationRequested()

    // =====================================================
    // FUNCTIONS
    // =====================================================

    // Select a monitor for editing
    function selectMonitor(monitor: var): void {
        console.log("[Monitors] selectMonitor called. Current:", selectedMonitor?.name ?? "null", "New:", monitor?.name ?? "null");
        selectedMonitor = monitor;
        pendingChanges = {};
        applyError = "";
        // Refresh monitor data when selecting
        if (monitor) {
            refreshMonitorData();
        }
        console.log("[Monitors] selectedMonitor is now:", selectedMonitor?.name ?? "null");
    }

    // Refresh monitor data from hyprctl
    function refreshMonitorData(): void {
        monitorInfoProcess.running = true;
    }

    // Get cached data for a monitor
    function getMonitorData(monitorName: string): var {
        return monitorData[monitorName] ?? null;
    }

    // Get available modes for a monitor (from cached hyprctl data)
    function getAvailableModes(monitor: var): var {
        if (!monitor) return [];
        
        const cached = monitorData[monitor.name];
        if (!cached || !cached.availableModes) return [];
        
        // Parse availableModes from monitor data
        // Format: "WIDTHxHEIGHT@REFRESHHz"
        const modes = [];
        const rawModes = cached.availableModes;
        
        for (const mode of rawModes) {
            const match = mode.match(/(\d+)x(\d+)@([\d.]+)Hz/);
            if (match) {
                modes.push({
                    width: parseInt(match[1]),
                    height: parseInt(match[2]),
                    refreshRate: parseFloat(match[3]),
                    raw: mode
                });
            }
        }
        
        return modes;
    }

    // Get unique resolutions from available modes
    function getAvailableResolutions(monitor: var): var {
        const modes = getAvailableModes(monitor);
        const seen = new Set();
        const resolutions = [];
        
        for (const mode of modes) {
            const key = `${mode.width}x${mode.height}`;
            if (!seen.has(key)) {
                seen.add(key);
                resolutions.push({
                    width: mode.width,
                    height: mode.height,
                    label: key
                });
            }
        }
        
        return resolutions;
    }

    // Get available refresh rates for a resolution
    function getRefreshRatesForResolution(monitor: var, width: int, height: int): var {
        const modes = getAvailableModes(monitor);
        const rates = [];
        
        for (const mode of modes) {
            if (mode.width === width && mode.height === height) {
                rates.push(mode.refreshRate);
            }
        }
        
        return rates.sort((a, b) => b - a); // Descending
    }

    // Alias for getRefreshRatesForResolution
    function getAvailableRefreshRates(monitor: var, width: int, height: int): var {
        return getRefreshRatesForResolution(monitor, width, height);
    }

    // Set pending change
    function setPendingChange(key: string, value: var): void {
        const newChanges = Object.assign({}, pendingChanges);
        newChanges[key] = value;
        pendingChanges = newChanges;
        console.log("[Monitors] Set pending change:", key, "=", JSON.stringify(value));
        console.log("[Monitors] All pending changes:", JSON.stringify(pendingChanges));
    }

    // Set resolution (adds to pending changes)
    function setResolution(monitor: var, width: int, height: int): void {
        if (!monitor) return;
        setPendingChange(`${monitor.name}_resolution`, { width, height });
        // Also get appropriate refresh rate for this resolution
        const rates = getRefreshRatesForResolution(monitor, width, height);
        if (rates.length > 0) {
            setPendingChange(`${monitor.name}_refreshRate`, rates[0]);
        }
    }

    // Set refresh rate (adds to pending changes)
    function setRefreshRate(monitor: var, rate: real): void {
        if (!monitor) return;
        setPendingChange(`${monitor.name}_refreshRate`, rate);
    }

    // Set scale (adds to pending changes)
    function setScale(monitor: var, scale: real): void {
        if (!monitor) return;
        setPendingChange(`${monitor.name}_scale`, scale);
    }

    // Set transform (adds to pending changes)
    function setTransform(monitor: var, transform: int): void {
        if (!monitor) return;
        setPendingChange(`${monitor.name}_transform`, transform);
    }

    // Check if there are pending changes
    function hasPendingChanges(): bool {
        return Object.keys(pendingChanges).length > 0;
    }

    // Check if resolution has pending change
    function hasPendingResolution(monitor: var, width: int, height: int): bool {
        if (!monitor) return false;
        const key = `${monitor.name}_resolution`;
        const pending = pendingChanges[key];
        return pending && pending.width === width && pending.height === height;
    }

    // Check if refresh rate has pending change
    function hasPendingRefreshRate(monitor: var, rate: real): bool {
        if (!monitor) return false;
        const key = `${monitor.name}_refreshRate`;
        const pending = pendingChanges[key];
        return pending !== undefined && Math.abs(pending - rate) < 1;
    }

    // Check if scale has pending change
    function hasPendingScale(monitor: var, scale: real): bool {
        if (!monitor) return false;
        const key = `${monitor.name}_scale`;
        const pending = pendingChanges[key];
        return pending !== undefined && Math.abs(pending - scale) < 0.01;
    }

    // Check if transform has pending change
    function hasPendingTransform(monitor: var, transform: int): bool {
        if (!monitor) return false;
        const key = `${monitor.name}_transform`;
        const pending = pendingChanges[key];
        return pending !== undefined && pending === transform;
    }

    // Clear ALL pending changes
    function clearAllPendingChanges(): void {
        pendingChanges = {};
        pendingChangesChanged();
    }

    // Build monitor config string for hyprctl
    function buildMonitorConfig(monitor: var, changes: var): string {
        if (!monitor) return "";
        
        const name = monitor.name;
        
        // Get cached data for accurate current values
        const cached = monitorData[monitor.name] ?? {};
        
        // Extract changes for this specific monitor from pendingChanges
        // pendingChanges keys are like: "eDP-1_resolution", "eDP-1_scale" etc
        const resChange = changes[`${name}_resolution`];
        const rateChange = changes[`${name}_refreshRate`];
        const scaleChange = changes[`${name}_scale`];
        const transformChange = changes[`${name}_transform`];
        
        // Also support flat changes object (for backward compatibility)
        const width = resChange?.width ?? changes.width ?? cached.width ?? monitor.width ?? 1920;
        const height = resChange?.height ?? changes.height ?? cached.height ?? monitor.height ?? 1080;
        
        // IMPORTANT: Use cached refreshRate to avoid reset to 60Hz
        const currentRefreshRate = cached.refreshRate ?? monitor.refreshRate ?? 60;
        const refreshRate = rateChange ?? changes.refreshRate ?? currentRefreshRate;
        
        const x = changes.x ?? cached.x ?? monitor.x ?? 0;
        const y = changes.y ?? cached.y ?? monitor.y ?? 0;
        
        // Scale handling - round to 2 decimal places for Hyprland compatibility
        const currentScale = cached.scale ?? monitor.scale ?? 1;
        let scale = scaleChange ?? changes.scale ?? currentScale;
        // Round scale to avoid floating point issues
        scale = Math.round(scale * 100) / 100;
        
        const transform = transformChange ?? changes.transform ?? cached.transform ?? monitor.transform ?? 0;
        const mirror = changes.mirror ?? monitor.mirrorOf ?? "";
        
        // VRR from cached data (number) or monitor (boolean)
        const currentVrr = typeof cached.vrr === 'number' ? cached.vrr : (monitor.vrr ? 1 : 0);
        const vrr = changes.vrr ?? currentVrr;
        
        const disabled = changes.disabled ?? monitor.disabled ?? false;
        
        if (disabled) {
            return `${name},disable`;
        }
        
        if (mirror && mirror !== "none" && mirror !== "") {
            return `${name},preferred,auto,1,mirror,${mirror}`;
        }
        
        // Format: name,resolution@rate,position,scale,transform,vrr
        const rateStr = typeof refreshRate === 'number' ? refreshRate.toFixed(2) : "60.00";
        let config = `${name},${width}x${height}@${rateStr},${x}x${y},${scale}`;
        
        if (transform !== 0) {
            config += `,transform,${transform}`;
        }
        
        if (vrr > 0) {
            config += `,vrr,${vrr}`;
        }
        
        return config;
    }

    // =====================================================
    // CONFIRMATION DIALOG FUNCTIONS
    // =====================================================

    // Show confirmation dialog
    function requestConfirmation(title: string, message: string, type: string, callback: var): void {
        confirmDialogTitle = title;
        confirmDialogMessage = message;
        confirmDialogType = type;
        confirmDialogCallback = callback;
        showConfirmDialog = true;
        confirmationRequested();
    }

    // User confirmed action
    function confirmAction(): void {
        showConfirmDialog = false;
        if (confirmDialogCallback) {
            confirmDialogCallback();
            confirmDialogCallback = null;
        }
    }

    // User cancelled action
    function cancelAction(): void {
        showConfirmDialog = false;
        confirmDialogCallback = null;
    }

    // =====================================================
    // PREVIEW MODE FUNCTIONS
    // =====================================================

    // Start preview mode - apply config temporarily
    function startPreview(): void {
        if (!selectedMonitor || !hasPendingChanges()) return;
        
        // Backup current config
        const mon = selectedMonitor;
        previewMonitorBackup = {
            name: mon.name,
            width: mon.width,
            height: mon.height,
            refreshRate: getCurrentRefreshRate(mon),
            x: mon.x,
            y: mon.y,
            scale: mon.scale,
            transform: mon.transform,
            vrr: getCurrentVrr(mon)
        };
        previewConfigBackup = buildMonitorConfig(mon, {});
        
        // Apply new config
        applying = true;
        applyError = "";
        inPreviewMode = true;
        previewCountdown = 15;
        
        const config = buildMonitorConfig(selectedMonitor, pendingChanges);
        console.log("[Monitors] Starting preview with config:", config);
        
        previewProcess.command = ["hyprctl", "keyword", "monitor", config];
        previewProcess.running = true;
    }

    // Keep the preview changes
    function keepPreview(): void {
        if (!inPreviewMode) return;
        
        previewTimer.stop();
        inPreviewMode = false;
        previewCountdown = 15;
        pendingChanges = {};
        previewConfigBackup = "";
        previewMonitorBackup = {};
        
        refreshMonitorData();
        Hyprland.refreshMonitors();
        monitorConfigApplied(selectedMonitorName);
        previewEnded(true);
    }

    // Revert preview changes
    function revertPreview(): void {
        if (!inPreviewMode) return;
        
        previewTimer.stop();
        inPreviewMode = false;
        previewCountdown = 15;
        
        // Restore original config
        if (previewConfigBackup) {
            console.log("[Monitors] Reverting to:", previewConfigBackup);
            revertProcess.command = ["hyprctl", "keyword", "monitor", previewConfigBackup];
            revertProcess.running = true;
        }
        
        previewConfigBackup = "";
        previewMonitorBackup = {};
        previewEnded(false);
    }

    // Apply monitor configuration with preview
    function applyConfig(): void {
        if (!selectedMonitor || !hasPendingChanges()) return;
        
        // Start preview instead of direct apply
        startPreview();
    }

    // Apply and save to hyprland.conf (permanent)
    function applyAndSave(): void {
        if (!selectedMonitor || !hasPendingChanges()) return;
        
        // First apply with preview
        startPreview();
        
        // Then save to config file (implementation depends on user preference)
        // For now, just show a message that they need to save manually
    }

    // Toggle DPMS with confirmation and explanation
    function toggleDpms(monitor: var): void {
        if (!monitor) return;
        
        const status = monitor.dpmsStatus;
        const action = status ? qsTr("turn off") : qsTr("turn on");
        
        const explanation = qsTr("DPMS (Display Power Management Signaling) controls your monitor's power state.\n\n• When OFF: The display is turned off but remains connected. You can turn it back on anytime.\n• Unlike disabling a monitor, DPMS keeps the display configuration intact.\n\n");
        
        const warning = status 
            ? qsTr("Note: If this is your only active display, you'll need to use keyboard shortcuts (like moving the mouse or pressing a key) to wake it up.")
            : "";
        
        requestConfirmation(
            qsTr("Display Power Management"),
            explanation + qsTr("Do you want to %1 '%2'?").arg(action).arg(monitor.name) + (warning !== "" ? "\n\n" + warning : ""),
            status ? "warning" : "info",
            () => {
                dpmsProcess.command = ["hyprctl", "dispatch", "dpms", status ? "off" : "on", monitor.name];
                dpmsProcess.running = true;
            }
        );
    }

    // Set DPMS for single monitor with confirmation
    function setDpmsWithConfirm(monitor: var, on: bool): void {
        if (!monitor) return;
        
        const action = on ? qsTr("turn on") : qsTr("turn off");
        
        const explanation = qsTr("DPMS (Display Power Management Signaling) controls your monitor's power state.\n\n• When OFF: The display is turned off but remains connected.\n• Unlike disabling a monitor, DPMS keeps the display configuration intact.\n\n");
        
        const warning = !on 
            ? qsTr("\nNote: If this is your only active display, you'll need to use keyboard shortcuts (like moving the mouse or pressing a key) to wake it up.")
            : "";
        
        requestConfirmation(
            qsTr("Display Power Management"),
            explanation + qsTr("Do you want to %1 '%2'?").arg(action).arg(monitor.name) + warning,
            on ? "info" : "warning",
            () => {
                dpmsProcess.command = ["hyprctl", "dispatch", "dpms", on ? "on" : "off", monitor.name];
                dpmsProcess.running = true;
            }
        );
    }

    // Set DPMS for single monitor (no confirmation) - use for UI state sync
    function setDpms(monitor: var, on: bool): void {
        if (!monitor) return;
        dpmsProcess.command = ["hyprctl", "dispatch", "dpms", on ? "on" : "off", monitor.name];
        dpmsProcess.running = true;
    }

    // Set DPMS for all monitors with confirmation
    function setDpmsAll(on: bool): void {
        const action = on ? qsTr("turn on") : qsTr("turn off");
        
        requestConfirmation(
            qsTr("All Displays Power"),
            qsTr("Are you sure you want to %1 all displays?").arg(action),
            on ? "info" : "warning",
            () => {
                dpmsProcess.command = ["hyprctl", "dispatch", "dpms", on ? "on" : "off"];
                dpmsProcess.running = true;
            }
        );
    }

    // Quick actions
    function mirrorTo(source: var, target: var): void {
        if (!source || !target) return;
        
        const config = `${source.name},preferred,auto,1,mirror,${target.name}`;
        quickProcess.command = ["hyprctl", "keyword", "monitor", config];
        quickProcess.running = true;
    }

    function extendRight(monitor: var): void {
        if (!monitor) return;
        
        // Find the rightmost monitor and position this one next to it
        let maxX = 0;
        let maxWidth = 0;
        
        for (let i = 0; i < monitorCount; i++) {
            const mon = monitors.values[i];
            if (mon && mon.name !== monitor.name && mon.x + mon.width > maxX + maxWidth) {
                maxX = mon.x;
                maxWidth = mon.width;
            }
        }
        
        const newX = maxX + maxWidth;
        const config = `${monitor.name},preferred,${newX}x0,1`;
        quickProcess.command = ["hyprctl", "keyword", "monitor", config];
        quickProcess.running = true;
    }

    function extendLeft(monitor: var): void {
        if (!monitor) return;
        
        const config = `${monitor.name},preferred,0x0,1`;
        // Need to shift all other monitors
        quickProcess.command = ["hyprctl", "keyword", "monitor", config];
        quickProcess.running = true;
    }

    // Disable monitor with confirmation
    function disableMonitor(monitor: var): void {
        if (!monitor) return;
        
        requestConfirmation(
            qsTr("Disable Monitor"),
            qsTr("Are you sure you want to disable '%1'?\n\nThis will turn off the display output. You can re-enable it from another monitor or using keyboard shortcuts.").arg(monitor.name),
            "danger",
            () => {
                const config = `${monitor.name},disable`;
                quickProcess.command = ["hyprctl", "keyword", "monitor", config];
                quickProcess.running = true;
            }
        );
    }

    function enableMonitor(monitor: var): void {
        if (!monitor) return;
        
        const config = `${monitor.name},preferred,auto,1`;
        quickProcess.command = ["hyprctl", "keyword", "monitor", config];
        quickProcess.running = true;
    }

    // Clear pending changes for a specific monitor (revert without applying)
    function clearPendingChanges(monitor: var): void {
        if (!monitor) return;
        
        const name = monitor.name;
        let newPending = {};
        
        // Copy all changes except for this monitor
        for (const key of Object.keys(pendingChanges)) {
            if (!key.startsWith(name + "_")) {
                newPending[key] = pendingChanges[key];
            }
        }
        
        pendingChanges = newPending;
        pendingChangesChanged();
        console.log("[Monitors] Cleared pending changes for:", name);
    }

    // Check if a monitor has any pending changes
    function hasAnyPendingChanges(monitor: var): bool {
        if (!monitor) return false;
        
        const name = monitor.name;
        for (const key of Object.keys(pendingChanges)) {
            if (key.startsWith(name + "_")) {
                return true;
            }
        }
        return false;
    }

    // Reset monitor to default with confirmation
    function resetToDefault(monitor: var): void {
        if (!monitor) return;
        
        requestConfirmation(
            qsTr("Reset to Default"),
            qsTr("Are you sure you want to reset '%1' to default settings?\n\nThis will use the preferred resolution, auto position, and 1x scale.").arg(monitor.name),
            "warning",
            () => {
                pendingChanges = {};
                const config = `${monitor.name},preferred,auto,1`;
                quickProcess.command = ["hyprctl", "keyword", "monitor", config];
                quickProcess.running = true;
            }
        );
    }

    // Get current VRR value - uses GLOBAL misc:vrr setting
    function getCurrentVrr(monitor: var): int {
        // VRR is a GLOBAL setting in Hyprland (misc:vrr)
        // Per-monitor vrr in hyprctl output is just status, not config
        return globalVrr;
    }

    // Set global VRR (misc:vrr)
    function setGlobalVrr(value: int): void {
        console.log("[Monitors] Setting global VRR to:", value);
        vrrProcess.command = ["hyprctl", "keyword", "misc:vrr", String(value)];
        vrrProcess.running = true;
    }

    // Refresh global VRR setting
    function refreshGlobalVrr(): void {
        vrrGetProcess.running = true;
    }

    // Refresh all global info
    function refreshGlobalInfo(): void {
        versionProcess.running = true;
        // Monitor stats are calculated from monitorData
        updateMonitorStats();
    }

    // Update monitor statistics from cached data
    function updateMonitorStats(): void {
        const info = Object.assign({}, globalInfo);
        
        let total = 0;
        let active = 0;
        let disabled = 0;
        let maxX = 0;
        let maxY = 0;
        
        const names = Object.keys(monitorData);
        for (const name of names) {
            const mon = monitorData[name];
            if (!mon) continue;
            
            total++;
            if (mon.disabled) {
                disabled++;
            } else {
                active++;
                // Calculate total desktop area
                const rightEdge = (mon.x ?? 0) + (mon.width ?? 0);
                const bottomEdge = (mon.y ?? 0) + (mon.height ?? 0);
                if (rightEdge > maxX) maxX = rightEdge;
                if (bottomEdge > maxY) maxY = bottomEdge;
            }
        }
        
        info.totalMonitors = total;
        info.activeMonitors = active;
        info.disabledMonitors = disabled;
        info.totalWidth = maxX;
        info.totalHeight = maxY;
        
        globalInfo = info;
    }

    // Get current refresh rate from cached data
    function getCurrentRefreshRate(monitor: var): real {
        if (!monitor) return 60;
        const cached = monitorData[monitor.name];
        if (cached && cached.refreshRate) {
            return cached.refreshRate;
        }
        return monitor.refreshRate ?? 60;
    }

    // =====================================================
    // INTERNAL PROCESSES
    // =====================================================

    Process {
        id: applyProcess

        onExited: (exitCode, exitStatus) => {
            root.applying = false;
            
            if (exitCode === 0) {
                root.pendingChanges = {};
                root.monitorConfigApplied(root.selectedMonitorName);
                root.refreshMonitorData();
                Hyprland.refreshMonitors();
            } else {
                root.applyError = qsTr("Failed to apply configuration");
                root.monitorConfigFailed(root.selectedMonitorName, root.applyError);
            }
        }
    }

    // Preview process - applies config temporarily
    Process {
        id: previewProcess

        onExited: (exitCode, exitStatus) => {
            root.applying = false;
            
            if (exitCode === 0) {
                // Start countdown timer
                previewTimer.start();
                root.refreshMonitorData();
                Hyprland.refreshMonitors();
                root.previewStarted();
            } else {
                root.inPreviewMode = false;
                root.applyError = qsTr("Failed to apply preview configuration");
            }
        }
    }

    // Revert process - restores original config
    Process {
        id: revertProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.refreshMonitorData();
                Hyprland.refreshMonitors();
            } else {
                root.applyError = qsTr("Failed to revert configuration. You may need to restart.");
            }
        }
    }

    // Preview countdown timer
    Timer {
        id: previewTimer
        interval: 1000
        repeat: true
        running: false

        onTriggered: {
            root.previewCountdown--;
            
            if (root.previewCountdown <= 0) {
                // Auto-revert if user didn't respond
                stop();
                root.revertPreview();
            }
        }
    }

    Process {
        id: dpmsProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.refreshMonitorData();
                Hyprland.refreshMonitors();
            }
        }
    }

    Process {
        id: quickProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.refreshMonitorData();
                Hyprland.refreshMonitors();
            }
        }
    }

    // Process to fetch monitor data from hyprctl
    Process {
        id: monitorInfoProcess
        
        command: ["hyprctl", "monitors", "-j"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const monitors = JSON.parse(data);
                    const newData = {};
                    for (const mon of monitors) {
                        newData[mon.name] = mon;
                    }
                    root.monitorData = newData;
                    root.updateMonitorStats();
                    root.monitorDataRefreshed();
                } catch (e) {
                    console.warn("[Monitors] Failed to parse monitor data:", e);
                }
            }
        }
    }

    // Process to set VRR
    Process {
        id: vrrProcess
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.refreshGlobalVrr();
            } else {
                console.warn("[Monitors] Failed to set VRR");
            }
        }
    }

    // Process to get VRR setting
    Process {
        id: vrrGetProcess
        
        command: ["hyprctl", "getoption", "misc:vrr", "-j"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const result = JSON.parse(data);
                    root.globalVrr = result.int ?? 0;
                } catch (e) {
                    console.warn("[Monitors] Failed to parse VRR option:", e);
                }
            }
        }
    }

    // Process to get Hyprland version
    Process {
        id: versionProcess
        
        command: ["hyprctl", "version", "-j"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const result = JSON.parse(data);
                    const info = Object.assign({}, root.globalInfo);
                    info.hyprlandVersion = result.tag ?? result.branch ?? "Unknown";
                    info.hyprlandCommit = result.commit ? result.commit.substring(0, 8) : "";
                    info.hyprlandBranch = result.branch ?? "";
                    root.globalInfo = info;
                } catch (e) {
                    console.warn("[Monitors] Failed to parse version:", e);
                }
            }
        }
    }

    // Refresh monitor info periodically when in use (but not during preview)
    Timer {
        id: refreshTimer
        interval: 2000
        repeat: true
        running: root.selectedMonitor !== null && !root.inPreviewMode

        onTriggered: {
            root.refreshMonitorData();
            root.refreshGlobalVrr();
            Hyprland.refreshMonitors();
        }
    }

    // Initial data fetch
    Component.onCompleted: {
        console.log("[Monitors Service] monitorCount:", monitorCount);
        console.log("[Monitors Service] monitors.values:", JSON.stringify(monitors?.values?.map(m => m?.name)));
        refreshMonitorData();
        refreshGlobalVrr();
        refreshGlobalInfo();
    }
}
