import Quickshell.Bluetooth
import qs.services
import QtQuick

QtObject {
    readonly property list<string> panes: ["network", "bluetooth", "monitor", "hardware"]

    required property var root
    property bool floating: false
    property string active: panes[0]
    property int activeIndex: 0
    property bool navExpanded: false

    readonly property Bt bt: Bt {}
    readonly property Nw nw: Nw {}
    readonly property Mon mon: Mon {}
    readonly property Hw hw: Hw {}

    onActiveChanged: activeIndex = panes.indexOf(active)
    onActiveIndexChanged: active = panes[activeIndex]

    component Bt: QtObject {
        property BluetoothDevice active
        property BluetoothAdapter currentAdapter: Bluetooth.defaultAdapter
        property bool editingAdapterName
        property bool fabMenuOpen
        property bool editingDeviceName
    }

    component Nw: QtObject {
        property var active: null  // Currently selected AccessPoint
        property var pendingNetwork: null  // Network waiting for password
        property bool fabMenuOpen: false
        property bool connectDialogOpen: false
        property string pendingPassword: ""
        property bool forgetDialogOpen: false
        property var networkToForget: null  // Network to be forgotten (needs confirmation)
        property bool showingWarning: false
        property bool hiddenNetworkDialogOpen: false
        property bool hotspotDialogOpen: false
    }

    component Mon: QtObject {
        property bool fabMenuOpen: false
    }

    component Hw: QtObject {
        property string view: "cpu"  // "cpu", "gpu", "battery", "gpumode", "profiles", "rgb"
        property bool fabMenuOpen: false
    }
}
