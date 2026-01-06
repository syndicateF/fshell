pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Network Service - Pure D-Bus subscriber to x-network daemon
// NO network logic here! All operations delegated to daemon.
// This maintains the same API as the old Network.qml for UI compatibility.
Singleton {
    id: root

    //==========================================================================
    // PROPERTIES - All from daemon D-Bus (read-only bindings)
    //==========================================================================
    
    // Network list and active connection
    readonly property list<AccessPoint> networks: _networks
    readonly property list<SavedConnection> savedConnections: _savedConnections
    
    // Active network: When connected, create synthetic AccessPoint from D-Bus state
    readonly property AccessPoint active: _connectionState === "connected" && _activeSSID !== "" 
        ? _syntheticActive 
        : null
    
    // WiFi state (from daemon)
    property bool wifiEnabled: _wifiEnabled
    readonly property bool scanning: _wifiScanning
    readonly property bool connecting: _connectionState === "connecting"
    
    // Connection state (from daemon)
    readonly property bool connected: _connectionState === "connected"
    // Clear lastConnectedSSID when connection state changes (fixes stuck spinner)
    onConnectedChanged: lastConnectedSSID = ""
    readonly property string connectionState: _connectionState
    readonly property string activeSSID: _activeSSID
    readonly property string connectingSSID: _connectingSSID  // From daemon - which SSID is currently connecting
    
    // Traffic (from daemon - bytes per second)
    readonly property real downloadSpeed: _trafficIn
    readonly property real uploadSpeed: _trafficOut
    
    // Network info (from daemon)
    readonly property string ipAddress: _ipAddress
    readonly property string gateway: _gateway
    readonly property string macAddress: _macAddress
    readonly property string networkInterface: _interfaceName
    readonly property string connectionType: _connectionType
    readonly property string band: _band
    
    // Features (from daemon)
    property bool airplaneMode: _airplaneMode
    readonly property bool captivePortalDetected: _captivePortalDetected
    property bool hotspotActive: _hotspotActive
    
    // Signal strength
    readonly property int signalStrength: _signalStrength
    readonly property int signalRSSI: _signalRSSI
    
    // USB Tethering (from daemon)
    readonly property bool usbInterfaceDetected: _usbInterfaceDetected
    readonly property bool usbTetheringAvailable: _usbTetheringAvailable
    readonly property bool usbTetheringConnected: _usbTetheringConnected
    readonly property string usbInterfaceName: _usbInterfaceName
    
    //==========================================================================
    // UI-ONLY PROPERTIES (not from daemon - managed locally)
    //==========================================================================
    
    property string connectionError: ""
    property string lastConnectedSSID: ""
    property bool connectionFailed: false
    property string failedSSID: ""
    property string captivePortalUrl: ""
    property string warningMessage: ""
    property string warningType: "info"
    property var pendingNetworkFromBar: null
    property bool openPasswordDialogOnPanelOpen: false
    
    // Traffic ref counting (UI lifecycle, not network logic)
    property int trafficRefCount: 0
    
    // Hotspot state (used by startHotspot)
    property string hotspotSSID: ""
    property string hotspotPassword: ""
    
    //==========================================================================
    // INTERNAL STATE (updated by D-Bus)
    //==========================================================================
    
    property string _connectionState: "disconnected"
    property string _activeSSID: ""
    property string _connectingSSID: ""  // Set by daemon during connection attempt
    property bool _wifiEnabled: false
    property bool _wifiScanning: false
    property bool _airplaneMode: false
    property string _ipAddress: ""
    property string _gateway: ""
    property string _macAddress: ""
    property string _interfaceName: ""
    property string _connectionType: ""
    property string _band: ""
    property int _frequency: 0
    property int _trafficIn: 0
    property int _trafficOut: 0
    property bool _captivePortalDetected: false
    property bool _hotspotActive: false
    property int _signalStrength: 0
    property int _signalRSSI: 0
    // USB Tethering internal state
    property bool _usbInterfaceDetected: false
    property bool _usbTetheringAvailable: false
    property bool _usbTetheringConnected: false
    property string _usbInterfaceName: ""
    // Network data cache
    property var _networksData: []
    property list<AccessPoint> _networks: []
    property list<SavedConnection> _savedConnections: []
    
    //==========================================================================
    // HELPER FUNCTIONS (pure UI, no network logic)
    //==========================================================================
    
    function isSavedNetworkInRange(ssid) {
        return networks.some(n => n.ssid === ssid);
    }
    
    function getSavedNetworkAccessPoint(ssid) {
        return networks.find(n => n.ssid === ssid) ?? null;
    }
    
    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
        } else if (bytesPerSec >= 1024) {
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        } else {
            return bytesPerSec.toFixed(0) + " B/s"
        }
    }
    
    function speedOpacity(bytesPerSec) {
        const maxSpeed = 1024 * 1024
        const ratio = Math.min(bytesPerSec / maxSpeed, 1.0)
        return 0.3 + (ratio * 0.7)
    }
    
    function showWarning(message, type) {
        root.warningMessage = message;
        root.warningType = type || "info";
        warningTimer.restart();
    }
    
    function clearWarning() {
        root.warningMessage = "";
    }
    
    //==========================================================================
    // PUBLIC METHODS - Delegate to daemon via D-Bus
    //==========================================================================
    
    function enableWifi(enabled) {
        _callDaemon("EnableWifi", ["b", enabled ? "true" : "false"]);
    }
    
    function toggleWifi() {
        enableWifi(!wifiEnabled);
    }
    
    function rescanWifi() {
        _callDaemon("Scan", []);
    }
    
    function connectToNetwork(ssid, password, isSaved) {
        root.connectionError = "";
        root.connectionFailed = false;
        root.lastConnectedSSID = ssid;
        
        if (password && password.length > 0) {
            _callDaemonConnect(ssid, password, "psk", false);
        } else if (isSaved) {
            _callDaemon("ConnectSaved", ["s", ssid]);
        } else {
            _callDaemonConnect(ssid, "", "open", false);
        }
    }
    
    function connectToNewNetwork(ssid, password) {
        connectToNetwork(ssid, password, false);
    }
    
    function connectWithSecurity(ssid, password, securityType) {
        root.connectionError = "";
        root.connectionFailed = false;
        root.lastConnectedSSID = ssid;
        _callDaemonConnect(ssid, password, securityType, false);
    }
    
    function connectToHiddenNetwork(ssid, password, security) {
        root.connectionError = "";
        root.connectionFailed = false;
        root.lastConnectedSSID = ssid;
        _callDaemonConnect(ssid, password, security || "psk", true);
    }
    
    function forgetNetwork(ssid) {
        // Update savedConnections immediately - isSaved is COMPUTED from this list
        // (See AccessPoint delegate: "readonly property bool isSaved: savedConnections.some(...)")
        _savedConnections = _savedConnections.filter(function(c) { return c.name !== ssid; });
        
        _callDaemon("Forget", ["s", ssid]);
    }
    
    function disconnectFromNetwork() {
        _callDaemon("Disconnect", []);
    }
    
    function toggleAirplaneMode() {
        _callDaemon("SetAirplaneMode", ["b", !airplaneMode ? "true" : "false"]);
    }
    
    function startHotspot(ssid, password) {
        root.hotspotSSID = ssid;
        root.hotspotPassword = password;
        _callDaemon("StartHotspot", ["ss", ssid, password]);
    }
    
    function stopHotspot() {
        _callDaemon("StopHotspot", []);
    }
    
    function setAutoConnect(ssid, enabled) {
        _callDaemon("SetAutoConnect", ["sb", ssid, enabled ? "true" : "false"]);
    }
    
    function checkCaptivePortal() {
        _callDaemon("CheckCaptivePortal", []);
    }
    
    function openCaptivePortal() {
        _callDaemon("OpenCaptivePortal", []);
    }
    
    function reconnect() {
        if (active) {
            disconnectFromNetwork();
            Qt.callLater(() => connectToNetwork(active.ssid, "", true));
        }
    }
    
    // USB Tethering methods (honest semantics - PC doesn't control phone)
    function requestUsbNetwork() {
        _callDaemon("RequestUsbNetwork", []);
    }
    
    function releaseUsbNetwork() {
        _callDaemon("ReleaseUsbNetwork", []);
    }
    
    // Open network settings (legacy compatibility - still useful)
    function openNetworkSettings() { settingsProc.running = true; }
    
    //==========================================================================
    // D-BUS COMMUNICATION (internal)
    //==========================================================================
    
    // Refresh all properties from daemon
    function _refreshProperties() {
        propReader.running = true;
    }
    
    // Call daemon method
    function _callDaemon(method, args) {
        const cmd = ["busctl", "--user", "call",
                     "org.xshell.Network", "/org/xshell/Network",
                     "org.xshell.Network", method, ...args];
        methodCaller.command = cmd;
        methodCaller.running = true;
    }
    
    // Connect with dict (a{sv}) parameters
    function _callDaemonConnect(ssid, password, security, hidden) {
        // Build a{sv} dict for Connect method
        // Note: busctl syntax for dict is: count + key type value pairs
        let entries = 3;
        const args = ["a{sv}", "4",
            "ssid", "s", ssid,
            "password", "s", password || "",
            "security", "s", security || "psk",
            "hidden", "b", hidden ? "true" : "false"
        ];
        const cmd = ["busctl", "--user", "call",
                     "org.xshell.Network", "/org/xshell/Network",
                     "org.xshell.Network", "Connect", ...args];
        methodCaller.command = cmd;
        methodCaller.running = true;
    }
    
    // Parse D-Bus property value
    function _updateProperty(name, value) {
        switch (name) {
            case "ConnectionState": _connectionState = value; break;
            case "ActiveSSID": _activeSSID = value; break;
            case "ConnectingSSID": _connectingSSID = value; break;
            case "WifiEnabled": _wifiEnabled = value; break;
            case "WifiScanning": _wifiScanning = value; break;
            case "AirplaneMode": _airplaneMode = value; break;
            case "IpAddress": _ipAddress = value; break;
            case "Gateway": _gateway = value; break;
            case "MacAddress": _macAddress = value; break;
            case "InterfaceName": _interfaceName = value; break;
            case "ConnectionType": _connectionType = value; break;
            case "Band": _band = value; break;
            case "Frequency": _frequency = value; break;
            case "TrafficIn": _trafficIn = value; break;
            case "TrafficOut": _trafficOut = value; break;
            case "CaptivePortalDetected": _captivePortalDetected = value; break;
            case "HotspotActive": _hotspotActive = value; break;
            case "SignalStrength": _signalStrength = value; break;
            case "SignalRSSI": _signalRSSI = value; break;
            case "ActiveSecurity": _activeSecurity = value; break;
            case "SavedNetworks": _updateSavedConnections(value); break;
            case "Networks": _updateNetworksList(value); break;
            // USB Tethering properties
            case "UsbInterfaceDetected": _usbInterfaceDetected = value; break;
            case "UsbTetheringAvailable": _usbTetheringAvailable = value; break;
            case "UsbTetheringConnected": _usbTetheringConnected = value; break;
            case "UsbInterfaceName": _usbInterfaceName = value; break;
            // Error feedback
            case "LastError":
                if (value && value.length > 0) {
                    root.connectionError = value;
                    root.connectionFailed = true;
                    root.failedSSID = root.lastConnectedSSID;
                    root.showWarning(qsTr("Connection failed: %1").arg(value), "error");
                }
                break;
        }
    }
    
    // Update saved connections from D-Bus array of SSIDs
    // IMPORTANT: Compare before rebuilding to avoid constant re-render
    property var _savedDataCache: []
    function _updateSavedConnections(ssidList) {
        if (!Array.isArray(ssidList)) return;
        
        // Compare with current data - skip rebuild if unchanged
        const newDataStr = JSON.stringify(ssidList);
        const currentDataStr = JSON.stringify(_savedDataCache);
        
        if (newDataStr === currentDataStr) {
            return; // Data unchanged - DO NOT rebuild!
        }
        
        // Store new data for future comparison
        _savedDataCache = ssidList;
        
        // Clear and rebuild only when data actually changed
        while (_savedConnections.length > 0) {
            _savedConnections.pop().destroy?.();
        }
        
        for (const ssid of ssidList) {
            const saved = savedComp.createObject(root, {
                lastIpcObject: {
                    name: ssid,
                    uuid: "",
                    type: "802-11-wireless",
                    device: ""
                }
            });
            _savedConnections.push(saved);
        }
    }
    
    // Update networks list from D-Bus array
    // IMPORTANT: Compare before rebuilding to avoid constant re-render
    function _updateNetworksList(networkData) {
        if (!Array.isArray(networkData)) return;
        
        // Compare with current data - skip rebuild if unchanged
        const newDataStr = JSON.stringify(networkData);
        const currentDataStr = JSON.stringify(_networksData);
        
        if (newDataStr === currentDataStr) {
            return; // Data unchanged - DO NOT rebuild!
        }
        
        // Store new data for future comparison
        _networksData = networkData;
        
        // Clear and rebuild only when data actually changed
        while (_networks.length > 0) {
            _networks.pop().destroy?.();
        }
        
        for (const net of networkData) {
            // net is [ssid, security, strength, active, frequency]
            const ap = apComp.createObject(root, {
                lastIpcObject: {
                    ssid: net[0] || "",
                    security: net[1] || "",
                    strength: net[2] || 0,
                    active: net[3] || false,
                    frequency: net[4] || 0,
                    bssid: ""
                }
            });
            _networks.push(ap);
        }
    }
    
    //==========================================================================
    // D-BUS PROPERTY READER
    //==========================================================================
    
    Process {
        id: propReader
        command: ["busctl", "--user", "-j", "call", 
                  "org.xshell.Network", "/org/xshell/Network",
                  "org.freedesktop.DBus.Properties", "GetAll",
                  "s", "org.xshell.Network"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                try {
                    const result = JSON.parse(text);
                    if (result.data && result.data[0]) {
                        for (const [key, val] of Object.entries(result.data[0])) {
                            root._updateProperty(key, val.data);
                        }
                    }
                } catch (e) {
                    // Daemon may not be running - ignore
                }
            }
        }
    }
    
    // Method caller (reusable)
    Process {
        id: methodCaller
        // No need to refresh here - D-Bus signals from daemon will trigger refresh via signalListener
        stdout: StdioCollector {
            onStreamFinished: {
                // Method completed - signals will handle state update
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0 && !text.includes("NoReply")) {
                    root.connectionError = text.trim();
                    root.connectionFailed = true;
                    root.failedSSID = root.lastConnectedSSID;
                    root.showWarning(qsTr("Connection failed: %1").arg(text.trim()), "error");
                }
            }
        }
        onExited: (code) => {
            if (code === 0 && root.lastConnectedSSID) {
                root.connectionError = "";
                root.connectionFailed = false;
            }
        }
    }
    
    // Open settings (legacy compatibility)
    Process {
        id: settingsProc
        command: ["sh", "-c", "command -v nm-connection-editor && nm-connection-editor || gnome-control-center network"]
    }
    //==========================================================================
    // D-BUS SIGNAL LISTENER (event-driven, refetch on signal)
    //==========================================================================
    
    // Listen for D-Bus PropertyChanged signals from daemon
    // Using gdbus monitor which is more reliable than busctl monitor
    Process {
        id: signalListener
        running: true
        command: ["gdbus", "monitor", "--session", "--dest", "org.xshell.Network", 
                  "--object-path", "/org/xshell/Network"]
        
        stdout: SplitParser {
            onRead: (data) => {
                // gdbus outputs "PropertiesChanged" for property changes
                if (!data.includes("PropertiesChanged")) {
                    return;
                }
                
                // Skip traffic-only signals (contain TrafficIn/Out but not other important props)
                const isTrafficOnly = data.includes("TrafficIn") && data.includes("TrafficOut")
                    && !data.includes("WifiScanning") && !data.includes("SavedNetworks")
                    && !data.includes("ConnectionState") && !data.includes("Networks")
                    && !data.includes("LastError") && !data.includes("ActiveSSID");
                
                if (isTrafficOnly) {
                    return; // Don't refresh for traffic-only updates
                }
                
                // Trigger property refetch - backend has all the data
                if (!propReader.running) {
                    propReader.running = true;
                }
            }
        }
    }
    
    // Warning auto-clear
    Timer {
        id: warningTimer
        interval: 5000
        onTriggered: root.warningMessage = ""
    }
    
    //==========================================================================
    // ACCESS POINT COMPONENT (maintains old API)
    //==========================================================================
    
    component AccessPoint: QtObject {
        property var lastIpcObject: ({})
        readonly property string ssid: lastIpcObject.ssid ?? ""
        readonly property string bssid: lastIpcObject.bssid ?? ""
        readonly property int strength: lastIpcObject.strength ?? 0
        readonly property int frequency: lastIpcObject.frequency ?? 0
        readonly property bool active: lastIpcObject.active ?? false
        readonly property string security: lastIpcObject.security ?? ""
        readonly property bool isSecure: security.length > 0
        readonly property bool isSaved: root.savedConnections.some(c => c.name === ssid)
        readonly property bool is5GHz: frequency > 5000
    }
    
    component SavedConnection: QtObject {
        property var lastIpcObject: ({})
        readonly property string name: lastIpcObject.name ?? ""
        readonly property string uuid: lastIpcObject.uuid ?? ""
        readonly property string type: lastIpcObject.type ?? ""
        readonly property string device: lastIpcObject.device ?? ""
        readonly property bool inRange: root.networks.some(n => n.ssid === name)
        readonly property var accessPoint: root.networks.find(n => n.ssid === name) ?? null
    }
    
    // Synthetic active AccessPoint - uses D-Bus state directly
    AccessPoint {
        id: _syntheticActive
        lastIpcObject: ({
            ssid: root._activeSSID,
            bssid: "",
            strength: root._signalStrength,
            frequency: root._frequency,
            active: true,
            security: root._activeSecurity
        })
    }
    
    // Track activeSecurity from D-Bus
    property string _activeSecurity: ""
    
    Component { id: apComp; AccessPoint {} }
    Component { id: savedComp; SavedConnection {} }
    
    //==========================================================================
    // INITIALIZATION
    //==========================================================================
    
    Component.onCompleted: {
        propReader.running = true;
    }
}