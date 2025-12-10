pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running

    // Network traffic monitoring
    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0    // bytes per second
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property string networkInterface: ""
    
    // Format bytes to human readable
    function formatSpeed(bytesPerSec: real): string {
        if (bytesPerSec >= 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
        } else if (bytesPerSec >= 1024) {
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        } else {
            return bytesPerSec.toFixed(0) + " B/s"
        }
    }
    
    // Opacity based on speed (faster = more opaque)
    function speedOpacity(bytesPerSec: real): real {
        // Min opacity 0.3, max 1.0
        // Scale: 0 B/s = 0.3, 1+ MB/s = 1.0
        const maxSpeed = 1024 * 1024 // 1 MB/s as "full speed"
        const ratio = Math.min(bytesPerSec / maxSpeed, 1.0)
        return 0.3 + (ratio * 0.7)
    }

    function enableWifi(enabled: bool): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        const cmd = wifiEnabled ? "off" : "on";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function rescanWifi(): void {
        rescanProc.running = true;
    }

    function connectToNetwork(ssid: string, password: string): void {
        // TODO: Implement password
        connectProc.exec(["nmcli", "conn", "up", ssid]);
    }

    function disconnectFromNetwork(): void {
        if (active) {
            disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
        }
    }

    function getWifiStatus(): void {
        wifiStatusProc.running = true;
    }

    // Network traffic monitoring timer
    Timer {
        id: trafficTimer
        interval: 1000  // Update every second
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            getInterfaceProc.running = true
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
    
    // Read network traffic from /proc/net/dev
    FileView {
        id: trafficStats
        path: "/proc/net/dev"
        onLoaded: {
            if (!root.networkInterface) return
            
            const lines = text().split("\n")
            for (const line of lines) {
                if (line.includes(root.networkInterface + ":")) {
                    // Format: Interface: rx_bytes rx_packets ... tx_bytes tx_packets ...
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
            onRead: getNetworks.running = true
        }
        stderr: StdioCollector {
            onStreamFinished: console.warn("Network connection error:", text)
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
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
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
    }

    Component {
        id: apComp

        AccessPoint {}
    }
}
