pragma Singleton

import qs.components.misc
import qs.config
import qs.utils
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
    
    // CPU C-States (idle states)
    readonly property var cpuCStates: cpuCStatesInternal
    property var cpuCStatesInternal: []
    readonly property string cpuIdleDriver: cpuIdleDriverInternal.trim()
    property string cpuIdleDriverInternal: ""
    
    // CPU utilization (percentage)
    readonly property real cpuUsage: cpuUsageInternal
    property real cpuUsageInternal: 0
    property var prevCpuStats: null
    
    // =====================================================
    // PLATFORM PROFILE (ACPI)
    // =====================================================
    
    readonly property string platformProfile: platformProfileInternal.trim()
    readonly property var platformProfilesAvailable: platformProfilesAvailableInternal.trim().split(" ").filter(p => p.length > 0)
    property string platformProfileInternal: ""
    property string platformProfilesAvailableInternal: ""
    
    // =====================================================
    // CUSTOM POWER MODE
    // =====================================================
    
    readonly property string customPowerMode: customPowerModeInternal
    readonly property var customPowerModesAvailable: ["performance", "balanced", "power-saver"]
    property string customPowerModeInternal: "performance"
    
    readonly property var customPowerModeConfigs: ({
        "performance": {
            governor: "performance",
            epp: "performance",
            boost: true,
            description: qsTr("Maximum performance")
        },
        "balanced": {
            governor: cpuGovernorsAvailable.includes("schedutil") ? "schedutil" : "powersave",
            epp: "balance_performance",
            boost: true,
            description: qsTr("Balanced mode")
        },
        "power-saver": {
            governor: "powersave",
            epp: "balance_power",
            boost: false,
            description: qsTr("Power saving")
        }
    })
    
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
    // GPU PRIORITY PROPERTIES (Hyprland DRM device order)
    // =====================================================
    
    // GPU Priority - which GPU is primary for compositor rendering
    // "integrated" = AMD iGPU primary (battery saving)
    // "nvidia" = NVIDIA dGPU primary (performance)
    readonly property string gpuPriority: gpuPriorityInternal.trim()
    readonly property var gpuPrioritiesAvailable: ["integrated", "nvidia"]
    property string gpuPriorityInternal: "integrated"
    
    // Whether GPU priority switching is available (hybrid mode + symlinks exist)
    readonly property bool hasGpuPriority: gpuMode === "hybrid" && gpuPriorityInternal !== "unknown"
    
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
    readonly property int rgbServerState: rgbServerStateInternal  // 0=Disconnected, 1=Connecting, 2=Connected
    
    // Mode capabilities
    readonly property bool rgbModeSupportsSpeed: ["Breathing", "Rainbow Wave", "Spectrum Cycle"].includes(rgbCurrentModeInternal)
    readonly property bool rgbModeSupportsColor: ["Direct", "Breathing"].includes(rgbCurrentModeInternal)
    readonly property bool rgbModeIsZoned: rgbCurrentModeInternal === "Direct"
    
    // Start as false - will be set to true only after successful connection
    property bool hasRgbKeyboardInternal: false
    property bool rgbEnabledInternal: true
    property string rgbDeviceNameInternal: "Lenovo 5 2021"
    property var rgbModesInternal: ["Direct", "Breathing", "Rainbow Wave", "Spectrum Cycle"]
    property string rgbCurrentModeInternal: "Direct"
    property var rgbColorsInternal: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]
    property var rgbLastColors: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]  // Store colors when turning off
    property int rgbSpeedInternal: 50
    property string rgbBreathingColorInternal: "#FF0000"
    
    // Saved state for revert functionality (in-memory checkpoint)
    property string rgbSavedMode: "Direct"
    property var rgbSavedColors: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]
    property int rgbSavedSpeed: 50
    property string rgbSavedBreathingColor: "#FF0000"
    
    // Persistent state (loaded from file on startup)
    property string rgbPersistedMode: "Direct"
    property var rgbPersistedColors: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]
    property int rgbPersistedSpeed: 50
    property string rgbPersistedBreathingColor: "#FF0000"
    property bool rgbPersistedEnabled: true
    property bool rgbSettingsLoaded: false
    
    // Track if user has made changes from the persisted state
    readonly property bool rgbHasChanges: {
        if (!rgbSettingsLoaded) return false;
        return rgbCurrentModeInternal !== rgbPersistedMode ||
               rgbSpeedInternal !== rgbPersistedSpeed ||
               rgbBreathingColorInternal !== rgbPersistedBreathingColor ||
               rgbEnabledInternal !== rgbPersistedEnabled ||
               !arraysEqual(rgbColorsInternal, rgbPersistedColors);
    }
    
    function arraysEqual(a: var, b: var): bool {
        if (!a || !b || a.length !== b.length) return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i]) return false;
        }
        return true;
    }
    
    // RGB presets
    readonly property var rgbPresets: [
        { name: "Legion Red", colors: ["#FF0000", "#FF0000", "#FF0000", "#FF0000"] },
        { name: "Cool Blue", colors: ["#0066FF", "#0099FF", "#00CCFF", "#00FFFF"] },
        { name: "Neon Green", colors: ["#00FF00", "#33FF33", "#66FF66", "#00FF00"] },
        { name: "Purple Haze", colors: ["#9900FF", "#CC00FF", "#FF00FF", "#CC00FF"] },
        { name: "Sunset", colors: ["#FF6600", "#FF3300", "#FF0066", "#FF0099"] },
        { name: "Ocean", colors: ["#0033FF", "#0066FF", "#0099FF", "#00CCFF"] },
        { name: "Rainbow", colors: ["#FF0000", "#FFFF00", "#00FF00", "#0000FF"] },
        { name: "White", colors: ["#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF"] }
    ]
    
    // RGB Command Queue - prevents race conditions
    property var rgbCommandQueue: []
    property bool rgbCommandRunning: false
    property bool rgbServerReady: false  // OpenRGB server running and ready
    
    // RGB busy state - true when commands are being processed
    readonly property bool rgbBusy: rgbCommandRunning || rgbCommandQueue.length > 0
    
    // RGB Server connection state (internal use)
    property int rgbServerStateInternal: 0  // 0=Disconnected, 1=Connecting, 2=Connected
    
    // RGB Connection retry mechanism
    property int rgbRetryCount: 0
    readonly property int rgbMaxRetries: 5
    readonly property var rgbRetryDelays: [2000, 4000, 8000, 16000, 32000]  // Exponential backoff

    // =====================================================
    // MEMORY PROPERTIES (lazy loaded when control center opens)
    // =====================================================
    
    // Memory info in MB
    readonly property int memTotal: memTotalInternal
    readonly property int memFree: memFreeInternal
    readonly property int memAvailable: memAvailableInternal
    readonly property int memBuffers: memBuffersInternal
    readonly property int memCached: memCachedInternal
    readonly property int memUsed: memTotal - memAvailable
    readonly property real memUsagePercent: memTotal > 0 ? (memUsed / memTotal * 100) : 0
    property int memTotalInternal: 0
    property int memFreeInternal: 0
    property int memAvailableInternal: 0
    property int memBuffersInternal: 0
    property int memCachedInternal: 0
    
    // Swap info in MB
    readonly property int swapTotal: swapTotalInternal
    readonly property int swapUsed: swapUsedInternal
    readonly property real swapUsagePercent: swapTotal > 0 ? (swapUsed / swapTotal * 100) : 0
    property int swapTotalInternal: 0
    property int swapUsedInternal: 0
    
    // =====================================================
    // THERMAL ZONES (lazy loaded when control center opens)
    // =====================================================
    
    // Array of thermal zone objects: { type: string, temp: int, critical: int }
    readonly property var thermalZones: thermalZonesInternal
    property var thermalZonesInternal: []
    
    // =====================================================
    // I/O SCHEDULER PROPERTIES (lazy loaded)
    // =====================================================
    
    // Map of disk -> { scheduler: string, available: [string] }
    readonly property var diskSchedulers: diskSchedulersInternal
    property var diskSchedulersInternal: ({})
    
    // =====================================================
    // FAN SPEED PROPERTIES (lazy loaded)
    // =====================================================
    
    // Array of fan objects: { name: string, rpm: int }
    readonly property var fanSpeeds: fanSpeedsInternal
    property var fanSpeedsInternal: []

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
        setCustomPowerMode(defaults.powerProfile);
        setCpuBoost(defaults.cpuBoost);
        if (cpuGovernorsAvailable.includes(defaults.cpuGovernor)) {
            setCpuGovernor(defaults.cpuGovernor);
        }
        if (cpuEppAvailable.includes(defaults.cpuEpp)) {
            setCpuEpp(defaults.cpuEpp);
        }
    }
    
    function resetBatteryToDefault(): void {
        setConservationMode(defaults.conservationMode);
    }
    
    function resetGpuToDefault(): void {
        setGpuPersistenceMode(defaults.gpuPersistence);
    }
    
    function resetRgbToDefault(): void {
        setRgbMode(defaults.rgbMode);
        setRgbColors(defaults.rgbColors);
        rgbEnabledInternal = true;
        // Save as new checkpoint and persist to file
        saveRgbState();
        persistRgbSettings();
    }
    
    function saveRgbState(): void {
        rgbSavedMode = rgbCurrentModeInternal;
        rgbSavedColors = rgbColorsInternal.slice();  // Clone array
        rgbSavedSpeed = rgbSpeedInternal;
        rgbSavedBreathingColor = rgbBreathingColorInternal;
        // Also persist to file
        persistRgbSettings();
    }
    
    function revertRgbChanges(): void {
        // Revert to persisted state (from file)
        setRgbMode(rgbPersistedMode);
        setRgbColors(rgbPersistedColors);
        setRgbSpeed(rgbPersistedSpeed);
        setRgbBreathingColor(rgbPersistedBreathingColor);
        setRgbEnabled(rgbPersistedEnabled);
        // Update saved state to match persisted
        rgbSavedMode = rgbPersistedMode;
        rgbSavedColors = [...rgbPersistedColors];
        rgbSavedSpeed = rgbPersistedSpeed;
        rgbSavedBreathingColor = rgbPersistedBreathingColor;
    }
    
    function resetAllToDefault(): void {
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
        cpuGovernorProcess.command = ["sh", "-c", 
            `echo "${governor}" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null`
        ];
        cpuGovernorProcess.running = true;
    }
    
    function setCpuBoost(enabled: bool): void {
        if (!cpuBoostSupported) return;
        cpuBoostProcess.command = ["sh", "-c", 
            `echo "${enabled ? "1" : "0"}" | sudo tee /sys/devices/system/cpu/cpufreq/boost > /dev/null`
        ];
        cpuBoostProcess.running = true;
    }
    
    function setCState(stateIndex: int, disabled: bool): void {
        // Disabling C-States can increase power consumption but may improve latency
        // stateIndex: 0=POLL, 1=C1, 2=C2, 3=C3
        cstateProcess.stateIndex = stateIndex;
        cstateProcess.newDisabled = disabled;
        cstateProcess.command = ["sh", "-c", 
            `for cpu in /sys/devices/system/cpu/cpu*/cpuidle/state${stateIndex}/; do echo "${disabled ? "1" : "0"}" | sudo tee "\${cpu}disable" > /dev/null; done`
        ];
        cstateProcess.running = true;
    }
    
    Process {
        id: cstateProcess
        property int stateIndex: 0
        property bool newDisabled: false
        
        onExited: (code, status) => {
            // Update array in-place to avoid scroll jump
            if (code === 0 && stateIndex < root.cpuCStatesInternal.length) {
                const updated = root.cpuCStatesInternal.slice();
                const old = updated[stateIndex];
                updated[stateIndex] = {
                    name: old.name,
                    desc: old.desc,
                    latency: old.latency,
                    disabled: newDisabled
                };
                root.cpuCStatesInternal = updated;
            }
        }
    }
    
    function setCpuEpp(epp: string): void {
        if (!cpuEppAvailable.includes(epp)) return;
        cpuEppProcess.command = ["sh", "-c", 
            `echo "${epp}" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null`
        ];
        cpuEppProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - PLATFORM PROFILE
    // =====================================================
    
    function setPlatformProfile(profile: string): void {
        if (!platformProfilesAvailable.includes(profile)) return;
        platformProfileProcess.command = ["sh", "-c", 
            `echo "${profile}" | sudo tee /sys/firmware/acpi/platform_profile > /dev/null`
        ];
        platformProfileProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - CUSTOM POWER MODE
    // =====================================================
    
    function setCustomPowerMode(mode: string): void {
        if (!customPowerModesAvailable.includes(mode)) return;
        
        const config = customPowerModeConfigs[mode];
        if (!config) return;
        
        // Update internal state immediately for UI responsiveness
        customPowerModeInternal = mode;
        
        // Set governor first
        if (cpuGovernorsAvailable.includes(config.governor)) {
            setCpuGovernor(config.governor);
        }
        
        // Set EPP if available (amd_pstate-epp driver)
        if (cpuEppAvailable.includes(config.epp)) {
            setCpuEpp(config.epp);
        }
        
        // Set boost
        if (cpuBoostSupported) {
            setCpuBoost(config.boost);
        }
    }
    
    function refreshCustomPowerMode(): void {
        // Determine current mode based on current settings
        const currentGovernor = cpuGovernor;
        const currentEpp = cpuEpp;
        const currentBoost = cpuBoostEnabled;
        
        // Match against known configurations
        if (currentGovernor === "performance" && 
            (currentEpp === "performance" || currentEpp === "") && 
            currentBoost) {
            customPowerModeInternal = "performance";
        } else if (currentGovernor === "powersave" && 
                   (currentEpp === "balance_power" || currentEpp === "power") && 
                   !currentBoost) {
            customPowerModeInternal = "power-saver";
        } else {
            customPowerModeInternal = "balanced";
        }
    }
    
    // =====================================================
    // FUNCTIONS - GPU
    // =====================================================
    
    function setGpuPowerLimit(watts: int): void {
        if (watts < gpuPowerMin || watts > gpuPowerMax) return;
        gpuPowerLimitProcess.command = ["sudo", "nvidia-smi", "-pl", watts.toString()];
        gpuPowerLimitProcess.running = true;
    }
    
    function resetGpuPowerLimit(): void {
        setGpuPowerLimit(gpuPowerDefault);
    }
    
    function setGpuPersistenceMode(enabled: bool): void {
        gpuPersistenceProcess.command = ["sudo", "nvidia-smi", "-pm", enabled ? "1" : "0"];
        gpuPersistenceProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - BATTERY
    // =====================================================
    
    function setConservationMode(enabled: bool): void {
        if (!hasConservationMode) return;
        conservationModeProcess.command = ["sh", "-c", 
            `echo "${enabled ? "1" : "0"}" | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/conservation_mode > /dev/null`
        ];
        conservationModeProcess.running = true;
    }
    
    function setUsbCharging(enabled: bool): void {
        if (!hasUsbCharging) return;
        usbChargingProcess.command = ["sh", "-c", 
            `echo "${enabled ? "1" : "0"}" | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC*/usb_charging > /dev/null`
        ];
        usbChargingProcess.running = true;
    }
    
    function setFnLock(enabled: bool): void {
        if (!hasFnLock) return;
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
        gpuModeProcess.command = ["sudo", "envycontrol", "-s", mode];
        gpuModeProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - GPU PRIORITY (Hyprland DRM device order)
    // =====================================================
    
    function setGpuPriority(priority: string): void {
        if (!hasGpuPriority || !gpuPrioritiesAvailable.includes(priority)) return;
        gpuPriorityProcess.command = [
            Paths.scriptsDir + "/gpu-priority.sh", 
            "set", 
            priority
        ];
        gpuPriorityProcess.running = true;
    }
    
    function toggleGpuPriority(): void {
        if (!hasGpuPriority) return;
        const newPriority = gpuPriority === "nvidia" ? "integrated" : "nvidia";
        setGpuPriority(newPriority);
    }
    
    function refreshGpuPriority(): void {
        gpuPriorityReadProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - GPU PROCESSES
    // =====================================================
    
    function killGpuProcess(pid: int): void {
        killProcessProcess.command = ["kill", "-9", pid.toString()];
        killProcessProcess.running = true;
    }
    
    // =====================================================
    // FUNCTIONS - APP PROFILES
    // =====================================================
    
    function applyProfile(profileIndex: int): void {
        if (profileIndex < 0 || profileIndex >= appProfiles.length) return;
        const profile = appProfiles[profileIndex];
        
        // Apply actions
        for (const action of profile.actions) {
            switch (action.type) {
                case "power_profile":
                    setCustomPowerMode(action.value);
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
        rgbProcess.command = cmd;
        rgbProcess.running = true;
    }
    
    function setRgbEnabled(enabled: bool): void {
        if (!hasRgbKeyboard) return;
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
        rgbCurrentModeInternal = mode;
        // Priority command - goes to front of queue
        // Include appropriate parameters for each mode type
        if (mode === "Direct") {
            const colorString = rgbColorsInternal.map(c => c.replace("#", "")).join(",");
            queueRgbCommand(["openrgb", "-d", "0", "-m", "Direct", "-c", colorString], true);
        } else if (mode === "Breathing") {
            const color = rgbBreathingColorInternal.replace("#", "");
            queueRgbCommand(["openrgb", "-d", "0", "-m", "Breathing", "-s", rgbSpeedInternal.toString(), "-c", color], true);
        } else {
            // Rainbow Wave, Spectrum Cycle, etc. - just need mode + speed
            queueRgbCommand(["openrgb", "-d", "0", "-m", mode, "-s", rgbSpeedInternal.toString()], true);
        }
    }
    
    function setRgbColor(zoneIndex: int, color: string): void {
        if (!hasRgbKeyboard || zoneIndex < 0 || zoneIndex > 3) return;
        // Ensure color has # prefix for internal storage
        const normalizedColor = color.startsWith("#") ? color : "#" + color;
        // Update internal colors array immediately for UI responsiveness
        let newColors = [...rgbColorsInternal];
        newColors[zoneIndex] = normalizedColor;
        rgbColorsInternal = newColors;
        if (rgbEnabled) rgbLastColors = [...newColors];
        rgbCurrentModeInternal = "Direct";
        
        // Combined command: mode + colors in single call
        const colorString = newColors.map(c => c.replace("#", "")).join(",");
        queueRgbCommand(["openrgb", "-d", "0", "-m", "Direct", "-c", colorString], true);
    }
    
    function setRgbColors(colors: var): void {
        if (!hasRgbKeyboard || colors.length !== 4) return;
        rgbColorsInternal = colors;
        // Only save to lastColors if not turning off
        const isOff = colors.every(c => c === "#000000");
        if (!isOff) rgbLastColors = [...colors];
        rgbCurrentModeInternal = "Direct";
        
        // Combined command: mode + colors in single call (faster!)
        const colorString = colors.map(c => c.replace("#", "")).join(",");
        queueRgbCommand(["openrgb", "-d", "0", "-m", "Direct", "-c", colorString], true);
    }
    
    function setRgbPreset(presetIndex: int): void {
        if (presetIndex < 0 || presetIndex >= rgbPresets.length) return;
        const preset = rgbPresets[presetIndex];
        
        rgbEnabledInternal = true;
        setRgbColors(preset.colors);
    }
    
    function setRgbSpeed(speed: int): void {
        if (!hasRgbKeyboard || speed < 0 || speed > 100) return;
        rgbSpeedInternal = speed;
        if (rgbModeSupportsSpeed) {
            const mode = rgbCurrentModeInternal;
            if (mode === "Breathing") {
                // Breathing mode needs speed + color
                const color = rgbBreathingColorInternal.replace("#", "");
                queueRgbCommand(["openrgb", "-d", "0", "-m", "Breathing", "-s", speed.toString(), "-c", color], false);
            } else {
                // Other animated modes just need speed
                queueRgbCommand(["openrgb", "-d", "0", "-m", mode, "-s", speed.toString()], false);
            }
        }
    }
    
    function setRgbBreathingColor(color: string): void {
        if (!hasRgbKeyboard) return;
        rgbBreathingColorInternal = color;
        if (rgbCurrentModeInternal === "Breathing") {
            // Include speed for complete state
            queueRgbCommand(["openrgb", "-d", "0", "-m", "Breathing", "-s", rgbSpeedInternal.toString(), "-c", color.replace("#", "")], false);
        }
    }
    
    function refreshRgb(): void {
        // Reconnect to OpenRGB server if disconnected
        if (!rgbServerReady && !rgbConnectProcess.running && !rgbRetryTimer.running) {
            rgbRetryCount = 0;  // Reset retry count on manual refresh
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
        refreshCustomPowerMode();
        refreshPlatformProfile();
        refreshGpuInfo();
        refreshBattery();
        refreshGpuMode();
        refreshGpuPriority();
        refreshGpuProcesses();
        // Note: refreshRgb() is called from shell.qml on startup
    }
    
    // Refresh essential data for bar display (battery + power mode)
    // Called on shell startup - lightweight, doesn't need Control Center
    function refreshEssentials(): void {
        refreshBattery();
        refreshCustomPowerMode();
        refreshCpuGovernor();  // Needed for power mode detection
        refreshCpuBoost();
        refreshCpuEpp();
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
    
    // Memory/swap refresh - only call when control center is visible
    function refreshMemory(): void {
        memoryProcess.running = true;
    }
    
    // Thermal zones refresh
    function refreshThermal(): void {
        thermalProcess.running = true;
    }
    
    // Disk scheduler refresh
    function refreshDiskSchedulers(): void {
        diskSchedulerProcess.running = true;
    }
    
    // Fan speed refresh
    function refreshFanSpeeds(): void {
        fanSpeedProcess.running = true;
    }
    
    // Refresh all extended hardware info (called when control center opens)
    function refreshExtendedInfo(): void {
        refreshMemory();
        refreshThermal();
        refreshDiskSchedulers();
        refreshFanSpeeds();
        refreshCStates();
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
            Qt.callLater(root.refreshGpuInfo);
        }
    }
    
    Process {
        id: gpuPersistenceProcess
        onExited: (code, status) => {
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
            Qt.callLater(root.refreshBattery);
        }
    }
    
    Process {
        id: fnLockProcess
        onExited: (code, status) => {
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
            Qt.callLater(root.refreshGpuMode);
        }
    }
    
    // =====================================================
    // PROCESSES - GPU PRIORITY
    // =====================================================
    
    Process {
        id: gpuPriorityReadProcess
        command: [Paths.scriptsDir + "/gpu-priority.sh", "get"]
        stdout: SplitParser {
            onRead: data => {
                root.gpuPriorityInternal = data.trim();
            }
        }
    }
    
    Process {
        id: gpuPriorityProcess
        onExited: (code, status) => {
            Qt.callLater(root.refreshGpuPriority);
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
        command: ["timeout", "3", "openrgb", "--list-devices"]
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
                root.hasRgbKeyboardInternal = true;
                root.rgbServerReady = true;
                root.rgbServerStateInternal = 2;  // Connected
                root.rgbRetryCount = 0;  // Reset retry counter on success
                
                // Extract device name
                const lines = output.split("\n");
                for (const line of lines) {
                    if (line.includes("0:")) {
                        const match = line.match(/0:\s*(.+)/);
                        if (match) root.rgbDeviceNameInternal = match[1].trim();
                        break;
                    }
                }
                
                // FORCE SYNC: Apply current state to keyboard
                if (root.rgbEnabledInternal) {
                    const mode = root.rgbCurrentModeInternal;
                    // Build command based on mode
                    if (mode === "Direct") {
                        // Direct mode: mode + colors
                        const colorString = root.rgbColorsInternal.map(c => c.replace("#", "")).join(",");
                        root.queueRgbCommand(["openrgb", "-d", "0", "-m", "Direct", "-c", colorString], true);
                    } else if (mode === "Breathing") {
                        // Breathing mode: mode + speed + color
                        const color = root.rgbBreathingColorInternal.replace("#", "");
                        root.queueRgbCommand(["openrgb", "-d", "0", "-m", "Breathing", "-s", root.rgbSpeedInternal.toString(), "-c", color], true);
                    } else {
                        // Other animated modes (Rainbow Wave, Spectrum Cycle): mode + speed
                        root.queueRgbCommand(["openrgb", "-d", "0", "-m", mode, "-s", root.rgbSpeedInternal.toString()], true);
                    }
                } else {
                    root.queueRgbCommand(["openrgb", "-d", "0", "-m", "Direct", "-c", "000000,000000,000000,000000"], true);
                }
                
                Qt.callLater(root.processRgbQueue);
            } else {
                // Server not available - mark as not ready during retry attempts
                root.hasRgbKeyboardInternal = false;  // Hide UI while retrying
                root.rgbServerReady = false;
                
                // Schedule retry if we haven't exceeded max retries
                if (root.rgbRetryCount < root.rgbMaxRetries) {
                    const delay = root.rgbRetryDelays[root.rgbRetryCount];
                    root.rgbRetryCount++;
                    root.rgbServerStateInternal = 1;  // Connecting (retry in progress)
                    rgbRetryTimer.interval = delay;
                    rgbRetryTimer.start();
                } else {
                    // Exhausted retries
                    root.rgbServerStateInternal = 0;  // Disconnected
                    root.rgbRetryCount = 0;  // Reset for future manual refresh
                }
            }
        }
    }
    
    // Timer for RGB connection retry with exponential backoff
    Timer {
        id: rgbRetryTimer
        repeat: false
        onTriggered: {
            root.rgbServerStateInternal = 1;  // Connecting
            rgbConnectProcess.running = true;
        }
    }
    
    // RGB command executor
    Process {
        id: rgbProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
            }
            root.rgbCommandRunning = false;
            Qt.callLater(root.processRgbQueue);
        }
    }
    
    // =====================================================
    // REFRESH TIMER
    // =====================================================
    
    // Control whether real-time monitoring is active
    // Set to true when control center Hardware pane is visible
    property bool monitoringActive: false
    
    // Track if initial refresh has been done (lazy loading)
    property bool hasInitialized: false
    
    // Initialize power mode data on component load
    Component.onCompleted: {
        Qt.callLater(() => {
            refreshCpuGovernor();
            refreshCpuBoost();
            refreshCpuEpp();
            refreshCustomPowerMode();
        });
    }
    
    // Trigger lazy initialization when monitoringActive becomes true
    onMonitoringActiveChanged: {
        if (monitoringActive && !hasInitialized) {
            hasInitialized = true;
            refresh();
        }
    }
    
    // Detailed monitoring timer - only when Control Center is open
    Timer {
        id: refreshTimer
        interval: 2000
        repeat: true
        running: root.monitoringActive
        
        onTriggered: {
            root.refreshCpuFreq();
            root.refreshCpuTemp();
            root.refreshCpuUsage();
            root.refreshBattery();  // Full battery info for Control Center
            if (root.hasNvidiaGpu) {
                root.refreshGpuInfo();
                root.refreshGpuProcesses();
            }
        }
    }
    
    // =====================================================
    // CPU C-STATES (IDLE STATES)
    // =====================================================
    
    function refreshCStates(): void {
        cpuCStatesProcess.running = true;
    }
    
    Process {
        id: cpuCStatesProcess
        command: ["sh", "-c", `
            driver=$(cat /sys/devices/system/cpu/cpuidle/current_driver 2>/dev/null || echo "N/A")
            echo "DRIVER:$driver"
            for state in /sys/devices/system/cpu/cpu0/cpuidle/state*/; do
                name=$(cat "\${state}name" 2>/dev/null)
                desc=$(cat "\${state}desc" 2>/dev/null)
                latency=$(cat "\${state}latency" 2>/dev/null)
                disable=$(cat "\${state}disable" 2>/dev/null)
                echo "STATE:$name|$desc|$latency|$disable"
            done
        `]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("DRIVER:")) {
                    root.cpuIdleDriverInternal = data.substring(7);
                } else if (data.startsWith("STATE:")) {
                    const parts = data.substring(6).split("|");
                    if (parts.length >= 4) {
                        const newState = {
                            name: parts[0],
                            desc: parts[1],
                            latency: parseInt(parts[2]) || 0,
                            disabled: parts[3] === "1"
                        };
                        root.cpuCStatesInternal = [...root.cpuCStatesInternal, newState];
                    }
                }
            }
        }
        onExited: (code, status) => {
            // States collected, no further action needed
        }
    }
    
    // =====================================================
    // RGB SETTINGS PERSISTENCE
    // =====================================================
    
    FileView {
        id: rgbStorage
        
        path: `${Paths.state}/rgb-keyboard.json`
        
        onLoaded: {
            try {
                const data = JSON.parse(text());
                // Apply persisted settings
                root.rgbPersistedMode = data.mode || "Direct";
                root.rgbPersistedColors = data.colors || ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"];
                root.rgbPersistedSpeed = data.speed || 50;
                root.rgbPersistedBreathingColor = data.breathingColor || "#FF0000";
                root.rgbPersistedEnabled = data.enabled !== undefined ? data.enabled : true;
                
                // Also set current state to match persisted state
                root.rgbCurrentModeInternal = root.rgbPersistedMode;
                root.rgbColorsInternal = [...root.rgbPersistedColors];
                root.rgbLastColors = [...root.rgbPersistedColors];
                root.rgbSpeedInternal = root.rgbPersistedSpeed;
                root.rgbBreathingColorInternal = root.rgbPersistedBreathingColor;
                root.rgbEnabledInternal = root.rgbPersistedEnabled;
                
                // Update saved state to match
                root.rgbSavedMode = root.rgbPersistedMode;
                root.rgbSavedColors = [...root.rgbPersistedColors];
                root.rgbSavedSpeed = root.rgbPersistedSpeed;
                root.rgbSavedBreathingColor = root.rgbPersistedBreathingColor;
                
                root.rgbSettingsLoaded = true;
            } catch (e) {
                root.rgbSettingsLoaded = true;
            }
        }
        
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.rgbSettingsLoaded = true;
                // Save defaults to create the file
                root.persistRgbSettings();
            }
        }
    }
    
    Timer {
        id: rgbSaveTimer
        interval: 500  // Debounce saves
        onTriggered: {
            const data = {
                mode: root.rgbCurrentModeInternal,
                colors: root.rgbColorsInternal,
                speed: root.rgbSpeedInternal,
                breathingColor: root.rgbBreathingColorInternal,
                enabled: root.rgbEnabledInternal
            };
            rgbStorage.setText(JSON.stringify(data, null, 2));
            
            // Update persisted state
            root.rgbPersistedMode = root.rgbCurrentModeInternal;
            root.rgbPersistedColors = [...root.rgbColorsInternal];
            root.rgbPersistedSpeed = root.rgbSpeedInternal;
            root.rgbPersistedBreathingColor = root.rgbBreathingColorInternal;
            root.rgbPersistedEnabled = root.rgbEnabledInternal;
        }
    }
    
    function persistRgbSettings(): void {
        if (rgbSettingsLoaded) {
            rgbSaveTimer.restart();
        }
    }
    
    // Slower refresh for settings that don't change often
    Timer {
        id: slowRefreshTimer
        interval: 10000
        repeat: true
        running: root.monitoringActive
        
        onTriggered: {
            root.refreshCpuGovernor();
            root.refreshCpuBoost();
            root.refreshCpuEpp();
            refreshCustomPowerMode();
            root.refreshPlatformProfile();
            root.refreshGpuMode();
        }
    }
    
    // =====================================================
    // PROCESSES - MEMORY & SWAP
    // =====================================================
    
    Process {
        id: memoryProcess
        command: ["sh", "-c", `
            awk '
                /^MemTotal:/ { total=$2 }
                /^MemFree:/ { free=$2 }
                /^MemAvailable:/ { available=$2 }
                /^Buffers:/ { buffers=$2 }
                /^Cached:/ { cached=$2 }
                /^SwapTotal:/ { swaptotal=$2 }
                /^SwapFree:/ { swapfree=$2 }
                END { 
                    printf "%d|%d|%d|%d|%d|%d|%d", 
                        total/1024, free/1024, available/1024, 
                        buffers/1024, cached/1024, 
                        swaptotal/1024, (swaptotal-swapfree)/1024 
                }
            ' /proc/meminfo
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|");
                if (parts.length >= 7) {
                    root.memTotalInternal = parseInt(parts[0]) || 0;
                    root.memFreeInternal = parseInt(parts[1]) || 0;
                    root.memAvailableInternal = parseInt(parts[2]) || 0;
                    root.memBuffersInternal = parseInt(parts[3]) || 0;
                    root.memCachedInternal = parseInt(parts[4]) || 0;
                    root.swapTotalInternal = parseInt(parts[5]) || 0;
                    root.swapUsedInternal = parseInt(parts[6]) || 0;
                }
            }
        }
    }
    
    // =====================================================
    // PROCESSES - THERMAL ZONES
    // =====================================================
    
    Process {
        id: thermalProcess
        command: ["sh", "-c", `
            for zone in /sys/class/thermal/thermal_zone*; do
                if [ -d "$zone" ]; then
                    type=$(cat "$zone/type" 2>/dev/null || echo "unknown")
                    temp=$(cat "$zone/temp" 2>/dev/null || echo "0")
                    echo "$type|$temp"
                fi
            done
        `]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.trim().split("\n").filter(l => l.length > 0);
                let zones = [];
                for (const line of lines) {
                    const parts = line.split("|");
                    if (parts.length >= 2) {
                        zones.push({
                            type: parts[0],
                            temp: Math.round(parseInt(parts[1]) / 1000)
                        });
                    }
                }
                root.thermalZonesInternal = zones;
            }
        }
    }
    
    // =====================================================
    // PROCESSES - DISK SCHEDULERS
    // =====================================================
    
    Process {
        id: diskSchedulerProcess
        command: ["sh", "-c", `
            for disk in /sys/block/nvme* /sys/block/sd*; do
                if [ -f "$disk/queue/scheduler" ]; then
                    name=$(basename "$disk")
                    sched=$(cat "$disk/queue/scheduler" 2>/dev/null)
                    echo "$name|$sched"
                fi
            done
        `]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.trim().split("\n").filter(l => l.length > 0);
                let schedulers = {};
                for (const line of lines) {
                    const parts = line.split("|");
                    if (parts.length >= 2) {
                        const disk = parts[0];
                        const schedLine = parts[1];
                        // Parse scheduler line like "[mq-deadline] kyber bfq"
                        const available = schedLine.replace(/[\[\]]/g, "").split(" ").filter(s => s.length > 0);
                        const currentMatch = schedLine.match(/\[(\w+)\]/);
                        const current = currentMatch ? currentMatch[1] : available[0];
                        schedulers[disk] = { scheduler: current, available: available };
                    }
                }
                root.diskSchedulersInternal = schedulers;
            }
        }
    }
    
    // =====================================================
    // PROCESSES - FAN SPEEDS
    // =====================================================
    
    Process {
        id: fanSpeedProcess
        command: ["sh", "-c", `
            for hwmon in /sys/class/hwmon/hwmon*; do
                for fan in "$hwmon"/fan*_input; do
                    if [ -f "$fan" ]; then
                        name=$(basename "$fan" | sed 's/_input//')
                        rpm=$(cat "$fan" 2>/dev/null || echo "0")
                        label=""
                        labelFile=$(echo "$fan" | sed 's/_input/_label/')
                        if [ -f "$labelFile" ]; then
                            label=$(cat "$labelFile" 2>/dev/null)
                        fi
                        echo "$name|$rpm|$label"
                    fi
                done
            done
        `]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.trim().split("\n").filter(l => l.length > 0);
                let fans = [];
                for (const line of lines) {
                    const parts = line.split("|");
                    if (parts.length >= 2) {
                        fans.push({
                            name: parts[2] || parts[0],
                            rpm: parseInt(parts[1]) || 0
                        });
                    }
                }
                root.fanSpeedsInternal = fans;
            }
        }
    }
    
    // =====================================================
    // INITIALIZATION
    // =====================================================
    // NOTE: Hardware info is lazy-loaded. refresh() is called when
    // monitoringActive becomes true (control center Hardware pane opens)
    // This prevents 14+ process calls at shell startup.
}
