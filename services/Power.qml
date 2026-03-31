pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Power service - D-Bus client for x-power-daemon (system bus)
Singleton {
    id: root

    // =====================================================
    // PROPERTIES (read from D-Bus)
    // =====================================================
    
    property string platformProfile: "unknown"  // Will be set by D-Bus
    property string cpuGovernor: "powersave"
    property string epp: "balance_performance"
    property bool cpuBoostEnabled: true
    property int amdGpuProfile: 0
    
    property var availableProfiles: []  // Empty until D-Bus reports actual capabilities
    property var availableGovernors: []  // Empty until D-Bus reports
    property var availableEpp: []  // Empty until D-Bus reports
    
    property bool safeModeActive: false
    property string lastError: ""
    property bool available: false
    property bool amdGpuAvailable: false
    property bool eppControllable: true
    property bool eppAvailable: true  // NEW: Whether EPP feature exists
    property var availableGpuProfiles: []  // Dynamic from backend: [{id, name}, ...]
    
    // Capability properties from daemon
    property string kernelVersion: "unknown"
    property string amdPstateMode: "unknown"
    property int policyCount: 0
    property int cpuCount: 0
    property string cpuDriver: "unknown"
    
    // Battery properties
    property bool batteryAvailable: false
    property var batteryInfo: ({  // Object with optional fields
        manufacturer: "unknown",
        model: "unknown",
        technology: "unknown",
        serial: "unknown",
        cycleCount: -1,
        energyFull: -1,
        energyFullDesign: -1,
        healthPercent: -1.0
    })
    property var availableChargeTypes: []
    property string chargeType: "unknown"
    property bool chargeTypeWritable: false
    
    // v3: Power source monitoring
    property string powerSource: "unknown"  // "ac", "battery", "unknown"
    property int batteryCapacity: 0
    property string batteryStatus: "Unknown"
    property bool acAdapterAvailable: false
    
    // v3: Temperature sensors
    property real cpuTemp: -1
    property real gpuTemp: -1
    property bool cpuTempAvailable: false
    property bool gpuTempAvailable: false
    
    // v3: Auto AC/Battery switching
    property bool autoSwitchEnabled: false
    property string acPresetProfile: ""
    property string acPresetGovernor: ""
    property string acPresetEpp: ""
    property bool acPresetBoost: true
    property int acPresetGpu: 0
    property string batteryPresetProfile: ""
    property string batteryPresetGovernor: ""
    property string batteryPresetEpp: ""
    property bool batteryPresetBoost: false
    property int batteryPresetGpu: 0
    
    // v3: Lenovo features
    property bool fanModeAvailable: false
    property int fanMode: 0
    property bool cameraPowerAvailable: false
    property bool cameraPower: false
    property bool usbChargingAvailable: false
    property bool usbCharging: false
    property bool fnLockAvailable: false
    property bool fnLock: false
    
    // Internal
    property bool _initialized: false
    property bool _busy: false

    // =====================================================
    // METHODS
    // =====================================================
    
    function setPlatformProfile(profile: string): void {
        if (_busy) return;
        _busy = true;
        setPlatformProfileProc.command = ["busctl", "--system", "call", 
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetPlatformProfile", "s", profile];
        setPlatformProfileProc.running = true;
    }
    
    function setEpp(value: string): void {
        if (_busy) return;
        _busy = true;
        setEppProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetEpp", "s", value];
        setEppProc.running = true;
    }
    
    function setCpuBoost(enabled: bool): void {
        if (_busy) return;
        _busy = true;
        setCpuBoostProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetCpuBoost", "b", enabled ? "true" : "false"];
        setCpuBoostProc.running = true;
    }
    
    function setGovernor(governor: string): void {
        if (_busy) return;
        _busy = true;
        setGovernorProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetGovernor", "s", governor];
        setGovernorProc.running = true;
    }
    
    function setAmdGpuProfile(profileId: int): void {
        if (_busy) return;
        _busy = true;
        setGpuProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetAmdGpuProfile", "u", profileId.toString()];
        setGpuProc.running = true;
    }
    
    function setChargeType(type: string): void {
        if (_busy) return;
        _busy = true;
        setChargeTypeProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetChargeType", "s", type];
        setChargeTypeProc.running = true;
    }
    
    function setAutoSwitch(enabled: bool): void {
        setAutoSwitchProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetAutoSwitch", "b", enabled ? "true" : "false"];
        setAutoSwitchProc.running = true;
    }
    
    // Pass-through: send raw user-selected values to daemon
    function setAcProfile(profile: string, governor: string, epp: string, boost: bool, gpu: int): void {
        setAcProfileProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetAcProfile", "sssbu",
            profile, governor, epp, boost ? "true" : "false", gpu.toString()];
        setAcProfileProc.running = true;
    }
    
    function setBatteryProfile(profile: string, governor: string, epp: string, boost: bool, gpu: int): void {
        setBatteryProfileProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetBatteryProfile", "sssbu",
            profile, governor, epp, boost ? "true" : "false", gpu.toString()];
        setBatteryProfileProc.running = true;
    }
    
    function setFanMode(mode: int): void {
        if (_busy) return;
        _busy = true;
        setFanModeProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetFanMode", "u", mode.toString()];
        setFanModeProc.running = true;
    }
    
    function setCameraPower(enabled: bool): void {
        if (_busy) return;
        _busy = true;
        setCameraPowerProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetCameraPower", "b", enabled ? "true" : "false"];
        setCameraPowerProc.running = true;
    }
    
    function setUsbCharging(enabled: bool): void {
        if (_busy) return;
        _busy = true;
        setUsbChargingProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetUsbCharging", "b", enabled ? "true" : "false"];
        setUsbChargingProc.running = true;
    }
    
    function setFnLock(enabled: bool): void {
        if (_busy) return;
        _busy = true;
        setFnLockProc.command = ["busctl", "--system", "call",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "SetFnLock", "b", enabled ? "true" : "false"];
        setFnLockProc.running = true;
    }
    
    function refresh(): void {
        refreshProc.running = true;
    }
    
    function refreshTemps(): void {
        tempRefreshProc.running = true;
    }

    // =====================================================
    // D-BUS READ PROCESSES
    // =====================================================
    
    // Check if service is available
    Process {
        id: checkProc
        command: ["busctl", "--system", "status", "org.xshell.Power"]
        onExited: (exitCode, _) => {
            root.available = (exitCode === 0);
            if (root.available) {
                root.refresh();
            }
        }
        Component.onCompleted: running = true
    }
    
    // Watch sysfs platform_profile for external changes (FN+Q, CLI, etc.)
    // NOTE: Only create the FileView AFTER init AND if platform profile is available
    Loader {
        active: root._initialized && root.availableProfiles.length > 0
        sourceComponent: FileView {
            id: profileWatcher
            path: "/sys/firmware/acpi/platform_profile"
            watchChanges: true
            onFileChanged: {
                // Debounce: only refresh if not already busy
                if (!root._busy && !refreshDebounce.running) {
                    refreshDebounce.start();
                }
            }
        }
    }

    // Watch sysfs governor for changes (auto-switch, external tools, etc.)
    // Governor changes affect EppControllable (governor=performance → EPP locked)
    Loader {
        active: root._initialized && root.availableGovernors.length > 0
        sourceComponent: FileView {
            id: governorWatcher
            path: "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
            watchChanges: true
            onFileChanged: {
                if (!root._busy && !refreshDebounce.running) {
                    refreshDebounce.start();
                }
            }
        }
    }

    // Watch sysfs EPP for changes (auto-switch applies EPP after governor)
    // Without this, EPP value stays stale in UI after auto-switch preset changes
    Loader {
        active: root._initialized && root.eppAvailable
        sourceComponent: FileView {
            id: eppWatcher
            path: "/sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference"
            watchChanges: true
            onFileChanged: {
                if (!root._busy && !refreshDebounce.running) {
                    refreshDebounce.start();
                }
            }
        }
    }

    // Debounce timer - sysfs watchers restart this on each change.
    // 1000ms ensures apply_preset (300ms between steps × 4) completes
    // before a single clean refresh, avoiding intermediate state flicker.
    Timer {
        id: refreshDebounce
        interval: 1000
        onTriggered: root.refresh()
    }
    
    // Refresh all properties
    Process {
        id: refreshProc
        command: ["busctl", "--system", "get-property", 
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "PlatformProfile", "CpuGovernor", "EnergyPerformancePreference", 
            "CpuBoostEnabled", "AvailableProfiles", "AvailableGovernors", "AvailableEpp", 
            "SafeModeActive", "AmdGpuAvailable", "AmdGpuProfile", "EppControllable",
            "AvailableAmdGpuProfiles",
            // Battery properties
            "BatteryAvailable", "BatteryInfo", "AvailableChargeTypes", "ChargeType", "ChargeTypeWritable",
            // Capability properties
            "EppAvailable", "KernelVersion", "AmdPstateMode", "PolicyCount", "CpuCount", "CpuDriver",
            // v3: Power source + temps + auto-switch + Lenovo
            "PowerSource", "BatteryCapacity", "BatteryStatus", "AcAdapterAvailable",
            "CpuTemp", "GpuTemp", "CpuTempAvailable", "GpuTempAvailable",
            "AutoSwitchEnabled",
            "AcPresetProfile", "AcPresetGovernor", "AcPresetEpp", "AcPresetBoost", "AcPresetGpu",
            "BatteryPresetProfile", "BatteryPresetGovernor", "BatteryPresetEpp", "BatteryPresetBoost", "BatteryPresetGpu",
            "FanModeAvailable", "FanMode", "CameraPowerAvailable", "CameraPower",
            "UsbChargingAvailable", "UsbCharging", "FnLockAvailable", "FnLock"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 23) {
                    root.platformProfile = parseDbusString(lines[0]);
                    root.cpuGovernor = parseDbusString(lines[1]);
                    root.epp = parseDbusString(lines[2]);
                    root.cpuBoostEnabled = parseDbusBoolean(lines[3]);
                    root.availableProfiles = parseDbusStringArray(lines[4]);
                    root.availableGovernors = parseDbusStringArray(lines[5]);
                    root.availableEpp = parseDbusStringArray(lines[6]);
                    root.safeModeActive = parseDbusBoolean(lines[7]);
                    root.amdGpuAvailable = parseDbusBoolean(lines[8]);
                    root.amdGpuProfile = parseDbusInt(lines[9]);
                    root.eppControllable = parseDbusBoolean(lines[10]);
                    root.availableGpuProfiles = parseDbusGpuProfiles(lines[11]);
                    // Battery properties
                    root.batteryAvailable = parseDbusBoolean(lines[12]);
                    root.batteryInfo = parseDbusBatteryInfo(lines[13]);
                    root.availableChargeTypes = parseDbusStringArray(lines[14]);
                    root.chargeType = parseDbusString(lines[15]);
                    root.chargeTypeWritable = parseDbusBoolean(lines[16]);
                    // Capability properties
                    root.eppAvailable = parseDbusBoolean(lines[17]);
                    root.kernelVersion = parseDbusString(lines[18]);
                    root.amdPstateMode = parseDbusString(lines[19]);
                    root.policyCount = parseDbusInt(lines[20]);
                    root.cpuCount = parseDbusInt(lines[21]);
                    root.cpuDriver = parseDbusString(lines[22]);
                }
                // v3 properties (23+)
                if (lines.length >= 50) {
                    root.powerSource = parseDbusString(lines[23]);
                    root.batteryCapacity = parseDbusInt(lines[24]);
                    root.batteryStatus = parseDbusString(lines[25]);
                    root.acAdapterAvailable = parseDbusBoolean(lines[26]);
                    root.cpuTemp = parseDbusDouble(lines[27]);
                    root.gpuTemp = parseDbusDouble(lines[28]);
                    root.cpuTempAvailable = parseDbusBoolean(lines[29]);
                    root.gpuTempAvailable = parseDbusBoolean(lines[30]);
                    root.autoSwitchEnabled = parseDbusBoolean(lines[31]);
                    // Stored presets (32-41)
                    root.acPresetProfile = parseDbusString(lines[32]);
                    root.acPresetGovernor = parseDbusString(lines[33]);
                    root.acPresetEpp = parseDbusString(lines[34]);
                    root.acPresetBoost = parseDbusBoolean(lines[35]);
                    root.acPresetGpu = parseDbusInt(lines[36]);
                    root.batteryPresetProfile = parseDbusString(lines[37]);
                    root.batteryPresetGovernor = parseDbusString(lines[38]);
                    root.batteryPresetEpp = parseDbusString(lines[39]);
                    root.batteryPresetBoost = parseDbusBoolean(lines[40]);
                    root.batteryPresetGpu = parseDbusInt(lines[41]);
                    // Lenovo features (42-49)
                    root.fanModeAvailable = parseDbusBoolean(lines[42]);
                    root.fanMode = parseDbusInt(lines[43]);
                    root.cameraPowerAvailable = parseDbusBoolean(lines[44]);
                    root.cameraPower = parseDbusBoolean(lines[45]);
                    root.usbChargingAvailable = parseDbusBoolean(lines[46]);
                    root.usbCharging = parseDbusBoolean(lines[47]);
                    root.fnLockAvailable = parseDbusBoolean(lines[48]);
                    root.fnLock = parseDbusBoolean(lines[49]);
                }
                root._initialized = true;
            }
        }
    }
    
    // Temperature refresh (polled separately, more frequently)
    Process {
        id: tempRefreshProc
        command: ["busctl", "--system", "get-property",
            "org.xshell.Power", "/org/xshell/Power", "org.xshell.Power",
            "CpuTemp", "GpuTemp", "PowerSource", "BatteryCapacity", "BatteryStatus"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 5) {
                    root.cpuTemp = parseDbusDouble(lines[0]);
                    root.gpuTemp = parseDbusDouble(lines[1]);
                    root.powerSource = parseDbusString(lines[2]);
                    root.batteryCapacity = parseDbusInt(lines[3]);
                    root.batteryStatus = parseDbusString(lines[4]);
                }
            }
        }
    }
    
    // Poll temperatures and power status every 10s
    Timer {
        interval: 10000
        running: root._initialized && root.available
        repeat: true
        onTriggered: root.refreshTemps()
    }

    
    // =====================================================
    // EVENT-DRIVEN REFRESH (Clean Architecture)
    // =====================================================
    // NO periodic polling! NO UI-triggered refresh! Data stays fresh via:
    // 1. On startup (checkProc → refresh)
    // 2. After each successful action (write procs → refresh)
    // 3. On sysfs file changes (FileView watchers → debounced refresh)
    // UI components just bind to service properties (reactive)

    // =====================================================
    // D-BUS WRITE PROCESSES
    // =====================================================
    
    Process {
        id: setPlatformProfileProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                if (text.includes("true")) {
                    root.refresh();
                }
            }
        }
    }
    
    Process {
        id: setEppProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                if (text.includes("true")) {
                    root.refresh();
                }
            }
        }
    }
    
    Process {
        id: setCpuBoostProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                if (text.includes("true")) {
                    root.refresh();
                }
            }
        }
    }
    
    Process {
        id: setGpuProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                if (text.includes("true")) {
                    root.refresh();
                }
            }
        }
    }
    
    Process {
        id: setGovernorProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                if (text.includes("true")) {
                    root.refresh();
                }
            }
        }
    }
    
    Process {
        id: setChargeTypeProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                if (text.includes("true")) {
                    root.refresh();
                }
            }
        }
    }
    
    Process {
        id: setAutoSwitchProc
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
    }
    
    Process {
        id: setAcProfileProc
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
    }
    
    Process {
        id: setBatteryProfileProc
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
    }
    
    Process {
        id: setFanModeProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                root.refresh();
            }
        }
    }
    
    Process {
        id: setCameraPowerProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                root.refresh();
            }
        }
    }
    
    Process {
        id: setUsbChargingProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                root.refresh();
            }
        }
    }
    
    Process {
        id: setFnLockProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                root.refresh();
            }
        }
    }

    // =====================================================
    // HELPERS
    // =====================================================
    
    function parseDbusString(line: string): string {
        // Format: s "value"
        const match = line.match(/^s\s+"(.*)"/);
        return match ? match[1] : "";
    }
    
    function parseDbusBoolean(line: string): bool {
        // Format: b true/false
        return line.includes("true");
    }
    
    function parseDbusStringArray(line: string): var {
        // Format: as N "val1" "val2" ...
        const matches = line.match(/"([^"]+)"/g);
        return matches ? matches.map(s => s.replace(/"/g, "")) : [];
    }
    
    function parseDbusInt(line: string): int {
        // Format: u 0
        const match = line.match(/^u\s+(\d+)/);
        return match ? parseInt(match[1]) : 0;
    }
    
    function parseDbusDouble(line: string): real {
        // Format: d 41.25
        const match = line.match(/^d\s+([\d.-]+)/);
        return match ? parseFloat(match[1]) : -1;
    }
    
    function parseDbusGpuProfiles(line: string): var {
        // Format: a(us) N 1 "3d Fullscreen" 3 "Video" ...
        // Parse tuples of (uint, string) into [{id, name}, ...]
        const result = [];
        // Match patterns like: number "string"
        const regex = /(\d+)\s+"([^"]+)"/g;
        let match;
        while ((match = regex.exec(line)) !== null) {
            result.push({ id: parseInt(match[1]), name: match[2] });
        }
        return result;
    }
    
    function parseDbusBatteryInfo(line: string): var {
        // Format: (ssssixxd) "manufacturer" "model" "technology" "serial" cycles energyFull energyFullDesign health
        // Example: (ssssixxd) "Sunwoda" "L20D4PC1" "Li-poly" "3242" 321 70140000 80000000 87.675
        const parts = line.match(/\(ssssixxd\)\s+"([^"]*)"\s+"([^"]*)"\s+"([^"]*)"\s+"([^"]*)"\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?[\d.]+)/);
        if (parts) {
            return {
                manufacturer: parts[1] !== "unknown" ? parts[1] : "",
                model: parts[2] !== "unknown" ? parts[2] : "",
                technology: parts[3] !== "unknown" ? parts[3] : "",
                serial: parts[4] !== "unknown" ? parts[4] : "",
                cycleCount: parseInt(parts[5]),
                energyFull: parseInt(parts[6]),
                energyFullDesign: parseInt(parts[7]),
                healthPercent: parseFloat(parts[8])
            };
        }
        return {
            manufacturer: "",
            model: "",
            technology: "",
            serial: "",
            cycleCount: -1,
            energyFull: -1,
            energyFullDesign: -1,
            healthPercent: -1.0
        };
    }
}
