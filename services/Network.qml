pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property list<SavedConnection> savedConnections: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running
    readonly property bool connecting: connectProc.running
    property string connectionError: ""
    property string lastConnectedSSID: ""
    
    // Connection state management
    property bool connectionFailed: false
    property string failedSSID: ""
    
    // Captive portal detection
    property bool captivePortalDetected: false
    property string captivePortalUrl: ""
    
    // Warning/Info messages
    property string warningMessage: ""
    property string warningType: "info" // info, warning, error, success

    // Network traffic monitoring
    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0    // bytes per second
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property string networkInterface: ""
    
    // Check if a saved network is currently in range
    function isSavedNetworkInRange(ssid) {
        return networks.some(n => n.ssid === ssid);
    }
    
    // Get the AccessPoint for a saved network if in range
    function getSavedNetworkAccessPoint(ssid) {
        return networks.find(n => n.ssid === ssid) ?? null;
    }
    
    // Format bytes to human readable
    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
        } else if (bytesPerSec >= 1024) {
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        } else {
            return bytesPerSec.toFixed(0) + " B/s"
        }
    }
    
    // Opacity based on speed (faster = more opaque)
    function speedOpacity(bytesPerSec) {
        const maxSpeed = 1024 * 1024
        const ratio = Math.min(bytesPerSec / maxSpeed, 1.0)
        return 0.3 + (ratio * 0.7)
    }

    function enableWifi(enabled) {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi() {
        const cmd = wifiEnabled ? "off" : "on";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function rescanWifi() {
        rescanProc.running = true;
    }

    function connectToNetwork(ssid, password) {
        root.connectionError = "";
        root.connectionFailed = false;
        root.lastConnectedSSID = ssid;
        
        if (password && password.length > 0) {
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid, "password", password]);
        } else {
            connectProc.exec(["nmcli", "conn", "up", ssid]);
        }
    }

    function connectToNewNetwork(ssid, password) {
        root.connectionError = "";
        root.connectionFailed = false;
        root.lastConnectedSSID = ssid;
        connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid, "password", password]);
    }

    function forgetNetwork(ssid) {
        forgetProc.exec(["nmcli", "connection", "delete", ssid]);
    }

    function disconnectFromNetwork() {
        if (active) {
            disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
        }
    }

    function getWifiStatus() {
        wifiStatusProc.running = true;
    }
    
    // Show a warning/info message
    function showWarning(message, type) {
        root.warningMessage = message;
        root.warningType = type || "info";
        warningTimer.restart();
    }
    
    // Clear warning message
    function clearWarning() {
        root.warningMessage = "";
    }
    
    // Check for captive portal
    function checkCaptivePortal() {
        captivePortalProc.running = true;
    }
    
    // Open captive portal in browser
    function openCaptivePortal() {
        if (captivePortalUrl) {
            captivePortalOpenProc.exec(["xdg-open", captivePortalUrl]);
        }
    }
    
    // Auto-clear warning after 5 seconds
    Timer {
        id: warningTimer
        interval: 5000
        onTriggered: root.warningMessage = ""
    }

    // Network traffic monitoring timer
    Timer {
        id: trafficTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            getInterfaceProc.running = true
        }
    }
    
    // Check captive portal periodically when connected
    Timer {
        id: captivePortalTimer
        interval: 3000
        repeat: false
        running: false
        onTriggered: {
            if (root.active) {
                root.checkCaptivePortal();
            }
        }
    }
    
    // Get active network interface
    Process {
        id: getInterfaceProc
        command: ["sh", "-c", "ip route | grep default | awk '{print $5}' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const iface = text.trim()
                if (iface && iface.length > 0) {
                    root.networkInterface = iface
                    trafficStats.reload()
                }
            }
        }
    }
    
    // Captive portal detection - check connectivity
    Process {
        id: captivePortalProc
        command: ["sh", "-c", "curl -s -o /dev/null -w '%{http_code}:%{redirect_url}' --connect-timeout 5 http://connectivitycheck.gstatic.com/generate_204"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = text.trim();
                const parts = result.split(":");
                const httpCode = parts[0];
                const redirectUrl = parts.slice(1).join(":"); // URL might contain colons
                
                if (httpCode === "204") {
                    // No captive portal - full internet access
                    root.captivePortalDetected = false;
                    root.captivePortalUrl = "";
                } else if (httpCode === "302" || httpCode === "301" || httpCode === "307") {
                    // Redirect detected - likely captive portal
                    root.captivePortalDetected = true;
                    root.captivePortalUrl = redirectUrl || "http://captive.apple.com"; // fallback URL
                    root.showWarning(qsTr("Captive portal detected. Click to authenticate."), "warning");
                } else if (httpCode === "200") {
                    // Got 200 but expected 204 - likely captive portal returning login page
                    root.captivePortalDetected = true;
                    root.captivePortalUrl = "http://captive.apple.com";
                    root.showWarning(qsTr("Network requires authentication. Click to open browser."), "warning");
                }
            }
        }
    }
    
    // Open captive portal in browser
    Process {
        id: captivePortalOpenProc
    }
    
    // Read network traffic from /proc/net/dev
    FileView {
        id: trafficStats
        path: "/proc/net/dev"
        onLoaded: {
            if (!root.networkInterface) return
            
            const lines = text().split("\n")
            for (const line of lines) {
                if (line.includes(root.networkInterface + ":")) {
                    const parts = line.trim().split(/\s+/)
                    if (parts.length >= 10) {
                        const rxBytes = parseInt(parts[1], 10) || 0
                        const txBytes = parseInt(parts[9], 10) || 0
                        
                        if (root.lastRxBytes > 0 && root.lastTxBytes > 0) {
                            root.downloadSpeed = Math.max(0, rxBytes - root.lastRxBytes)
                            root.uploadSpeed = Math.max(0, txBytes - root.lastTxBytes)
                        }
                        
                        root.lastRxBytes = rxBytes
                        root.lastTxBytes = txBytes
                        break
                    }
                }
            }
        }
    }

    Process {
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: wifiStatusProc

        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: enableWifiProc

        onExited: {
            root.getWifiStatus();
            getNetworks.running = true;
        }
    }

    Process {
        id: rescanProc

        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            getNetworks.running = true;
        }
    }

    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: {
                getNetworks.running = true;
                getSavedConnections.running = true;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const errorText = text.trim();
                if (errorText.length > 0) {
                    root.connectionError = errorText;
                    root.connectionFailed = true;
                    root.failedSSID = root.lastConnectedSSID;
                    
                    // Check for specific errors
                    if (errorText.includes("Secrets were required") || 
                        errorText.includes("No secrets") ||
                        errorText.includes("password") ||
                        errorText.includes("802-11-wireless-security")) {
                        // Wrong password - auto-forget the failed connection
                        root.showWarning(qsTr("Wrong password. Please try again."), "error");
                        // Delete the failed connection profile so user can re-enter password
                        forgetProc.exec(["nmcli", "connection", "delete", root.lastConnectedSSID]);
                    } else if (errorText.includes("No network with SSID")) {
                        root.showWarning(qsTr("Network not in range."), "error");
                    } else {
                        root.showWarning(qsTr("Connection failed: %1").arg(errorText), "error");
                    }
                    
                    console.warn("Network connection error:", errorText);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.connectionError = "";
                root.connectionFailed = false;
                root.failedSSID = "";
                root.showWarning(qsTr("Connected to %1").arg(root.lastConnectedSSID), "success");
                // Check for captive portal after successful connection
                captivePortalTimer.restart();
            }
            getNetworks.running = true;
        }
    }

    Process {
        id: forgetProc

        onExited: {
            getSavedConnections.running = true;
            getNetworks.running = true;
        }
    }

    Process {
        id: disconnectProc

        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: getNetworks

        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3]?.replace(rep2, ":") ?? "",
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] ?? ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                    }
                }

                const networks = Array.from(networkMap.values());

                const rNetworks = root.networks;

                const destroyed = rNetworks.filter(rn => !networks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of networks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
        readonly property bool isSaved: root.savedConnections.some(c => c.name === ssid)
    }

    component SavedConnection: QtObject {
        required property var lastIpcObject
        readonly property string name: lastIpcObject.name
        readonly property string uuid: lastIpcObject.uuid
        readonly property string type: lastIpcObject.type
        readonly property string device: lastIpcObject.device
        // Check if this saved network is currently in range
        readonly property bool inRange: root.networks.some(n => n.ssid === name)
        readonly property var accessPoint: root.networks.find(n => n.ssid === name) ?? null
    }

    Component {
        id: apComp

        AccessPoint {}
    }

    Component {
        id: savedComp

        SavedConnection {}
    }

    // Get saved WiFi connections
    Process {
        id: getSavedConnections

        running: true
        command: ["nmcli", "-g", "NAME,UUID,TYPE,DEVICE", "connection", "show"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allConnections = text.trim().split("\n").map(line => {
                    const parts = line.replace(rep, PLACEHOLDER).split(":");
                    return {
                        name: parts[0]?.replace(rep2, ":") ?? "",
                        uuid: parts[1] ?? "",
                        type: parts[2] ?? "",
                        device: parts[3] ?? ""
                    };
                }).filter(c => c.name && c.type === "802-11-wireless");

                const rSaved = root.savedConnections;

                const destroyed = rSaved.filter(rs => !allConnections.find(c => c.uuid === rs.uuid));
                for (const conn of destroyed)
                    rSaved.splice(rSaved.indexOf(conn), 1).forEach(c => c.destroy());

                for (const conn of allConnections) {
                    const match = rSaved.find(s => s.uuid === conn.uuid);
                    if (match) {
                        match.lastIpcObject = conn;
                    } else {
                        rSaved.push(savedComp.createObject(root, {
                            lastIpcObject: conn
                        }));
                    }
                }
            }
        }
    }
}
