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
    
    // =====================================================
    // TDP PROPERTIES (AMD RyzenAdj)
    // =====================================================
    
    readonly property bool hasRyzenAdj: hasRyzenAdjInternal
    property bool hasRyzenAdjInternal: false
    
    // TDP values (Watts)
    readonly property real tdpStapmLimit: tdpStapmLimitInternal
    readonly property real tdpStapmValue: tdpStapmValueInternal
    readonly property real tdpFastLimit: tdpFastLimitInternal
    readonly property real tdpFastValue: tdpFastValueInternal
    readonly property real tdpSlowLimit: tdpSlowLimitInternal
    readonly property real tdpSlowValue: tdpSlowValueInternal
    property real tdpStapmLimitInternal: 0
    property real tdpStapmValueInternal: 0
    property real tdpFastLimitInternal: 0
    property real tdpFastValueInternal: 0
    property real tdpSlowLimitInternal: 0
    property real tdpSlowValueInternal: 0
    
    // Thermal limit
    readonly property real tdpThermalLimit: tdpThermalLimitInternal
    readonly property real tdpThermalValue: tdpThermalValueInternal
    property real tdpThermalLimitInternal: 100
    property real tdpThermalValueInternal: 0
    
    // TDP presets
    readonly property var tdpPresets: [
        { name: "Silent", stapm: 15, fast: 20, slow: 18 },
        { name: "Eco", stapm: 25, fast: 30, slow: 28 },
        { name: "Balanced", stapm: 45, fast: 55, slow: 50 },
        { name: "Performance", stapm: 65, fast: 80, slow: 75 },
        { name: "Max", stapm: 80, fast: 90, slow: 85 }
    ]
    
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
    // Default to true for Lenovo Legion - will be validated on startup
    property bool hasRgbKeyboardInternal: true
    property bool rgbEnabledInternal: true
    property string rgbDeviceNameInternal: "Lenovo 5 2021"
    property var rgbModesInternal: ["Direct", "Breathing", "Rainbow Wave", "Spectrum Cycle"]
    property string rgbCurrentModeInternal: "Direct"
    property var rgbColorsInternal: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]
    property var rgbLastColors: ["#FF0000", "#00FF00", "#0000FF", "#FF00FF"]  // Store colors when turning off
    
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
    
    // =====================================================
    // DEFAULT VALUES (for reset functionality)
    // =====================================================
    
    readonly property var defaults: ({
        powerProfile: "balanced",
        cpuBoost: true,
        cpuGovernor: "powersave",
        cpuEpp: "balance_performance",
        tdpStapm: 45,
        tdpFast: 55,
        tdpSlow: 50,
        thermalLimit: 100,
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
    
    function resetTdpToDefault(): void {
        console.log("[Hardware] Resetting TDP to defaults");
        setTdp(defaults.tdpStapm, defaults.tdpFast, defaults.tdpSlow);
        setThermalLimit(defaults.thermalLimit);
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
    }
    
    function resetAllToDefault(): void {
        console.log("[Hardware] Resetting ALL settings to defaults");
        resetCpuToDefault();
        resetTdpToDefault();
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
    
    // =====================================================
    // FUNCTIONS - TDP (RyzenAdj)
    // =====================================================
    
    function setTdp(stapm: int, fast: int, slow: int): void {
        if (!hasRyzenAdj) return;
        console.log("[Hardware] Setting TDP - STAPM:", stapm, "Fast:", fast, "Slow:", slow);
        tdpProcess.command = ["sudo", "ryzenadj", 
            "--stapm-limit=" + (stapm * 1000).toString(),
            "--fast-limit=" + (fast * 1000).toString(),
            "--slow-limit=" + (slow * 1000).toString()
        ];
        tdpProcess.running = true;
    }
    
    function setTdpPreset(presetIndex: int): void {
        if (presetIndex < 0 || presetIndex >= tdpPresets.length) return;
        const preset = tdpPresets[presetIndex];
        setTdp(preset.stapm, preset.fast, preset.slow);
    }
    
    function setThermalLimit(temp: int): void {
        if (!hasRyzenAdj || temp < 60 || temp > 105) return;
        console.log("[Hardware] Setting thermal limit to:", temp);
        tdpThermalProcess.command = ["sudo", "ryzenadj", "--tctl-temp=" + temp.toString()];
        tdpThermalProcess.running = true;
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
    // FUNCTIONS - RGB KEYBOARD
    // =====================================================
    
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
        console.log("[Hardware] Setting RGB mode to:", mode);
        rgbCurrentModeInternal = mode;
        rgbModeProcess.command = ["openrgb", "-d", "0", "-m", mode];
        rgbModeProcess.running = true;
    }
    
    function setRgbColor(zoneIndex: int, color: string): void {
        if (!hasRgbKeyboard || zoneIndex < 0 || zoneIndex > 3) return;
        console.log("[Hardware] Setting RGB zone", zoneIndex, "to:", color);
        // Update internal colors array
        let newColors = [...rgbColorsInternal];
        newColors[zoneIndex] = color;
        rgbColorsInternal = newColors;
        if (rgbEnabled) rgbLastColors = [...newColors];
        // Apply via openrgb
        const colorHex = color.replace("#", "");
        rgbColorProcess.command = ["openrgb", "-d", "0", "-z", zoneIndex.toString(), "-c", colorHex];
        rgbColorProcess.running = true;
    }
    
    function setRgbColors(colors: var): void {
        if (!hasRgbKeyboard || colors.length !== 4) return;
        console.log("[Hardware] Setting all RGB colors");
        rgbColorsInternal = colors;
        // Only save to lastColors if not turning off
        const isOff = colors.every(c => c === "#000000");
        if (!isOff) rgbLastColors = [...colors];
        // Build command to set all zones at once
        const cmd = ["openrgb", "-d", "0"];
        for (let i = 0; i < 4; i++) {
            cmd.push("-z", i.toString(), "-c", colors[i].replace("#", ""));
        }
        rgbAllColorsProcess.command = cmd;
        rgbAllColorsProcess.running = true;
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
    
    function setRgbBrightness(brightness: int): void {
        if (!hasRgbKeyboard || brightness < 0 || brightness > 100) return;
        console.log("[Hardware] Setting RGB brightness to:", brightness);
        rgbBrightnessProcess.command = ["openrgb", "-d", "0", "-b", brightness.toString()];
        rgbBrightnessProcess.running = true;
    }
    
    function refreshRgb(): void {
        rgbCheckProcess.running = true;
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
        refreshTdp();
        refreshGpuMode();
        refreshGpuProcesses();
        refreshRgb();
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
    }
    
    function refreshTdp(): void {
        ryzenAdjCheckProcess.running = true;
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
    
    // =====================================================
    // PROCESSES - TDP (RyzenAdj)
    // =====================================================
    
    Process {
        id: ryzenAdjCheckProcess
        command: ["which", "ryzenadj"]
        onExited: (code, status) => {
            root.hasRyzenAdjInternal = code === 0;
            if (code === 0) {
                tdpReadProcess.running = true;
            }
        }
    }
    
    Process {
        id: tdpReadProcess
        command: ["sudo", "ryzenadj", "-i"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.split("\n");
                for (const line of lines) {
                    if (line.includes("STAPM LIMIT")) {
                        const match = line.match(/\|\s*([\d.]+)/);
                        if (match) root.tdpStapmLimitInternal = parseFloat(match[1]);
                    } else if (line.includes("STAPM VALUE")) {
                        const match = line.match(/\|\s*([\d.]+)/);
                        if (match) root.tdpStapmValueInternal = parseFloat(match[1]);
                    } else if (line.includes("PPT LIMIT FAST")) {
                        const match = line.match(/\|\s*([\d.]+)/);
                        if (match) root.tdpFastLimitInternal = parseFloat(match[1]);
                    } else if (line.includes("PPT VALUE FAST")) {
                        const match = line.match(/\|\s*([\d.]+)/);
                        if (match) root.tdpFastValueInternal = parseFloat(match[1]);
                    } else if (line.includes("PPT LIMIT SLOW") && !line.includes("APU")) {
                        const match = line.match(/\|\s*([\d.]+)/);
                        if (match) root.tdpSlowLimitInternal = parseFloat(match[1]);
                    } else if (line.includes("PPT VALUE SLOW") && !line.includes("APU")) {
                        const match = line.match(/\|\s*([\d.]+)/);
                        if (match) root.tdpSlowValueInternal = parseFloat(match[1]);
                    } else if (line.includes("THM LIMIT CORE")) {
                        const match = line.match(/\|\s*([\d.]+)/);
                        if (match) root.tdpThermalLimitInternal = parseFloat(match[1]);
                    } else if (line.includes("THM VALUE CORE")) {
                        const match = line.match(/\|\s*([\d.]+)/);
                        if (match) root.tdpThermalValueInternal = parseFloat(match[1]);
                    }
                }
            }
        }
    }
    
    Process {
        id: tdpProcess
        onExited: (code, status) => {
            console.log("[Hardware] TDP set, exit code:", code);
            Qt.callLater(root.refreshTdp);
        }
    }
    
    Process {
        id: tdpThermalProcess
        onExited: (code, status) => {
            console.log("[Hardware] Thermal limit set, exit code:", code);
            Qt.callLater(root.refreshTdp);
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
    // PROCESSES - RGB KEYBOARD
    // =====================================================
    
    Process {
        id: rgbCheckProcess
        command: ["openrgb", "--list-devices"]
        property string outputBuffer: ""
        
        stdout: SplitParser {
            onRead: data => {
                rgbCheckProcess.outputBuffer += data.toString();
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            const output = rgbCheckProcess.outputBuffer.toLowerCase();
            console.log("[Hardware] OpenRGB output length:", output.length, "exit:", exitCode);
            rgbCheckProcess.outputBuffer = "";
            
            if (exitCode === 0 && (output.includes("lenovo") || output.includes("4-zone") || output.includes("keyboard"))) {
                console.log("[Hardware] RGB keyboard detected!");
                root.hasRgbKeyboardInternal = true;
                
                // Extract device name from output like "0: Lenovo 5 2021"
                const lines = output.split("\n");
                for (const line of lines) {
                    if (line.includes("0:")) {
                        const match = line.match(/0:\s*(.+)/);
                        if (match) {
                            root.rgbDeviceNameInternal = match[1].trim();
                        }
                        break;
                    }
                }
            } else {
                console.log("[Hardware] No RGB keyboard found or OpenRGB not available");
                root.hasRgbKeyboardInternal = false;
            }
        }
    }
    
    Process {
        id: rgbModeProcess
        // Command set dynamically
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("[Hardware] Failed to set RGB mode");
            }
        }
    }
    
    Process {
        id: rgbColorProcess
        // Command set dynamically
    }
    
    Process {
        id: rgbAllColorsProcess
        // Command set dynamically
    }
    
    Process {
        id: rgbBrightnessProcess
        // Command set dynamically
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
            root.refreshTdp();
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
