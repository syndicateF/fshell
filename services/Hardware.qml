pragma Singleton

import qs.components.misc
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // =====================================================
    // CPU PROPERTIES
    // =====================================================
    
    // CPU model name
    readonly property string cpuModel: cpuModelInternal.trim()
    property string cpuModelInternal: "Unknown CPU"
    
    // CPU core/thread count
    readonly property int cpuCores: cpuCoresInternal
    readonly property int cpuThreads: cpuThreadsInternal
    property int cpuCoresInternal: 0
    property int cpuThreadsInternal: 0
    
    // CPU frequency (MHz)
    readonly property real cpuFreqCurrent: cpuFreqCurrentInternal / 1000 // Convert to MHz
    readonly property real cpuFreqMin: cpuFreqMinInternal / 1000
    readonly property real cpuFreqMax: cpuFreqMaxInternal / 1000
    property real cpuFreqCurrentInternal: 0
    property real cpuFreqMinInternal: 0
    property real cpuFreqMaxInternal: 0
    
    // CPU temperature (Celsius)
    readonly property real cpuTemp: cpuTempInternal / 1000
    property real cpuTempInternal: 0
    
    // CPU governor & driver
    readonly property string cpuGovernor: cpuGovernorInternal.trim()
    readonly property string cpuDriver: cpuDriverInternal.trim()
    readonly property var cpuGovernorsAvailable: cpuGovernorsAvailableInternal.trim().split(" ").filter(g => g.length > 0)
    property string cpuGovernorInternal: "unknown"
    property string cpuDriverInternal: "unknown"
    property string cpuGovernorsAvailableInternal: ""
    
    // CPU boost
    readonly property bool cpuBoostSupported: cpuBoostSupportedInternal
    readonly property bool cpuBoostEnabled: cpuBoostInternal === "1"
    property bool cpuBoostSupportedInternal: false
    property string cpuBoostInternal: "0"
    
    // AMD P-State EPP
    readonly property string cpuEpp: cpuEppInternal.trim()
    readonly property var cpuEppAvailable: cpuEppAvailableInternal.trim().split(" ").filter(e => e.length > 0)
    property string cpuEppInternal: ""
    property string cpuEppAvailableInternal: ""
    
    // CPU utilization (percentage)
    readonly property real cpuUsage: cpuUsageInternal
    property real cpuUsageInternal: 0
    property var prevCpuStats: null
    
    // =====================================================
    // POWER PROFILE PROPERTIES
    // =====================================================
    
    // Power Profiles Daemon
    readonly property string powerProfile: powerProfileInternal.trim()
    readonly property var powerProfilesAvailable: ["performance", "balanced", "power-saver"]
    property string powerProfileInternal: "balanced"
    
    // Platform profile (ACPI)
    readonly property string platformProfile: platformProfileInternal.trim()
    readonly property var platformProfilesAvailable: platformProfilesAvailableInternal.trim().split(" ").filter(p => p.length > 0)
    property string platformProfileInternal: ""
    property string platformProfilesAvailableInternal: ""
    
    // =====================================================
    // GPU PROPERTIES (NVIDIA)
    // =====================================================
    
    // GPU basic info
    readonly property string gpuModel: gpuModelInternal.trim()
    readonly property string gpuDriver: gpuDriverInternal.trim()
    property string gpuModelInternal: "Unknown GPU"
    property string gpuDriverInternal: ""
    
    // GPU temperature
    readonly property int gpuTemp: gpuTempInternal
    property int gpuTempInternal: 0
    
    // GPU power
    readonly property real gpuPowerDraw: gpuPowerDrawInternal
    readonly property real gpuPowerLimit: gpuPowerLimitInternal
    readonly property real gpuPowerMin: gpuPowerMinInternal
    readonly property real gpuPowerMax: gpuPowerMaxInternal
    readonly property real gpuPowerDefault: gpuPowerDefaultInternal
    property real gpuPowerDrawInternal: 0
    property real gpuPowerLimitInternal: 0
    property real gpuPowerMinInternal: 0
    property real gpuPowerMaxInternal: 140
    property real gpuPowerDefaultInternal: 115
    
    // GPU utilization
    readonly property int gpuUsage: gpuUsageInternal
    readonly property int gpuMemoryUsage: gpuMemoryUsageInternal
    property int gpuUsageInternal: 0
    property int gpuMemoryUsageInternal: 0
    
    // GPU memory
    readonly property int gpuMemoryUsed: gpuMemoryUsedInternal
    readonly property int gpuMemoryTotal: gpuMemoryTotalInternal
    property int gpuMemoryUsedInternal: 0
    property int gpuMemoryTotalInternal: 0
    
    // GPU clocks (MHz)
    readonly property int gpuClockGraphics: gpuClockGraphicsInternal
    readonly property int gpuClockMemory: gpuClockMemoryInternal
    readonly property int gpuClockMaxGraphics: gpuClockMaxGraphicsInternal
    readonly property int gpuClockMaxMemory: gpuClockMaxMemoryInternal
    property int gpuClockGraphicsInternal: 0
    property int gpuClockMemoryInternal: 0
    property int gpuClockMaxGraphicsInternal: 0
    property int gpuClockMaxMemoryInternal: 0
    
    // GPU power state
    readonly property string gpuPowerState: gpuPowerStateInternal.trim()
    property string gpuPowerStateInternal: "unknown"
    
    // GPU persistence mode
    readonly property bool gpuPersistenceMode: gpuPersistenceModeInternal
    property bool gpuPersistenceModeInternal: false
    
    // GPU power limit support
    readonly property bool gpuPowerLimitSupported: gpuPowerLimitSupportedInternal
    property bool gpuPowerLimitSupportedInternal: false
    
    // =====================================================
    // DETECTION FLAGS
    // =====================================================
    
    readonly property bool hasNvidiaGpu: gpuModel !== "Unknown GPU" && gpuModel !== ""
    readonly property bool hasAmdCpu: cpuDriver === "amd-pstate-epp" || cpuDriver === "amd-pstate" || cpuDriver === "acpi-cpufreq"
    readonly property bool hasPowerProfiles: powerProfileInternal !== ""
    readonly property bool hasPlatformProfile: platformProfile !== ""
    
    // =====================================================
    // BATTERY PROPERTIES
    // =====================================================
    
    // Battery basic
    readonly property bool hasBattery: batteryPresentInternal
    readonly property string batteryStatus: batteryStatusInternal.trim()
    readonly property int batteryPercent: batteryPercentInternal
    readonly property bool batteryCharging: batteryStatus === "Charging"
    readonly property bool batteryDischarging: batteryStatus === "Discharging"
    readonly property bool batteryNotCharging: batteryStatus === "Not charging"  // Conservation mode active
    readonly property bool batteryPluggedIn: batteryCharging || batteryNotCharging || batteryStatus === "Full"
    property bool batteryPresentInternal: false
    property string batteryStatusInternal: "Unknown"
    property int batteryPercentInternal: 0
    
    // Battery health
    readonly property int batteryCycleCount: batteryCycleCountInternal
    readonly property real batteryDesignCapacity: batteryDesignCapacityInternal / 1000000  // Wh
    readonly property real batteryCurrentCapacity: batteryCurrentCapacityInternal / 1000000  // Wh
    readonly property real batteryHealth: batteryDesignCapacity > 0 ? (batteryCurrentCapacity / batteryDesignCapacity * 100) : 0
    property int batteryCycleCountInternal: 0
    property real batteryDesignCapacityInternal: 0
    property real batteryCurrentCapacityInternal: 0
    
    // Battery power/time
    readonly property real batteryPowerNow: batteryPowerNowInternal / 1000000  // W
    readonly property real batteryEnergyNow: batteryEnergyNowInternal / 1000000  // Wh
    readonly property real batteryTimeRemaining: batteryPowerNow > 0 ? (batteryEnergyNow / batteryPowerNow * 60) : 0  // minutes
    property real batteryPowerNowInternal: 0
    property real batteryEnergyNowInternal: 0
    
    // Battery info
    readonly property string batteryModel: batteryModelInternal.trim()
    readonly property string batteryManufacturer: batteryManufacturerInternal.trim()
    readonly property string batteryTechnology: batteryTechnologyInternal.trim()
    property string batteryModelInternal: ""
    property string batteryManufacturerInternal: ""
    property string batteryTechnologyInternal: ""
    
    // Lenovo Conservation Mode (charge limit to 60%)
    readonly property bool hasConservationMode: hasConservationModeInternal
    readonly property bool conservationMode: conservationModeInternal === "1"
    property bool hasConservationModeInternal: false
    property string conservationModeInternal: "0"
    
    // Lenovo USB Charging (charge devices when laptop is off)
    readonly property bool hasUsbCharging: hasUsbChargingInternal
    readonly property bool usbCharging: usbChargingInternal === "1"
    property bool hasUsbChargingInternal: false
    property string usbChargingInternal: "0"
    
    // Lenovo Fn Lock
    readonly property bool hasFnLock: hasFnLockInternal
    readonly property bool fnLock: fnLockInternal === "1"
    property bool hasFnLockInternal: false
    property string fnLockInternal: "0"
    
    // =====================================================
    // GPU MODE PROPERTIES (Optimus/envycontrol)
    // =====================================================
    
    readonly property bool hasEnvyControl: hasEnvyControlInternal
    readonly property string gpuMode: gpuModeInternal.trim()  // "integrated", "hybrid", "nvidia"
    readonly property var gpuModesAvailable: ["integrated", "hybrid", "nvidia"]
    property bool hasEnvyControlInternal: false
    property string gpuModeInternal: "hybrid"
    
    // Current render GPU
    readonly property string currentRenderGpu: currentRenderGpuInternal.trim()
    property string currentRenderGpuInternal: "Unknown"
    
    // =====================================================
    // GPU PROCESSES
    // =====================================================
    
    readonly property var gpuProcesses: gpuProcessesInternal
    property var gpuProcessesInternal: []
    
    // =====================================================
    // APP PROFILES
    // =====================================================
    
    readonly property var appProfiles: [
        {
            name: "Gaming",
            icon: "sports_esports",
            description: "Performance mode + Launch apps",
            actions: [
                { type: "power_profile", value: "performance" },
                { type: "cpu_boost", value: true },
                { type: "conservation_mode", value: false }
            ],
            apps: ["discord", "steam"]
        },
        {
            name: "Work",
            icon: "work",
            description: "Balanced mode + Productivity apps",
            actions: [
                { type: "power_profile", value: "balanced" },
                { type: "cpu_boost", value: true }
            ],
            apps: ["code", "firefox"]
        },
        {
            name: "Battery Saver",
            icon: "battery_saver",
            description: "Power saving mode",
            actions: [
                { type: "power_profile", value: "power-saver" },
                { type: "cpu_boost", value: false },
                { type: "conservation_mode", value: true }
            ],
            apps: []
        },
        {
            name: "Streaming",
            icon: "videocam",
            description: "OBS + Game + Chat",
            actions: [
                { type: "power_profile", value: "performance" },
                { type: "cpu_boost", value: true }
            ],
            apps: ["obs", "discord"]
        }
    ]
    
    // =====================================================
    // RGB KEYBOARD PROPERTIES
    // =====================================================
    
    readonly property bool hasRgbKeyboard: hasRgbKeyboardInternal
    readonly property bool rgbEnabled: rgbEnabledInternal
    readonly property string rgbDeviceName: rgbDeviceNameInternal.trim()
    readonly property var rgbModes: rgbModesInternal
    readonly property string rgbCurrentMode: rgbCurrentModeInternal.trim()
    readonly property var rgbZones: ["left", "left_center", "right_center", "right"]
    readonly property var rgbColors: rgbColorsInternal  // Array of 4 colors for each zone
    readonly property int rgbSpeed: rgbSpeedInternal
    readonly property string rgbBreathingColor: rgbBreathingColorInternal
    
    // Mode capabilities
    readonly property bool rgbModeSupportsSpeed: ["Breathing", "Rainbow Wave", "Spectrum Cycle"].includes(rgbCurrentModeInternal)
    readonly property bool rgbModeSupportsColor: ["Direct", "Breathing"].includes(rgbCurrentModeInternal)
    readonly property bool rgbModeIsZoned: rgbCurrentModeInternal === "Direct"
    
    // Default to true for Lenovo Legion - will be validated on startup
    property bool hasRgbKeyboardInternal: true
    property bool rgbEnabledInternal: true
    property string rgbDeviceNameInternal: "Lenovo 5 2021"
    property var rgbModesInternal: ["Direct", "Breathing", "Rainbow Wave", "Spectrum Cycle"]
    property string rgbCurrentModeInternal: "Direct"
    property var rgbColorsInternal: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]
    property var rgbLastColors: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]  // Store colors when turning off
    property int rgbSpeedInternal: 50
    property string rgbBreathingColorInternal: "#FF0000"
    
    // Saved state for revert functionality
    property string rgbSavedMode: "Direct"
    property var rgbSavedColors: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]
    property int rgbSavedSpeed: 50
    property string rgbSavedBreathingColor: "#FF0000"
    
    // RGB presets
    readonly property var rgbPresets: [
        { name: "Legion Red", colors: ["#FF0000", "#FF0000", "#FF0000", "#FF0000"] },
        { name: "Cool Blue", colors: ["#0066FF", "#0099FF", "#00CCFF", "#00FFFF"] },
        { name: "Neon Green", colors: ["#00FF00", "#33FF33", "#66FF66", "#00FF00"] },
        { name: "Purple Haze", colors: ["#9900FF", "#CC00FF", "#FF00FF", "#CC00FF"] },
        { name: "Sunset", colors: ["#FF6600", "#FF3300", "#FF0066", "#FF0099"] },
        { name: "Ocean", colors: ["#0033FF", "#0066FF", "#0099FF", "#00CCFF"] },
        { name: "Rainbow", colors: ["#FF0000", "#FFFF00", "#00FF00", "#0000FF"] },
        { name: "White", colors: ["#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF"] },
        { name: "Off", colors: ["#000000", "#000000", "#000000", "#000000"] }
    ]
    
    // RGB Command Queue - prevents race conditions
    property var rgbCommandQueue: []
    property bool rgbCommandRunning: false
    property bool rgbServerReady: false  // OpenRGB server running and ready
    
    // RGB Server connection state (internal use)
    property int rgbServerStateInternal: 0  // 0=Disconnected, 1=Connecting, 2=Connected

    // =====================================================
    // DEFAULT VALUES (for reset functionality)
    // =====================================================
    
    readonly property var defaults: ({
        powerProfile: "balanced",
        cpuBoost: true,
        cpuGovernor: "powersave",
        cpuEpp: "balance_performance",
        conservationMode: false,
        gpuPersistence: true,
        rgbMode: "direct",
        rgbColors: ["#FF0000", "#FF0000", "#FF0000", "#FF0000"]
    })
    
    // =====================================================
    // FUNCTIONS - RESET TO DEFAULTS
    // =====================================================
    
    function resetCpuToDefault(): void {
        console.log("[Hardware] Resetting CPU to defaults");
        setPowerProfile(defaults.powerProfile);
        setCpuBoost(defaults.cpuBoost);
        if (cpuGovernorsAvailable.includes(defaults.cpuGovernor)) {
            setCpuGovernor(defaults.cpuGovernor);
        }
        if (cpuEppAvailable.includes(defaults.cpuEpp)) {
            setCpuEpp(defaults.cpuEpp);
        }
    }
    
    function resetBatteryToDefault(): void {
        console.log("[Hardware] Resetting battery to defaults");
        setConservationMode(defaults.conservationMode);
    }
    
    function resetGpuToDefault(): void {
        console.log("[Hardware] Resetting GPU to defaults");
        setGpuPersistenceMode(defaults.gpuPersistence);
    }
    
    function resetRgbToDefault(): void {
        console.log("[Hardware] Resetting RGB to defaults");
        setRgbMode(defaults.rgbMode);
        setRgbColors(defaults.rgbColors);
        // Save as new checkpoint
        saveRgbState();
    }
    
    function saveRgbState(): void {
        console.log("[Hardware] Saving RGB state checkpoint");
        rgbSavedMode = rgbCurrentModeInternal;
        rgbSavedColors = rgbColorsInternal.slice();  // Clone array
        rgbSavedSpeed = rgbSpeedInternal;
        rgbSavedBreathingColor = rgbBreathingColorInternal;
    }
    
    function revertRgbChanges(): void {
        console.log("[Hardware] Reverting RGB to saved state");
        setRgbMode(rgbSavedMode);
        setRgbColors(rgbSavedColors);
        setRgbSpeed(rgbSavedSpeed);
        setRgbBreathingColor(rgbSavedBreathingColor);
    }
    
    function resetAllToDefault(): void {
        console.log("[Hardware] Resetting ALL settings to defaults");
        resetCpuToDefault();
        resetBatteryToDefault();
        resetGpuToDefault();
        resetRgbToDefault();
    }
    
    // =====================================================
    // FUNCTIONS - CPU
    // =====================================================
    
    function setCpuGovernor(governor: string): void {
        if (!cpuGovernorsAvailable.includes(governor)) return;
        console.log("[Hardware] Setting CPU governor to:", governor);
        cpuGovernorProcess.command = ["sh", "-c", 
            `echo "${governor}" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null`
        ];
        cpuGovernorProcess.running = true;
    }
    
    function setCpuBoost(enabled: bool): void {
        if (!cpuBoostSupported) return;
        console.log("[Hardware] Setting CPU boost to:", enabled);
        cpuBoostProcess.command = ["sh", "-c", 
            `echo "${enabled ? "1" : "0"}" | sudo tee /sys/devices/system/cpu/cpufreq/boost > /dev/null`
        ];
        cpuBoostProcess.running = true;
    }
    
    function setCpuEpp(epp: string): void {
        if (!cpuEppAvailable.includes(epp)) return;
        console.log("[Hardware] Setting CPU EPP to:", epp);
        cpuEppProcess.command = ["sh", "-c", 
            `echo "${epp}" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null`
        ];
        cpuEppProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - POWER PROFILES
    // =====================================================
    
    function setPowerProfile(profile: string): void {
        if (!powerProfilesAvailable.includes(profile)) return;
        console.log("[Hardware] Setting power profile to:", profile);
        powerProfileProcess.command = ["powerprofilesctl", "set", profile];
        powerProfileProcess.running = true;
    }
    
    function setPlatformProfile(profile: string): void {
        if (!platformProfilesAvailable.includes(profile)) return;
        console.log("[Hardware] Setting platform profile to:", profile);
        platformProfileProcess.command = ["sh", "-c", 
            `echo "${profile}" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null`
        ];
        platformProfileProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - GPU
    // =====================================================
    
    function setGpuPowerLimit(watts: int): void {
        if (watts < gpuPowerMin || watts > gpuPowerMax) return;
        console.log("[Hardware] Setting GPU power limit to:", watts, "W");
        gpuPowerLimitProcess.command = ["sudo", "nvidia-smi", "-pl", watts.toString()];
        gpuPowerLimitProcess.running = true;
    }
    
    function resetGpuPowerLimit(): void {
        setGpuPowerLimit(gpuPowerDefault);
    }
    
    function setGpuPersistenceMode(enabled: bool): void {
        console.log("[Hardware] Setting GPU persistence mode to:", enabled);
        gpuPersistenceProcess.command = ["sudo", "nvidia-smi", "-pm", enabled ? "1" : "0"];
        gpuPersistenceProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - BATTERY
    // =====================================================
    
    function setConservationMode(enabled: bool): void {
        if (!hasConservationMode) return;
        console.log("[Hardware] Setting conservation mode to:", enabled);
        conservationModeProcess.command = ["sh", "-c", 
            `echo "${enabled ? "1" : "0"}" | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/conservation_mode > /dev/null`
        ];
        conservationModeProcess.running = true;
    }
    
    function setUsbCharging(enabled: bool): void {
        if (!hasUsbCharging) return;
        console.log("[Hardware] Setting USB charging to:", enabled);
        usbChargingProcess.command = ["sh", "-c", 
            `echo "${enabled ? "1" : "0"}" | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/usb_charging > /dev/null`
        ];
        usbChargingProcess.running = true;
    }
    
    function setFnLock(enabled: bool): void {
        if (!hasFnLock) return;
        console.log("[Hardware] Setting Fn Lock to:", enabled);
        fnLockProcess.command = ["sh", "-c", 
            `echo "${enabled ? "1" : "0"}" | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/fn_lock > /dev/null`
        ];
        fnLockProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - GPU MODE (envycontrol)
    // =====================================================
    
    function setGpuMode(mode: string): void {
        if (!hasEnvyControl || !gpuModesAvailable.includes(mode)) return;
        console.log("[Hardware] Setting GPU mode to:", mode, "(requires reboot)");
        gpuModeProcess.command = ["sudo", "envycontrol", "-s", mode];
        gpuModeProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - GPU PROCESSES
    // =====================================================
    
    function killGpuProcess(pid: int): void {
        console.log("[Hardware] Killing GPU process:", pid);
        killProcessProcess.command = ["kill", "-9", pid.toString()];
        killProcessProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - APP PROFILES
    // =====================================================
    
    function applyProfile(profileIndex: int): void {
        if (profileIndex < 0 || profileIndex >= appProfiles.length) return;
        const profile = appProfiles[profileIndex];
        console.log("[Hardware] Applying profile:", profile.name);
        
        // Apply actions
        for (const action of profile.actions) {
            switch (action.type) {
                case "power_profile":
                    setPowerProfile(action.value);
                    break;
                case "cpu_boost":
                    setCpuBoost(action.value);
                    break;
                case "conservation_mode":
                    setConservationMode(action.value);
                    break;
            }
        }
        
        // Launch apps
        for (const app of profile.apps) {
            launchAppProcess.command = ["sh", "-c", `${app} &`];
            launchAppProcess.running = true;
        }
    }
    
    // =====================================================
    // FUNCTIONS - RGB KEYBOARD (Queue-based to prevent race conditions)
    // =====================================================
    
    // Queue a command and process it
    function queueRgbCommand(cmd: var, priority: bool): void {
        const cmdStr = cmd.join(" ");
        const isMode = cmdStr.includes("-m ");
        const isBrightness = cmdStr.includes("-b ");
        const isColor = cmdStr.includes("-c ");
        
        // Deduplicate: remove older commands of same type
        if (isMode) {
            rgbCommandQueue = rgbCommandQueue.filter(c => !c.join(" ").includes("-m "));
        } else if (isBrightness) {
            rgbCommandQueue = rgbCommandQueue.filter(c => !c.join(" ").includes("-b "));
        } else if (isColor) {
            // Remove older color commands
            rgbCommandQueue = rgbCommandQueue.filter(c => !c.join(" ").includes("-c "));
        }
        
        // Add to queue
        if (priority) {
            rgbCommandQueue.unshift(cmd);
        } else {
            rgbCommandQueue.push(cmd);
        }
        
        processRgbQueue();
    }
    
    // Process the queue - only run one command at a time
    function processRgbQueue(): void {
        if (rgbCommandRunning || rgbCommandQueue.length === 0 || !rgbServerReady) return;
        
        rgbCommandRunning = true;
        const cmd = rgbCommandQueue.shift();
        console.log("[Hardware] Running RGB command:", cmd.join(" "));
        rgbProcess.command = cmd;
        rgbProcess.running = true;
    }
    
    function setRgbEnabled(enabled: bool): void {
        if (!hasRgbKeyboard) return;
        console.log("[Hardware] Setting RGB enabled:", enabled);
        rgbEnabledInternal = enabled;
        
        if (enabled) {
            // Restore last colors
            setRgbColors(rgbLastColors);
        } else {
            // Save current colors before turning off
            rgbLastColors = [...rgbColorsInternal];
            // Turn off all LEDs
            setRgbColors(["#000000", "#000000", "#000000", "#000000"]);
        }
    }
    
    function toggleRgb(): void {
        setRgbEnabled(!rgbEnabled);
    }
    
    function setRgbMode(mode: string): void {
        if (!hasRgbKeyboard) return;
        console.log("[Hardware] Queueing RGB mode:", mode);
        rgbCurrentModeInternal = mode;
        // Priority command - goes to front of queue
        queueRgbCommand(["openrgb", "-d", "0", "-m", mode], true);
    }
    
    function setRgbColor(zoneIndex: int, color: string): void {
        if (!hasRgbKeyboard || zoneIndex < 0 || zoneIndex > 3) return;
        // Ensure color has # prefix for internal storage
        const normalizedColor = color.startsWith("#") ? color : "#" + color;
        console.log("[Hardware] Queueing RGB zone", zoneIndex, "color:", normalizedColor);
        // Update internal colors array immediately for UI responsiveness
        let newColors = [...rgbColorsInternal];
        newColors[zoneIndex] = normalizedColor;
        rgbColorsInternal = newColors;
        if (rgbEnabled) rgbLastColors = [...newColors];
        
        // If not in Direct mode, queue mode change first
        if (rgbCurrentModeInternal !== "Direct") {
            rgbCurrentModeInternal = "Direct";
            queueRgbCommand(["openrgb", "-d", "0", "-m", "Direct"], true);
        }
        
        // Device has 1 zone with 4 LEDs - must set all colors at once
        const colorString = newColors.map(c => c.replace("#", "")).join(",");
        queueRgbCommand(["openrgb", "-d", "0", "-c", colorString], false);
    }
    
    function setRgbColors(colors: var): void {
        if (!hasRgbKeyboard || colors.length !== 4) return;
        console.log("[Hardware] Queueing all RGB colors");
        rgbColorsInternal = colors;
        // Only save to lastColors if not turning off
        const isOff = colors.every(c => c === "#000000");
        if (!isOff) rgbLastColors = [...colors];
        rgbCurrentModeInternal = "Direct";
        
        // Queue mode change first (priority)
        queueRgbCommand(["openrgb", "-d", "0", "-m", "Direct"], true);
        
        // Build comma-separated color string for all 4 LEDs
        const colorString = colors.map(c => c.replace("#", "")).join(",");
        queueRgbCommand(["openrgb", "-d", "0", "-c", colorString], false);
    }
    
    function setRgbPreset(presetIndex: int): void {
        if (presetIndex < 0 || presetIndex >= rgbPresets.length) return;
        const preset = rgbPresets[presetIndex];
        console.log("[Hardware] Applying RGB preset:", preset.name);
        
        // If Off preset, disable RGB
        if (preset.name === "Off") {
            setRgbEnabled(false);
        } else {
            rgbEnabledInternal = true;
            setRgbColors(preset.colors);
        }
    }
    
    function setRgbSpeed(speed: int): void {
        if (!hasRgbKeyboard || speed < 0 || speed > 100) return;
        rgbSpeedInternal = speed;
        console.log("[Hardware] Queueing RGB speed:", speed);
        if (rgbModeSupportsSpeed) {
            queueRgbCommand(["openrgb", "-d", "0", "-m", rgbCurrentModeInternal, "-s", speed.toString()], false);
        }
    }
    
    function setRgbBreathingColor(color: string): void {
        if (!hasRgbKeyboard) return;
        rgbBreathingColorInternal = color;
        console.log("[Hardware] Setting breathing color:", color);
        if (rgbCurrentModeInternal === "Breathing") {
            queueRgbCommand(["openrgb", "-d", "0", "-m", "Breathing", "-c", color.replace("#", "")], false);
        }
    }
    
    function refreshRgb(): void {
        // Reconnect to OpenRGB server if disconnected
        if (!rgbServerReady && !rgbConnectProcess.running) {
            console.log("[Hardware] Reconnecting to OpenRGB server...");
            rgbServerStateInternal = 1;  // Connecting
            rgbConnectProcess.running = true;
        }
    }

    // =====================================================
    // REFRESH FUNCTIONS
    // =====================================================
    
    function refresh(): void {
        refreshCpuInfo();
        refreshCpuFreq();
        refreshCpuTemp();
        refreshCpuGovernor();
        refreshCpuBoost();
        refreshCpuEpp();
        refreshCpuUsage();
        refreshPowerProfile();
        refreshPlatformProfile();
        refreshGpuInfo();
        refreshBattery();
        refreshGpuMode();
        refreshGpuProcesses();
        // Note: refreshRgb() is called from shell.qml on startup
    }
    
    function refreshCpuInfo(): void {
        cpuInfoProcess.running = true;
    }
    
    function refreshCpuFreq(): void {
        cpuFreqProcess.running = true;
    }
    
    function refreshCpuTemp(): void {
        cpuTempProcess.running = true;
    }
    
    function refreshCpuGovernor(): void {
        cpuGovernorReadProcess.running = true;
    }
    
    function refreshCpuBoost(): void {
        cpuBoostReadProcess.running = true;
    }
    
    function refreshCpuEpp(): void {
        cpuEppReadProcess.running = true;
    }
    
    function refreshCpuUsage(): void {
        cpuUsageProcess.running = true;
    }
    
    function refreshPowerProfile(): void {
        powerProfileReadProcess.running = true;
    }
    
    function refreshPlatformProfile(): void {
        platformProfileReadProcess.running = true;
    }
    
    function refreshGpuInfo(): void {
        if (!hasNvidiaGpu && gpuModelInternal === "Unknown GPU") {
            // First check if nvidia-smi exists
            gpuCheckProcess.running = true;
        } else if (hasNvidiaGpu) {
            gpuInfoProcess.running = true;
            gpuPowerInfoProcess.running = true;
        }
    }
    
    function refreshBattery(): void {
        batteryProcess.running = true;
        conservationModeReadProcess.running = true;
        lenovoFeaturesReadProcess.running = true;
    }
    
    function refreshGpuMode(): void {
        envyControlCheckProcess.running = true;
        renderGpuProcess.running = true;
    }
    
    function refreshGpuProcesses(): void {
        if (hasNvidiaGpu) {
            gpuProcessesProcess.running = true;
        }
    }
    
    // =====================================================
    // PROCESSES - CPU INFO
    // =====================================================
    
    Process {
        id: cpuInfoProcess
        command: ["sh", "-c", `
            model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2)
            cores=$(grep -m1 'cpu cores' /proc/cpuinfo | cut -d: -f2)
            threads=$(grep -c '^processor' /proc/cpuinfo)
            echo "$model|$cores|$threads"
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 3) {
                    root.cpuModelInternal = parts[0].trim();
                    root.cpuCoresInternal = parseInt(parts[1]) || 0;
                    root.cpuThreadsInternal = parseInt(parts[2]) || 0;
                }
            }
        }
    }
    
    // =====================================================
    // PROCESSES - CPU FREQ
    // =====================================================
    
    Process {
        id: cpuFreqProcess
        command: ["sh", "-c", `
            cur=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo 0)
            min=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null || echo 0)
            max=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 0)
            echo "$cur|$min|$max"
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 3) {
                    root.cpuFreqCurrentInternal = parseFloat(parts[0]) || 0;
                    root.cpuFreqMinInternal = parseFloat(parts[1]) || 0;
                    root.cpuFreqMaxInternal = parseFloat(parts[2]) || 0;
                }
            }
        }
    }
    
    // =====================================================
    // PROCESSES - CPU TEMP
    // =====================================================
    
    Process {
        id: cpuTempProcess
        command: ["sh", "-c", `
            # Try k10temp first (AMD), then coretemp (Intel), then generic hwmon
            for hwmon in /sys/class/hwmon/hwmon*/; do
                name=$(cat "$hwmon/name" 2>/dev/null)
                if [ "$name" = "k10temp" ] || [ "$name" = "coretemp" ]; then
                    cat "$hwmon/temp1_input" 2>/dev/null
                    exit 0
                fi
            done
            echo "0"
        `]
        stdout: SplitParser {
            onRead: data => {
                root.cpuTempInternal = parseFloat(data) || 0;
            }
        }
    }
    
    // =====================================================
    // PROCESSES - CPU GOVERNOR
    // =====================================================
    
    Process {
        id: cpuGovernorReadProcess
        command: ["sh", "-c", `
            gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
            driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "unknown")
            avail=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")
            echo "$gov|$driver|$avail"
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 3) {
                    root.cpuGovernorInternal = parts[0];
                    root.cpuDriverInternal = parts[1];
                    root.cpuGovernorsAvailableInternal = parts[2];
                }
            }
        }
    }
    
    Process {
        id: cpuGovernorProcess
        onExited: (code, status) => {
            console.log("[Hardware] CPU governor set, exit code:", code);
            Qt.callLater(root.refreshCpuGovernor);
        }
    }
    
    // =====================================================
    // PROCESSES - CPU BOOST
    // =====================================================
    
    Process {
        id: cpuBoostReadProcess
        command: ["sh", "-c", `
            if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
                echo "1|$(cat /sys/devices/system/cpu/cpufreq/boost)"
            elif [ -f /sys/devices/system/cpu/cpu0/cpufreq/boost ]; then
                echo "1|$(cat /sys/devices/system/cpu/cpu0/cpufreq/boost)"
            else
                echo "0|0"
            fi
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 2) {
                    root.cpuBoostSupportedInternal = parts[0] === "1";
                    root.cpuBoostInternal = parts[1].trim();
                }
            }
        }
    }
    
    Process {
        id: cpuBoostProcess
        onExited: (code, status) => {
            console.log("[Hardware] CPU boost set, exit code:", code);
            Qt.callLater(root.refreshCpuBoost);
        }
    }
    
    // =====================================================
    // PROCESSES - CPU EPP (Energy Performance Preference)
    // =====================================================
    
    Process {
        id: cpuEppReadProcess
        command: ["sh", "-c", `
            epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "")
            avail=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences 2>/dev/null || echo "")
            echo "$epp|$avail"
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 2) {
                    root.cpuEppInternal = parts[0];
                    root.cpuEppAvailableInternal = parts[1];
                }
            }
        }
    }
    
    Process {
        id: cpuEppProcess
        onExited: (code, status) => {
            console.log("[Hardware] CPU EPP set, exit code:", code);
            Qt.callLater(root.refreshCpuEpp);
        }
    }
    
    // =====================================================
    // PROCESSES - CPU USAGE
    // =====================================================
    
    Process {
        id: cpuUsageProcess
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                // Parse: cpu user nice system idle iowait irq softirq
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 5 && parts[0] === "cpu") {
                    const user = parseInt(parts[1]) || 0;
                    const nice = parseInt(parts[2]) || 0;
                    const system = parseInt(parts[3]) || 0;
                    const idle = parseInt(parts[4]) || 0;
                    const iowait = parseInt(parts[5]) || 0;
                    const irq = parseInt(parts[6]) || 0;
                    const softirq = parseInt(parts[7]) || 0;
                    
                    const total = user + nice + system + idle + iowait + irq + softirq;
                    const active = total - idle - iowait;
                    
                    if (root.prevCpuStats) {
                        const totalDiff = total - root.prevCpuStats.total;
                        const activeDiff = active - root.prevCpuStats.active;
                        if (totalDiff > 0) {
                            root.cpuUsageInternal = Math.round((activeDiff / totalDiff) * 100);
                        }
                    }
                    
                    root.prevCpuStats = { total, active };
                }
            }
        }
    }
    
    // =====================================================
    // PROCESSES - POWER PROFILE
    // =====================================================
    
    Process {
        id: powerProfileReadProcess
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                root.powerProfileInternal = data.trim();
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.powerProfileInternal = "";
            }
        }
    }
    
    Process {
        id: powerProfileProcess
        onExited: (code, status) => {
            console.log("[Hardware] Power profile set, exit code:", code);
            Qt.callLater(root.refreshPowerProfile);
            Qt.callLater(root.refreshCpuGovernor);
            Qt.callLater(root.refreshCpuEpp);
        }
    }
    
    // =====================================================
    // PROCESSES - PLATFORM PROFILE
    // =====================================================
    
    Process {
        id: platformProfileReadProcess
        command: ["sh", "-c", `
            profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo "")
            avail=$(cat /sys/firmware/acpi/platform_profile_choices 2>/dev/null || echo "")
            echo "$profile|$avail"
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 2) {
                    root.platformProfileInternal = parts[0];
                    root.platformProfilesAvailableInternal = parts[1];
                }
            }
        }
    }
    
    Process {
        id: platformProfileProcess
        onExited: (code, status) => {
            console.log("[Hardware] Platform profile set, exit code:", code);
            Qt.callLater(root.refreshPlatformProfile);
        }
    }
    
    // =====================================================
    // PROCESSES - GPU CHECK
    // =====================================================
    
    Process {
        id: gpuCheckProcess
        command: ["which", "nvidia-smi"]
        onExited: (code, status) => {
            if (code === 0) {
                gpuInfoProcess.running = true;
                gpuPowerInfoProcess.running = true;
            }
        }
    }
    
    // =====================================================
    // PROCESSES - GPU INFO
    // =====================================================
    
    Process {
        id: gpuInfoProcess
        command: ["nvidia-smi", "--query-gpu=name,driver_version,temperature.gpu,power.draw,utilization.gpu,utilization.memory,clocks.gr,clocks.mem,clocks.max.gr,clocks.max.mem,memory.used,memory.total,pstate,persistence_mode,power.management", "--format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                // Parse CSV: name,driver,temp,power,gpu_util,mem_util,clock_gr,clock_mem,max_gr,max_mem,mem_used,mem_total,pstate,persistence,power_mgmt
                const parts = data.split(",").map(p => p.trim());
                if (parts.length >= 15) {
                    root.gpuModelInternal = parts[0];
                    root.gpuDriverInternal = parts[1];
                    root.gpuTempInternal = parseInt(parts[2]) || 0;
                    root.gpuPowerDrawInternal = parseFloat(parts[3]) || 0;
                    root.gpuUsageInternal = parseInt(parts[4]) || 0;
                    root.gpuMemoryUsageInternal = parseInt(parts[5]) || 0;
                    root.gpuClockGraphicsInternal = parseInt(parts[6]) || 0;
                    root.gpuClockMemoryInternal = parseInt(parts[7]) || 0;
                    root.gpuClockMaxGraphicsInternal = parseInt(parts[8]) || 0;
                    root.gpuClockMaxMemoryInternal = parseInt(parts[9]) || 0;
                    root.gpuMemoryUsedInternal = parseInt(parts[10]) || 0;
                    root.gpuMemoryTotalInternal = parseInt(parts[11]) || 0;
                    root.gpuPowerStateInternal = parts[12];
                    root.gpuPersistenceModeInternal = parts[13].toLowerCase() === "enabled";
                    // Power management supported if not "[N/A]" or "N/A"
                    root.gpuPowerLimitSupportedInternal = !parts[14].includes("N/A") && parts[14] !== "[Not Supported]";
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.gpuModelInternal = "";
            }
        }
    }
    
    // =====================================================
    // PROCESSES - GPU POWER INFO
    // =====================================================
    
    Process {
        id: gpuPowerInfoProcess
        command: ["nvidia-smi", "-q", "-d", "POWER"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                // Parse power limits from nvidia-smi output
                const lines = data.split("\n");
                for (const line of lines) {
                    if (line.includes("Current Power Limit") && !line.includes("N/A")) {
                        const match = line.match(/:\s*([\d.]+)\s*W/);
                        if (match) root.gpuPowerLimitInternal = parseFloat(match[1]);
                    } else if (line.includes("Min Power Limit") && !line.includes("N/A")) {
                        const match = line.match(/:\s*([\d.]+)\s*W/);
                        if (match) root.gpuPowerMinInternal = parseFloat(match[1]);
                    } else if (line.includes("Max Power Limit") && !line.includes("N/A")) {
                        const match = line.match(/:\s*([\d.]+)\s*W/);
                        if (match) root.gpuPowerMaxInternal = parseFloat(match[1]);
                    } else if (line.includes("Default Power Limit") && !line.includes("N/A")) {
                        const match = line.match(/:\s*([\d.]+)\s*W/);
                        if (match) root.gpuPowerDefaultInternal = parseFloat(match[1]);
                    }
                }
            }
        }
    }
    
    // =====================================================
    // PROCESSES - GPU POWER LIMIT
    // =====================================================
    
    Process {
        id: gpuPowerLimitProcess
        onExited: (code, status) => {
            console.log("[Hardware] GPU power limit set, exit code:", code);
            Qt.callLater(root.refreshGpuInfo);
        }
    }
    
    Process {
        id: gpuPersistenceProcess
        onExited: (code, status) => {
            console.log("[Hardware] GPU persistence mode set, exit code:", code);
            Qt.callLater(root.refreshGpuInfo);
        }
    }
    
    // =====================================================
    // PROCESSES - BATTERY
    // =====================================================
    
    Process {
        id: batteryProcess
        command: ["sh", "-c", `
            bat="/sys/class/power_supply/BAT0"
            if [ -d "$bat" ]; then
                present=$(cat "$bat/present" 2>/dev/null || echo "0")
                status=$(cat "$bat/status" 2>/dev/null || echo "Unknown")
                capacity=$(cat "$bat/capacity" 2>/dev/null || echo "0")
                cycle=$(cat "$bat/cycle_count" 2>/dev/null || echo "0")
                design=$(cat "$bat/energy_full_design" 2>/dev/null || echo "0")
                full=$(cat "$bat/energy_full" 2>/dev/null || echo "0")
                now=$(cat "$bat/energy_now" 2>/dev/null || echo "0")
                power=$(cat "$bat/power_now" 2>/dev/null || echo "0")
                model=$(cat "$bat/model_name" 2>/dev/null || echo "")
                mfg=$(cat "$bat/manufacturer" 2>/dev/null || echo "")
                tech=$(cat "$bat/technology" 2>/dev/null || echo "")
                echo "$present|$status|$capacity|$cycle|$design|$full|$now|$power|$model|$mfg|$tech"
            else
                echo "0|Unknown|0|0|0|0|0|0|||"
            fi
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 11) {
                    root.batteryPresentInternal = parts[0] === "1";
                    root.batteryStatusInternal = parts[1];
                    root.batteryPercentInternal = parseInt(parts[2]) || 0;
                    root.batteryCycleCountInternal = parseInt(parts[3]) || 0;
                    root.batteryDesignCapacityInternal = parseFloat(parts[4]) || 0;
                    root.batteryCurrentCapacityInternal = parseFloat(parts[5]) || 0;
                    root.batteryEnergyNowInternal = parseFloat(parts[6]) || 0;
                    root.batteryPowerNowInternal = parseFloat(parts[7]) || 0;
                    root.batteryModelInternal = parts[8];
                    root.batteryManufacturerInternal = parts[9];
                    root.batteryTechnologyInternal = parts[10];
                }
            }
        }
    }
    
    Process {
        id: conservationModeReadProcess
        command: ["sh", "-c", `
            mode=$(cat /sys/bus/platform/drivers/ideapad_acpi/VPC*/conservation_mode 2>/dev/null)
            if [ -n "$mode" ]; then
                echo "1|$mode"
            else
                echo "0|0"
            fi
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 2) {
                    root.hasConservationModeInternal = parts[0] === "1";
                    root.conservationModeInternal = parts[1].trim();
                }
            }
        }
    }
    
    Process {
        id: conservationModeProcess
        onExited: (code, status) => {
            console.log("[Hardware] Conservation mode set, exit code:", code);
            Qt.callLater(root.refreshBattery);
        }
    }
    
    // Read all Lenovo features at once (USB charging and Fn Lock)
    Process {
        id: lenovoFeaturesReadProcess
        command: ["sh", "-c", "usb=$(cat /sys/bus/platform/drivers/ideapad_acpi/VPC*/usb_charging 2>/dev/null); fn=$(cat /sys/bus/platform/drivers/ideapad_acpi/VPC*/fn_lock 2>/dev/null); echo \"${usb:-x}|${fn:-x}\""]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split("|");
                if (parts.length >= 2) {
                    root.hasUsbChargingInternal = parts[0] !== "x";
                    root.usbChargingInternal = parts[0] !== "x" ? parts[0].trim() : "0";
                    root.hasFnLockInternal = parts[1] !== "x";
                    root.fnLockInternal = parts[1] !== "x" ? parts[1].trim() : "0";
                }
            }
        }
    }
    
    Process {
        id: usbChargingProcess
        onExited: (code, status) => {
            console.log("[Hardware] USB charging set, exit code:", code);
            Qt.callLater(root.refreshBattery);
        }
    }
    
    Process {
        id: fnLockProcess
        onExited: (code, status) => {
            console.log("[Hardware] Fn Lock set, exit code:", code);
            Qt.callLater(root.refreshBattery);
        }
    }
    
    // =====================================================
    // PROCESSES - GPU MODE (envycontrol)
    // =====================================================
    
    Process {
        id: envyControlCheckProcess
        command: ["which", "envycontrol"]
        onExited: (code, status) => {
            root.hasEnvyControlInternal = code === 0;
            if (code === 0) {
                gpuModeReadProcess.running = true;
            }
        }
    }
    
    Process {
        id: gpuModeReadProcess
        command: ["sudo", "envycontrol", "--query"]
        stdout: SplitParser {
            onRead: data => {
                root.gpuModeInternal = data.trim();
            }
        }
    }
    
    Process {
        id: gpuModeProcess
        onExited: (code, status) => {
            console.log("[Hardware] GPU mode set, exit code:", code);
            Qt.callLater(root.refreshGpuMode);
        }
    }
    
    Process {
        id: renderGpuProcess
        command: ["sh", "-c", "glxinfo 2>/dev/null | grep 'OpenGL renderer' | cut -d: -f2"]
        stdout: SplitParser {
            onRead: data => {
                root.currentRenderGpuInternal = data.trim();
            }
        }
    }
    
    // =====================================================
    // PROCESSES - GPU PROCESSES
    // =====================================================
    
    Process {
        id: gpuProcessesProcess
        command: ["nvidia-smi", "pmon", "-c", "1", "-s", "um"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.split("\n");
                const processes = [];
                for (const line of lines) {
                    if (line.startsWith("#") || line.trim() === "") continue;
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 8) {
                        const pid = parseInt(parts[1]);
                        const type = parts[2];
                        const sm = parts[3];
                        const mem = parts[4];
                        const command = parts[parts.length - 1];
                        if (pid > 0 && command !== "-") {
                            processes.push({
                                pid: pid,
                                type: type,
                                sm: sm === "-" ? 0 : parseInt(sm),
                                mem: mem === "-" ? 0 : parseInt(mem),
                                command: command
                            });
                        }
                    }
                }
                root.gpuProcessesInternal = processes;
            }
        }
    }
    
    Process {
        id: killProcessProcess
        onExited: (code, status) => {
            console.log("[Hardware] Process killed, exit code:", code);
            Qt.callLater(root.refreshGpuProcesses);
        }
    }
    
    // =====================================================
    // PROCESSES - APP PROFILES
    // =====================================================
    
    Process {
        id: launchAppProcess
        // Command set dynamically
    }
    
    // =====================================================
    // PROCESSES - RGB KEYBOARD (Simplified - systemd manages server)
    // =====================================================
    
    // Connect to OpenRGB server (expects systemd service running)
    Process {
        id: rgbConnectProcess
        command: ["timeout", "2", "openrgb", "--list-devices"]
        property string outputBuffer: ""
        
        stdout: SplitParser {
            onRead: data => {
                rgbConnectProcess.outputBuffer += data.toString();
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            const output = rgbConnectProcess.outputBuffer.toLowerCase();
            rgbConnectProcess.outputBuffer = "";
            
            if (exitCode === 0 && (output.includes("lenovo") || output.includes("4-zone") || output.includes("keyboard"))) {
                // Connected successfully!
                console.log("[Hardware] Connected to OpenRGB server!");
                root.hasRgbKeyboardInternal = true;
                root.rgbServerReady = true;
                root.rgbServerStateInternal = 2;  // Connected
                
                // Extract device name
                const lines = output.split("\n");
                for (const line of lines) {
                    if (line.includes("0:")) {
                        const match = line.match(/0:\s*(.+)/);
                        if (match) root.rgbDeviceNameInternal = match[1].trim();
                        break;
                    }
                }
                
                // FORCE SYNC: Apply current colors to keyboard
                console.log("[Hardware] Syncing RGB state to keyboard...");
                if (root.rgbEnabledInternal) {
                    root.queueRgbCommand(["openrgb", "-d", "0", "-m", root.rgbCurrentModeInternal], true);
                    const colorString = root.rgbColorsInternal.map(c => c.replace("#", "")).join(",");
                    root.queueRgbCommand(["openrgb", "-d", "0", "-c", colorString], false);
                } else {
                    root.queueRgbCommand(["openrgb", "-d", "0", "-m", "Direct"], true);
                    root.queueRgbCommand(["openrgb", "-d", "0", "-c", "000000,000000,000000,000000"], false);
                }
                
                Qt.callLater(root.processRgbQueue);
            } else {
                // Server not available
                console.log("[Hardware] OpenRGB server not available. Start with: systemctl --user start openrgb-server");
                root.hasRgbKeyboardInternal = false;
                root.rgbServerReady = false;
                root.rgbServerStateInternal = 0;  // Disconnected
            }
        }
    }
    
    // RGB command executor
    Process {
        id: rgbProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("[Hardware] RGB command failed with code:", exitCode);
            }
            root.rgbCommandRunning = false;
            Qt.callLater(root.processRgbQueue);
        }
    }
    
    // =====================================================
    // REFRESH TIMER
    // =====================================================
    
    Timer {
        id: refreshTimer
        interval: 2000
        repeat: true
        running: true
        
        onTriggered: {
            root.refreshCpuFreq();
            root.refreshCpuTemp();
            root.refreshCpuUsage();
            root.refreshBattery();
            if (root.hasNvidiaGpu) {
                root.refreshGpuInfo();
                root.refreshGpuProcesses();
            }
        }
    }
    
    // Slower refresh for settings that don't change often
    Timer {
        id: slowRefreshTimer
        interval: 10000
        repeat: true
        running: true
        
        onTriggered: {
            root.refreshCpuGovernor();
            root.refreshCpuBoost();
            root.refreshCpuEpp();
            root.refreshPowerProfile();
            root.refreshPlatformProfile();
            root.refreshGpuMode();
        }
    }
    
    // =====================================================
    // INITIALIZATION
    // =====================================================
    
    Component.onCompleted: {
        refresh();
    }
}
