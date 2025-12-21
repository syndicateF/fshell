pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Bluetooth popout - Feature Rich iOS Sheet style
ColumnLayout {
    id: root

    required property Item wrapper

    // Computed properties
    readonly property var allDevices: [...Bluetooth.devices.values]
    readonly property var connectedDevices: allDevices.filter(d => d.connected)
    readonly property var pairedDevices: allDevices.filter(d => d.bonded && !d.connected)
    readonly property var availableDevices: allDevices.filter(d => !d.bonded && !d.connected)
    readonly property bool isEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool isDiscovering: Bluetooth.defaultAdapter?.discovering ?? false

    // Error state
    property string errorMessage: ""
    property bool hasError: errorMessage !== ""

    function showError(msg: string): void {
        errorMessage = msg;
        errorTimer.restart();
    }

    Timer {
        id: errorTimer
        interval: 5000
        onTriggered: root.errorMessage = ""
    }

    spacing: Appearance.spacing.small

    // ═══════════════════════════════════════════════════
    // Error Toast - animated show/hide
    // ═══════════════════════════════════════════════════
    StyledRect {
        visible: opacity > 0  // Stay visible during fade out animation
        Layout.fillWidth: true
        implicitHeight: errorContent.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3errorContainer

        opacity: root.hasError ? 1 : 0
        scale: root.hasError ? 1 : 0.9

        Behavior on opacity { Anim {} }
        Behavior on scale { Anim {} }

        RowLayout {
            id: errorContent
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: "error"
                color: Colours.palette.m3onErrorContainer
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                text: root.errorMessage
                color: Colours.palette.m3onErrorContainer
                font.pointSize: Appearance.font.size.small
                wrapMode: Text.WordWrap
                Layout.maximumWidth: 200
            }

            Item {
                implicitWidth: 20
                implicitHeight: 20

                StateLayer {
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3onErrorContainer

                    function onClicked(): void {
                        root.errorMessage = "";
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onErrorContainer
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // iOS Drag Handle (clickable to open panel)
    // ═══════════════════════════════════════════════════
    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 48
        implicitHeight: 20

        Rectangle {
            anchors.centerIn: parent
            width: 36
            height: 4
            radius: 2
            color: Colours.palette.m3outlineVariant
        }

        StateLayer {
            radius: Appearance.rounding.small

            function onClicked(): void {
                root.wrapper.detach("bluetooth");
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Status Card
    // ═══════════════════════════════════════════════════
    StyledRect {
        Layout.fillWidth: true
        implicitWidth: 280
        implicitHeight: statusContent.height + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainerHigh

        ColumnLayout {
            id: statusContent
            width: parent.width - Appearance.padding.normal * 2
            x: Appearance.padding.normal
            y: Appearance.padding.normal
            spacing: Appearance.spacing.small

            // Header row
            RowLayout {
                width: parent.width  // Fill parent width so switch goes to right edge
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "bluetooth"
                    color: root.isEnabled ? Colours.palette.m3primary : Colours.palette.m3outline
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: qsTr("Bluetooth")
                        font.weight: 600
                    }

                    StyledText {
                        visible: root.isEnabled
                        text: {
                            const conn = root.connectedDevices.length;
                            const paired = root.pairedDevices.length;
                            if (conn > 0 && paired > 0)
                                return qsTr("%1 connected • %2 paired").arg(conn).arg(paired);
                            if (conn > 0)
                                return qsTr("%1 connected").arg(conn);
                            if (paired > 0)
                                return qsTr("%1 paired").arg(paired);
                            return qsTr("No devices");
                        }
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                    }
                }

                // Spacer to push switch to right
                Item { Layout.fillWidth: true }

                StyledSwitch {
                    checked: root.isEnabled
                    onClicked: {
                        const adapter = Bluetooth.defaultAdapter;
                        if (adapter)
                            adapter.enabled = checked;
                    }
                }
            }

            // Status badges row - animated height
            // Only show when there's at least one badge visible
            Item {
                readonly property bool hasBadges: root.isDiscovering || (Bluetooth.defaultAdapter?.discoverable ?? false)

                Layout.fillWidth: true
                implicitHeight: (root.isEnabled && hasBadges) ? badgesContent.implicitHeight : 0
                clip: true

                Behavior on implicitHeight {
                    Anim {}
                }

                RowLayout {
                    id: badgesContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    opacity: (root.isEnabled && parent.hasBadges) ? 1 : 0
                    scale: (root.isEnabled && parent.hasBadges) ? 1 : 0.8

                    Behavior on opacity { Anim {} }
                    Behavior on scale { Anim {} }

                    // Scanning badge - animated width
                    Item {
                        implicitWidth: root.isDiscovering ? scanBadge.implicitWidth : 0
                        implicitHeight: scanBadge.implicitHeight
                        clip: true

                        Behavior on implicitWidth { Anim {} }

                        StyledRect {
                            id: scanBadge
                            implicitWidth: scanLabel.implicitWidth + Appearance.padding.normal * 2
                            implicitHeight: scanLabel.implicitHeight + Appearance.padding.normal
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3tertiaryContainer

                            opacity: root.isDiscovering ? 1 : 0
                            scale: root.isDiscovering ? 1 : 0.8

                            Behavior on opacity { Anim {} }
                            Behavior on scale { Anim {} }

                            RowLayout {
                                id: scanLabel
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.smaller

                                MaterialIcon {
                                    text: "radar"
                                    font.pointSize: Appearance.font.size.smaller
                                    color: Colours.palette.m3onTertiaryContainer
                                }

                                StyledText {
                                    text: qsTr("Scanning")
                                    font.pointSize: Appearance.font.size.smaller
                                    color: Colours.palette.m3onTertiaryContainer
                                }
                            }
                        }
                    }

                    // Discoverable badge - animated width
                    Item {
                        readonly property bool shouldShow: Bluetooth.defaultAdapter?.discoverable ?? false

                        implicitWidth: shouldShow ? discBadge.implicitWidth : 0
                        implicitHeight: discBadge.implicitHeight
                        clip: true

                        Behavior on implicitWidth { Anim {} }

                        StyledRect {
                            id: discBadge
                            implicitWidth: discLabel.implicitWidth + Appearance.padding.normal * 2
                            implicitHeight: discLabel.implicitHeight + Appearance.padding.small
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3secondaryContainer

                            opacity: parent.shouldShow ? 1 : 0
                            scale: parent.shouldShow ? 1 : 0.8

                            Behavior on opacity { Anim {} }
                            Behavior on scale { Anim {} }

                            RowLayout {
                                id: discLabel
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.smaller

                                MaterialIcon {
                                    text: "visibility"
                                    font.pointSize: Appearance.font.size.smaller
                                    color: Colours.palette.m3onSecondaryContainer
                                }

                                StyledText {
                                    text: qsTr("Visible")
                                    font.pointSize: Appearance.font.size.smaller
                                    color: Colours.palette.m3onSecondaryContainer
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Quick Actions
    // ═══════════════════════════════════════════════════
    RowLayout {
        visible: root.isEnabled
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        // Scan button
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: Appearance.rounding.small
            color: root.isDiscovering ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerHigh

            StateLayer {
                color: root.isDiscovering ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface

                function onClicked(): void {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.discovering = !adapter.discovering;
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.smaller

                MaterialIcon {
                    text: "radar"
                    font.pointSize: Appearance.font.size.small
                    color: root.isDiscovering ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    text: root.isDiscovering ? qsTr("Stop") : qsTr("Scan")
                    font.pointSize: Appearance.font.size.small
                    color: root.isDiscovering ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Pair button (opens panel)
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: Appearance.rounding.small
            color: Colours.palette.m3surfaceContainerHigh

            StateLayer {
                color: Colours.palette.m3onSurface

                function onClicked(): void {
                    root.wrapper.detach("bluetooth");
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.smaller

                MaterialIcon {
                    text: "add"
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    text: qsTr("Pair")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Connected Section
    // ═══════════════════════════════════════════════════
    RowLayout {
        visible: root.isEnabled && root.connectedDevices.length > 0
        spacing: Appearance.spacing.small

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        StyledText {
            text: qsTr("Connected")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3primary
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }
    }

    // Connected devices card
    StyledRect {
        visible: root.isEnabled && root.connectedDevices.length > 0
        Layout.fillWidth: true
        implicitWidth: 280
        implicitHeight: connectedList.height + Appearance.padding.small * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainerHigh  // Same as other cards, no special color
        // No border - same as other sections

        Column {
            id: connectedList
            width: parent.width - Appearance.padding.smaller * 2
            x: Appearance.padding.smaller
            y: Appearance.padding.small
            spacing: 2

            Repeater {
                model: ScriptModel {
                    values: root.connectedDevices.slice(0, 3)
                }

                ConnectedDeviceRow {
                    required property BluetoothDevice modelData
                    width: parent.width
                    device: modelData
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Paired Section
    // ═══════════════════════════════════════════════════
    RowLayout {
        visible: root.isEnabled && root.pairedDevices.length > 0
        spacing: Appearance.spacing.small

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        StyledText {
            text: qsTr("Paired")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3outline
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }
    }

    // Paired devices card
    StyledRect {
        visible: root.isEnabled && root.pairedDevices.length > 0
        Layout.fillWidth: true
        implicitWidth: 280
        implicitHeight: pairedList.height + Appearance.padding.small * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainerHigh

        Column {
            id: pairedList
            width: parent.width - Appearance.padding.smaller * 2
            x: Appearance.padding.smaller
            y: Appearance.padding.small
            spacing: 2

            Repeater {
                model: ScriptModel {
                    values: root.pairedDevices.slice(0, 3)
                }

                DeviceRow {
                    required property BluetoothDevice modelData
                    width: parent.width
                    device: modelData
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Available Section (when scanning) - animated height
    // ═══════════════════════════════════════════════════
    Item {
        readonly property bool shouldShow: root.isEnabled && root.isDiscovering && root.availableDevices.length > 0

        Layout.fillWidth: true
        implicitHeight: shouldShow ? availableContent.implicitHeight : 0
        clip: true

        Behavior on implicitHeight { Anim {} }

        ColumnLayout {
            id: availableContent
            width: parent.width
            spacing: Appearance.spacing.small

            opacity: parent.shouldShow ? 1 : 0
            scale: parent.shouldShow ? 1 : 0.95

            Behavior on opacity { Anim {} }
            Behavior on scale { Anim {} }

            // Section header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colours.palette.m3outlineVariant
                }

                StyledText {
                    text: qsTr("Available")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3tertiary
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colours.palette.m3outlineVariant
                }
            }

            // Available devices card
            StyledRect {
                Layout.fillWidth: true
                implicitWidth: 280
                implicitHeight: availableList.height + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: Colours.palette.m3surfaceContainerHigh

                Column {
                    id: availableList
                    width: parent.width - Appearance.padding.smaller * 2
                    x: Appearance.padding.smaller
                    y: Appearance.padding.small
                    spacing: 2

                    Repeater {
                        model: ScriptModel {
                            values: root.availableDevices.slice(0, 3)
                        }

                        AvailableDeviceRow {
                            required property BluetoothDevice modelData
                            width: parent.width
                            device: modelData
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    // INLINE COMPONENTS
    // ═══════════════════════════════════════════════════════

    // Connected device row (special styling with battery)
    component ConnectedDeviceRow: Item {
        id: connRow

        required property BluetoothDevice device
        readonly property bool loading: device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting

        implicitHeight: 48

        // Entry animation
        opacity: 0
        scale: 0.9
        Component.onCompleted: { opacity = 1; scale = 1; }
        Behavior on opacity { Anim {} }
        Behavior on scale { Anim {} }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.normal

            // Device icon in container
            StyledRect {
                implicitWidth: 36
                implicitHeight: 36
                radius: Appearance.rounding.small
                color: Colours.palette.m3primaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: Icons.getBluetoothIcon(connRow.device.icon)
                    color: Colours.palette.m3onPrimaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: connRow.device.name
                    font.weight: 600
                    color: Colours.palette.m3onSurface  // Same as other sections
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    visible: connRow.device.battery >= 0

                    MaterialIcon {
                        text: "battery_full"
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                    }

                    StyledText {
                        text: connRow.device.battery + "%"
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                    }
                }
            }

            // Disconnect button
            StyledRect {
                implicitWidth: 28
                implicitHeight: 28
                radius: Appearance.rounding.full
                color: Colours.palette.m3primary

                CircularIndicator {
                    anchors.fill: parent
                    running: connRow.loading
                }

                StateLayer {
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3onPrimary
                    disabled: connRow.loading

                    function onClicked(): void {
                        connRow.device.connected = false;
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "link_off"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onPrimary
                    opacity: connRow.loading ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }

    // Paired device row
    component DeviceRow: Item {
        id: row

        required property BluetoothDevice device
        readonly property bool loading: device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting

        // Track if we initiated a connection
        property bool wasConnecting: false

        implicitHeight: 40

        // Detect connection failure
        Connections {
            target: row.device

            function onStateChanged(): void {
                if (row.wasConnecting && row.device.state === BluetoothDeviceState.Disconnected) {
                    // Was connecting but now disconnected = failed
                    root.showError(qsTr("Failed to connect to %1").arg(row.device.name));
                    row.wasConnecting = false;
                } else if (row.device.state === BluetoothDeviceState.Connected) {
                    row.wasConnecting = false;
                }
            }
        }

        // Entry animation
        opacity: 0
        scale: 0.9
        Component.onCompleted: { opacity = 1; scale = 1; }
        Behavior on opacity { Anim {} }
        Behavior on scale { Anim {} }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: Icons.getBluetoothIcon(row.device.icon)
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                text: row.device.name
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            // Delete button - subtle style
            Item {
                implicitWidth: 24
                implicitHeight: 24

                StateLayer {
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3onSurfaceVariant  // Subtle, not red

                    function onClicked(): void {
                        row.device.forget();
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "delete"
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3outline  // Muted, not red
                }
            }

            // Connect button
            StyledRect {
                implicitWidth: 24
                implicitHeight: 24
                radius: Appearance.rounding.full
                color: "transparent"
                border.width: 1
                border.color: Colours.palette.m3outline

                CircularIndicator {
                    anchors.fill: parent
                    running: row.loading
                }

                StateLayer {
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3onSurface
                    disabled: row.loading

                    function onClicked(): void {
                        row.wasConnecting = true;
                        row.device.connected = true;
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "link"
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3outline
                    opacity: row.loading ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }

    // Available device row (not paired yet)
    component AvailableDeviceRow: Item {
        id: availRow

        required property BluetoothDevice device
        readonly property bool loading: device.state === BluetoothDeviceState.Connecting

        // Track if we initiated a connection
        property bool wasConnecting: false

        implicitHeight: 36

        // Detect connection failure
        Connections {
            target: availRow.device

            function onStateChanged(): void {
                if (availRow.wasConnecting && availRow.device.state === BluetoothDeviceState.Disconnected) {
                    root.showError(qsTr("Failed to pair with %1").arg(availRow.device.name));
                    availRow.wasConnecting = false;
                } else if (availRow.device.state === BluetoothDeviceState.Connected) {
                    availRow.wasConnecting = false;
                }
            }
        }

        // Entry animation
        opacity: 0
        scale: 0.9
        Component.onCompleted: { opacity = 1; scale = 1; }
        Behavior on opacity { Anim {} }
        Behavior on scale { Anim {} }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: Icons.getBluetoothIcon(availRow.device.icon)
                color: Colours.palette.m3onSurfaceVariant
                opacity: 0.7
            }

            StyledText {
                Layout.fillWidth: true
                text: availRow.device.name
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }

            // Pair button
            StyledRect {
                implicitWidth: 24
                implicitHeight: 24
                radius: Appearance.rounding.full
                color: "transparent"
                border.width: 1
                border.color: Colours.palette.m3tertiary

                CircularIndicator {
                    anchors.fill: parent
                    running: availRow.loading
                }

                StateLayer {
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3tertiary
                    disabled: availRow.loading

                    function onClicked(): void {
                        availRow.wasConnecting = true;
                        availRow.device.connected = true;
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "add"
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3tertiary
                    opacity: availRow.loading ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
