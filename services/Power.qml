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
    
    property string platformProfile: "balanced"
    property string cpuGovernor: "powersave"
    property string epp: "balance_performance"
    property bool cpuBoostEnabled: true
    property int amdGpuProfile: 0
    
    property var availableProfiles: ["low-power", "balanced", "performance"]
    property var availableGovernors: ["powersave", "performance"]
    property var availableEpp: ["default", "performance", "balance_performance", "balance_power", "power"]
    
    property bool safeModeActive: false
    property string lastError: ""
    property bool available: false
    property bool amdGpuAvailable: false
    property bool eppControllable: true
    property var availableGpuProfiles: []  // Dynamic from backend: [{id, name}, ...]
    
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
    
    function refresh(): void {
        refreshProc.running = true;
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
            "BatteryAvailable", "BatteryInfo", "AvailableChargeTypes", "ChargeType", "ChargeTypeWritable"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 17) {
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
                }
                root._initialized = true;
            }
        }
    }
    
    // Periodic refresh (every 5 seconds)
    Timer {
        interval: 5000
        running: root.available
        repeat: true
        onTriggered: root.refresh()
    }

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
        onExited: root._busy = false
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
        onExited: root._busy = false
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
        onExited: root._busy = false
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
        onExited: root._busy = false
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
        onExited: root._busy = false
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
        onExited: root._busy = false
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
