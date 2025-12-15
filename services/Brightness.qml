pragma Singleton
pragma ComponentBehavior: Bound

import qs.components.misc
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property list<var> ddcMonitors: []
    readonly property list<Monitor> monitors: variants.instances
    property bool appleDisplayPresent: false

    // =====================================================
    // COLOR TEMPERATURE / GAMMA
    // =====================================================
    
    // Available gamma backend
    property string gammaBackend: "none"  // "hyprsunset", "wlsunset", "gammastep", "none"
    
    // Current color temperature (in Kelvin, 1000-10000, default 6500 = neutral)
    property int colorTemperature: 6500
    
    // Night light enabled state
    property bool nightLightEnabled: false
    
    // Night light temperature (warmer, around 4500K)
    property int nightLightTemperature: 4500
    
    // Gamma process (for hyprsunset/wlsunset)
    property var gammaProcess: null
    
    // Check available gamma tools on startup
    function detectGammaBackend(): void {
        gammaDetectProcess.running = true;
    }
    
    // Set color temperature
    function setColorTemperature(temp: int): void {
        colorTemperature = Math.max(1000, Math.min(10000, temp));
        applyColorTemperature();
    }
    
    // Toggle night light
    function toggleNightLight(): void {
        nightLightEnabled = !nightLightEnabled;
        applyColorTemperature();
    }
    
    // Enable night light
    function enableNightLight(): void {
        nightLightEnabled = true;
        applyColorTemperature();
    }
    
    // Disable night light
    function disableNightLight(): void {
        nightLightEnabled = false;
        applyColorTemperature();
    }
    
    // Apply color temperature using available backend
    function applyColorTemperature(): void {
        const temp = nightLightEnabled ? nightLightTemperature : colorTemperature;
        
        // Kill existing gamma process if any
        if (gammaProcess) {
            gammaProcess.running = false;
        }
        
        switch (gammaBackend) {
            case "hyprsunset":
                // hyprsunset -t <temperature>
                Quickshell.execDetached(["hyprsunset", "-t", temp.toString()]);
                break;
                
            case "wlsunset":
                // wlsunset needs to run as daemon with -T (high temp) and -t (low temp)
                // For manual control, we set both to same value
                gammaProcess = gammaRunProcess;
                gammaRunProcess.command = ["wlsunset", "-T", temp.toString(), "-t", temp.toString()];
                gammaRunProcess.running = true;
                break;
                
            case "gammastep":
                // gammastep -O <temperature>
                Quickshell.execDetached(["gammastep", "-O", temp.toString()]);
                break;
                
            default:
        }
    }
    
    // Reset color temperature to neutral
    function resetColorTemperature(): void {
        colorTemperature = 6500;
        nightLightEnabled = false;
        
        // Kill gamma process
        if (gammaProcess) {
            gammaProcess.running = false;
            gammaProcess = null;
        }
        
        // Reset using backend-specific commands
        switch (gammaBackend) {
            case "hyprsunset":
                // Kill hyprsunset to reset
                Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
                break;
            case "wlsunset":
                Quickshell.execDetached(["pkill", "-x", "wlsunset"]);
                break;
            case "gammastep":
                Quickshell.execDetached(["gammastep", "-x"]);
                break;
        }
    }

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.modelData === screen);
    }

    function getMonitor(query: string): var {
        if (query === "active") {
            return monitors.find(m => Hypr.monitorFor(m.modelData)?.focused);
        }

        if (query.startsWith("model:")) {
            const model = query.slice(6);
            return monitors.find(m => m.modelData.model === model);
        }

        if (query.startsWith("serial:")) {
            const serial = query.slice(7);
            return monitors.find(m => m.modelData.serialNumber === serial);
        }

        if (query.startsWith("id:")) {
            const id = parseInt(query.slice(3), 10);
            return monitors.find(m => Hypr.monitorFor(m.modelData)?.id === id);
        }

        return monitors.find(m => m.modelData.name === query);
    }

    function increaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor)
            monitor.setBrightness(monitor.brightness + 0.1);
    }

    function decreaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor)
            monitor.setBrightness(monitor.brightness - 0.1);
    }

    onMonitorsChanged: {
        ddcMonitors = [];
        ddcProc.running = true;
    }

    Variants {
        id: variants

        model: Quickshell.screens

        Monitor {}
    }

    Process {
        running: true
        command: ["sh", "-c", "asdbctl get"] // To avoid warnings if asdbctl is not installed
        stdout: StdioCollector {
            onStreamFinished: root.appleDisplayPresent = text.trim().length > 0
        }
    }

    Process {
        id: ddcProc

        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: root.ddcMonitors = text.trim().split("\n\n").filter(d => d.startsWith("Display ")).map(d => ({
                        busNum: d.match(/I2C bus:[ ]*\/dev\/i2c-([0-9]+)/)[1],
                        connector: d.match(/DRM connector:\s+(.*)/)[1].replace(/^card\d+-/, "") // strip "card1-"
                    }))
        }
    }

    // Process to detect available gamma backend
    Process {
        id: gammaDetectProcess
        
        command: ["sh", "-c", "which hyprsunset 2>/dev/null && echo hyprsunset || which wlsunset 2>/dev/null && echo wlsunset || which gammastep 2>/dev/null && echo gammastep || echo none"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                // Get the last line which is the backend name
                const backend = lines[lines.length - 1].trim();
                if (["hyprsunset", "wlsunset", "gammastep"].includes(backend)) {
                    root.gammaBackend = backend;
                } else {
                    root.gammaBackend = "none";
                }
            }
        }
    }
    
    // Process to run gamma daemon (for wlsunset)
    Process {
        id: gammaRunProcess
        
        onExited: (exitCode, exitStatus) => {
        }
    }

    CustomShortcut {
        name: "brightnessUp"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    CustomShortcut {
        name: "brightnessDown"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }

    CustomShortcut {
        name: "nightLightToggle"
        description: "Toggle night light (warmer colors)"
        onPressed: root.toggleNightLight()
    }

    IpcHandler {
        target: "brightness"

        function get(): real {
            return getFor("active");
        }

        // Allows searching by active/model/serial/id/name
        function getFor(query: string): real {
            return root.getMonitor(query)?.brightness ?? -1;
        }

        function set(value: string): string {
            return setFor("active", value);
        }

        // Handles brightness value like brightnessctl: 0.1, +0.1, 0.1-, 10%, +10%, 10%-
        function setFor(query: string, value: string): string {
            const monitor = root.getMonitor(query);
            if (!monitor)
                return "Invalid monitor: " + query;

            let targetBrightness;
            if (value.endsWith("%-")) {
                const percent = parseFloat(value.slice(0, -2));
                targetBrightness = monitor.brightness - (percent / 100);
            } else if (value.startsWith("+") && value.endsWith("%")) {
                const percent = parseFloat(value.slice(1, -1));
                targetBrightness = monitor.brightness + (percent / 100);
            } else if (value.endsWith("%")) {
                const percent = parseFloat(value.slice(0, -1));
                targetBrightness = percent / 100;
            } else if (value.startsWith("+")) {
                const increment = parseFloat(value.slice(1));
                targetBrightness = monitor.brightness + increment;
            } else if (value.endsWith("-")) {
                const decrement = parseFloat(value.slice(0, -1));
                targetBrightness = monitor.brightness - decrement;
            } else if (value.includes("%") || value.includes("-") || value.includes("+")) {
                return `Invalid brightness format: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;
            } else {
                targetBrightness = parseFloat(value);
            }

            if (isNaN(targetBrightness))
                return `Failed to parse value: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;

            monitor.setBrightness(targetBrightness);

            return `Set monitor ${monitor.modelData.name} brightness to ${+monitor.brightness.toFixed(2)}`;
        }
    }

    component Monitor: QtObject {
        id: monitor

        required property ShellScreen modelData
        readonly property bool isDdc: root.ddcMonitors.some(m => m.connector === modelData.name)
        readonly property string busNum: root.ddcMonitors.find(m => m.connector === modelData.name)?.busNum ?? ""
        readonly property bool isAppleDisplay: root.appleDisplayPresent && modelData.model.startsWith("StudioDisplay")
        property real brightness
        property real queuedBrightness: NaN

        readonly property Process initProc: Process {
            stdout: StdioCollector {
                onStreamFinished: {
                    if (monitor.isAppleDisplay) {
                        const val = parseInt(text.trim());
                        monitor.brightness = val / 101;
                    } else {
                        const [, , , cur, max] = text.split(" ");
                        monitor.brightness = parseInt(cur) / parseInt(max);
                    }
                }
            }
        }

        readonly property Timer timer: Timer {
            interval: 500
            onTriggered: {
                if (!isNaN(monitor.queuedBrightness)) {
                    monitor.setBrightness(monitor.queuedBrightness);
                    monitor.queuedBrightness = NaN;
                }
            }
        }

        function setBrightness(value: real): void {
            value = Math.max(0, Math.min(1, value));
            const rounded = Math.round(value * 100);
            if (Math.round(brightness * 100) === rounded)
                return;

            if (isDdc && timer.running) {
                queuedBrightness = value;
                return;
            }

            brightness = value;

            if (isAppleDisplay)
                Quickshell.execDetached(["asdbctl", "set", rounded]);
            else if (isDdc)
                Quickshell.execDetached(["ddcutil", "-b", busNum, "setvcp", "10", rounded]);
            else
                Quickshell.execDetached(["brightnessctl", "s", `${rounded}%`]);

            if (isDdc)
                timer.restart();
        }

        function initBrightness(): void {
            if (isAppleDisplay)
                initProc.command = ["asdbctl", "get"];
            else if (isDdc)
                initProc.command = ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"];
            else
                initProc.command = ["sh", "-c", "echo a b c $(brightnessctl g) $(brightnessctl m)"];

            initProc.running = true;
        }

        onBusNumChanged: initBrightness()
        Component.onCompleted: initBrightness()
    }
    
    // Detect gamma backend on startup
    Component.onCompleted: {
        detectGammaBackend();
    }
}
