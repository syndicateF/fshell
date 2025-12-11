pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property var network: session.nw.active
    readonly property bool isSaved: network?.isSaved ?? false
    readonly property bool isConnecting: Network.connecting && Network.lastConnectedSSID === (network?.ssid ?? "")

    StyledFlickable {
        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: layout.height

        ColumnLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: getWifiIcon(root.network?.strength ?? 0)
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true

                function getWifiIcon(strength: int): string {
                    if (strength >= 80) return "signal_wifi_4_bar";
                    if (strength >= 60) return "network_wifi_3_bar";
                    if (strength >= 40) return "network_wifi_2_bar";
                    if (strength >= 20) return "network_wifi_1_bar";
                    return "signal_wifi_0_bar";
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacing.small

                StyledText {
                    animate: true
                    text: root.network?.ssid ?? ""
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                }

                MaterialIcon {
                    visible: root.isSaved
                    text: "bookmark"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.large
                }

                MaterialIcon {
                    visible: root.network?.isSecure ?? false
                    text: "lock"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.large
                }
            }

            // Quick connect/disconnect buttons
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.normal
                spacing: Appearance.spacing.normal

                // Connect/Disconnect button
                StyledRect {
                    implicitWidth: connectBtnContent.implicitWidth + Appearance.padding.large * 2
                    implicitHeight: connectBtnContent.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.full
                    color: root.network?.active ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer

                    CircularIndicator {
                        anchors.fill: parent
                        running: root.isConnecting
                    }

                    StateLayer {
                        color: root.network?.active ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                        disabled: root.isConnecting

                        function onClicked(): void {
                            if (root.network?.active) {
                                Network.disconnectFromNetwork();
                            } else if (root.isSaved) {
                                // Saved network
                                Network.connectToNetwork(root.network.ssid, "", true);
                            } else if (root.network?.isSecure) {
                                // New secured network - need password
                                root.session.nw.pendingNetwork = root.network;
                                root.session.nw.connectDialogOpen = true;
                            } else {
                                // Open network (not saved)
                                Network.connectToNetwork(root.network.ssid, "", false);
                            }
                        }
                    }

                    RowLayout {
                        id: connectBtnContent
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small
                        opacity: root.isConnecting ? 0 : 1

                        Behavior on opacity {
                            Anim {}
                        }

                        MaterialIcon {
                            text: root.network?.active ? "link_off" : root.network?.isSecure && !root.isSaved ? "key" : "link"
                            color: root.network?.active ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                        }

                        StyledText {
                            text: root.isConnecting ? qsTr("Connecting...") : root.network?.active ? qsTr("Disconnect") : qsTr("Connect")
                            color: root.network?.active ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                        }
                    }
                }

                // Forget button (only for saved networks) - now opens confirmation dialog
                StyledRect {
                    visible: root.isSaved
                    implicitWidth: forgetBtnContent.implicitWidth + Appearance.padding.large * 2
                    implicitHeight: forgetBtnContent.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    StateLayer {
                        color: Colours.palette.m3onSecondaryContainer

                        function onClicked(): void {
                            // Open confirmation dialog instead of direct forget
                            root.session.nw.networkToForget = root.network;
                            root.session.nw.forgetDialogOpen = true;
                        }
                    }

                    RowLayout {
                        id: forgetBtnContent
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: "delete"
                            color: Colours.palette.m3onSecondaryContainer
                        }

                        StyledText {
                            text: qsTr("Forget")
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Connection status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Current connection state")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: networkStatus.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: networkStatus

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: statusIcon.implicitHeight + Appearance.padding.normal * 2

                            radius: Appearance.rounding.normal
                            color: root.network?.active ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                            MaterialIcon {
                                id: statusIcon

                                anchors.centerIn: parent
                                text: root.network?.active ? "wifi" : "wifi_off"
                                color: root.network?.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.large
                                fill: root.network?.active ? 1 : 0

                                Behavior on fill {
                                    Anim {}
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: root.network?.active ? qsTr("Connected") : root.isSaved ? qsTr("Saved - Not connected") : qsTr("Not connected")
                                font.weight: 500
                            }

                            StyledText {
                                text: root.network?.active ? qsTr("You are connected to this network") : root.isSaved ? qsTr("Tap Connect to join this network") : qsTr("Enter password to connect")
                                color: Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.small
                            }
                        }
                    }

                    // Saved and Security indicators in connection status
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.large

                        RowLayout {
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: root.isSaved ? "bookmark" : "bookmark_border"
                                color: root.isSaved ? Colours.palette.m3tertiary : Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.large
                            }

                            StyledText {
                                text: root.isSaved ? qsTr("Saved") : qsTr("Not saved")
                                color: root.isSaved ? Colours.palette.m3tertiary : Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.small
                            }
                        }

                        RowLayout {
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: root.network?.isSecure ? "lock" : "lock_open"
                                color: Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.large
                            }

                            StyledText {
                                text: root.network?.isSecure ? qsTr("Secured") : qsTr("Open")
                                color: Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.small
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Network information")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Details about this network")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: networkInfo.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: networkInfo

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.small / 2

                    StyledText {
                        text: qsTr("Signal strength")
                    }

                    Item {
                        Layout.topMargin: Appearance.spacing.small / 2
                        Layout.fillWidth: true
                        Layout.preferredHeight: Appearance.padding.smaller

                        StyledRect {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * ((root.network?.strength ?? 0) / 100)
                            radius: Appearance.rounding.full
                            color: {
                                const strength = root.network?.strength ?? 0;
                                if (strength >= 70) return Colours.palette.m3primary;
                                if (strength >= 40) return Colours.palette.m3tertiary;
                                return Colours.palette.m3error;
                            }

                            Behavior on width {
                                Anim {}
                            }
                        }

                        StyledRect {
                            anchors.fill: parent
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3secondaryContainer
                            z: -1
                        }
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.small / 2
                        text: (root.network?.strength ?? 0) + "%"
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    InfoRow {
                        label: qsTr("SSID")
                        value: root.network?.ssid ?? qsTr("Unknown")
                    }

                    InfoRow {
                        label: qsTr("BSSID")
                        value: root.network?.bssid ?? qsTr("Unknown")
                    }

                    InfoRow {
                        label: qsTr("Frequency")
                        value: {
                            const freq = root.network?.frequency ?? 0;
                            if (freq > 5000) return freq + " MHz (5 GHz)";
                            if (freq > 0) return freq + " MHz (2.4 GHz)";
                            return qsTr("Unknown");
                        }
                    }

                    RowLayout {
                        Layout.topMargin: Appearance.spacing.normal
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("Security")
                        }

                        Item { Layout.fillWidth: true }

                        MaterialIcon {
                            text: root.network?.isSecure ? "lock" : "lock_open"
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledText {
                            text: root.network?.security || qsTr("Open")
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                        }
                    }

                    RowLayout {
                        Layout.topMargin: Appearance.spacing.normal
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("Saved")
                        }

                        Item { Layout.fillWidth: true }

                        MaterialIcon {
                            text: root.isSaved ? "bookmark" : "bookmark_border"
                            color: root.isSaved ? Colours.palette.m3tertiary : Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledText {
                            text: root.isSaved ? qsTr("Yes") : qsTr("No")
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                        }
                    }
                }
            }

            // Network traffic section (only when connected)
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Network traffic")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: root.network?.active ?? false
            }

            StyledText {
                text: qsTr("Current transfer speeds")
                color: Colours.palette.m3outline
                visible: root.network?.active ?? false
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: trafficInfo.implicitHeight + Appearance.padding.large * 2
                visible: root.network?.active ?? false

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: trafficInfo

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: dlCol.implicitHeight + Appearance.padding.normal * 2
                            
                            radius: Appearance.rounding.small
                            color: Colours.tPalette.m3surfaceContainerHigh

                            ColumnLayout {
                                id: dlCol
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                spacing: Appearance.spacing.small

                                RowLayout {
                                    spacing: Appearance.spacing.small
                                    
                                    MaterialIcon {
                                        text: "download"
                                        color: Colours.palette.m3primary
                                        font.pointSize: Appearance.font.size.large
                                    }
                                    
                                    StyledText {
                                        text: qsTr("Download")
                                        color: Colours.palette.m3onSurface
                                    }
                                }

                                StyledText {
                                    text: Network.formatSpeed(Network.downloadSpeed)
                                    font.pointSize: Appearance.font.size.large
                                    font.weight: 500
                                }
                            }
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: ulCol.implicitHeight + Appearance.padding.normal * 2
                            
                            radius: Appearance.rounding.small
                            color: Colours.tPalette.m3surfaceContainerHigh

                            ColumnLayout {
                                id: ulCol
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                spacing: Appearance.spacing.small

                                RowLayout {
                                    spacing: Appearance.spacing.small
                                    
                                    MaterialIcon {
                                        text: "upload"
                                        color: Colours.palette.m3tertiary
                                        font.pointSize: Appearance.font.size.large
                                    }
                                    
                                    StyledText {
                                        text: qsTr("Upload")
                                        color: Colours.palette.m3onSurface
                                    }
                                }

                                StyledText {
                                    text: Network.formatSpeed(Network.uploadSpeed)
                                    font.pointSize: Appearance.font.size.large
                                    font.weight: 500
                                }
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Interface: %1").arg(Network.networkInterface)
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }
                }
            }

            // Connection details section (only when connected)
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Connection details")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: root.network?.active ?? false
            }

            StyledText {
                text: qsTr("IP and network information")
                color: Colours.palette.m3outline
                visible: root.network?.active ?? false
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: connectionDetails.implicitHeight + Appearance.padding.large * 2
                visible: root.network?.active ?? false

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: connectionDetails

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.small / 2

                    InfoRow {
                        label: qsTr("IP Address")
                        value: Network.ipAddress || qsTr("Not available")
                    }

                    InfoRow {
                        label: qsTr("Gateway")
                        value: Network.gateway || qsTr("Not available")
                    }

                    InfoRow {
                        label: qsTr("DNS Server")
                        value: Network.dns || qsTr("Not available")
                    }

                    InfoRow {
                        label: qsTr("MAC Address")
                        value: Network.macAddress || qsTr("Not available")
                    }

                    RowLayout {
                        Layout.topMargin: Appearance.spacing.normal
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("Band")
                        }

                        Item { Layout.fillWidth: true }

                        MaterialIcon {
                            text: root.network?.is5GHz ? "signal_wifi_4_bar" : "network_wifi"
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledText {
                            text: root.network?.is5GHz ? "5 GHz" : "2.4 GHz"
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                        }
                    }
                }
            }
        }
    }

    // FAB for quick actions
    ColumnLayout {
        anchors.right: fabRoot.right
        anchors.bottom: fabRoot.top
        anchors.bottomMargin: Appearance.padding.normal

        Repeater {
            id: fabMenu

            model: ListModel {
                ListElement {
                    name: "connect"
                    icon: "link"
                    action: "connect"
                }
                ListElement {
                    name: "rescan"
                    icon: "wifi_find"
                    action: "rescan"
                }
                ListElement {
                    name: "forget"
                    icon: "delete"
                    action: "forget"
                }
            }

            StyledClippingRect {
                id: fabMenuItem

                required property var modelData
                required property int index

                readonly property bool isForget: modelData.action === "forget"
                readonly property bool isConnect: modelData.action === "connect"
                readonly property bool shouldShow: {
                    if (isForget) return root.isSaved;
                    if (isConnect) return !root.network?.active;
                    return true;
                }

                visible: shouldShow

                Layout.alignment: Qt.AlignRight

                implicitHeight: fabMenuItemInner.implicitHeight + Appearance.padding.larger * 2

                radius: Appearance.rounding.full
                color: isForget ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer

                opacity: 0

                states: State {
                    name: "visible"
                    when: root.session.nw.fabMenuOpen

                    PropertyChanges {
                        fabMenuItem.implicitWidth: fabMenuItemInner.implicitWidth + Appearance.padding.large * 2
                        fabMenuItem.opacity: 1
                        fabMenuItemInner.opacity: 1
                    }
                }

                transitions: [
                    Transition {
                        to: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: (fabMenu.count - 1 - fabMenuItem.index) * Appearance.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                Anim {
                                    property: "implicitWidth"
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                                Anim {
                                    property: "opacity"
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    },
                    Transition {
                        from: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: fabMenuItem.index * Appearance.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                Anim {
                                    property: "implicitWidth"
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                                Anim {
                                    property: "opacity"
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    }
                ]

                StateLayer {
                    color: fabMenuItem.isForget ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer

                    function onClicked(): void {
                        root.session.nw.fabMenuOpen = false;

                        const action = fabMenuItem.modelData.action;
                        if (action === "connect") {
                            if (root.isSaved) {
                                // Saved network
                                Network.connectToNetwork(root.network.ssid, "", true);
                            } else if (root.network?.isSecure) {
                                // New secured network - need password
                                root.session.nw.pendingNetwork = root.network;
                                root.session.nw.connectDialogOpen = true;
                            } else {
                                // Open network (not saved)
                                Network.connectToNetwork(root.network.ssid, "", false);
                            }
                        } else if (action === "rescan") {
                            Network.rescanWifi();
                        } else if (action === "forget") {
                            // Open confirmation dialog instead of direct forget
                            root.session.nw.networkToForget = root.network;
                            root.session.nw.forgetDialogOpen = true;
                        }
                    }
                }

                RowLayout {
                    id: fabMenuItemInner

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.normal
                    opacity: 0

                    MaterialIcon {
                        text: fabMenuItem.isConnect ? (root.network?.isSecure && !root.isSaved ? "key" : "link") : fabMenuItem.modelData.icon
                        color: fabMenuItem.isForget ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                        fill: 1
                    }

                    StyledText {
                        animate: true
                        text: fabMenuItem.modelData.name
                        color: fabMenuItem.isForget ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                        font.capitalization: Font.Capitalize
                        Layout.preferredWidth: implicitWidth

                        Behavior on Layout.preferredWidth {
                            Anim {
                                duration: Appearance.anim.durations.small
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: fabRoot

        anchors.right: parent.right
        anchors.bottom: parent.bottom

        implicitWidth: 64
        implicitHeight: 64

        StyledRect {
            id: fabBg

            anchors.right: parent.right
            anchors.top: parent.top

            implicitWidth: 64
            implicitHeight: 64

            radius: Appearance.rounding.normal
            color: root.session.nw.fabMenuOpen ? Colours.palette.m3primary : Colours.palette.m3primaryContainer

            states: State {
                name: "expanded"
                when: root.session.nw.fabMenuOpen

                PropertyChanges {
                    fabBg.implicitWidth: 48
                    fabBg.implicitHeight: 48
                    fabBg.radius: 48 / 2
                    fab.font.pointSize: Appearance.font.size.larger
                }
            }

            transitions: Transition {
                Anim {
                    properties: "implicitWidth,implicitHeight"
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
                Anim {
                    properties: "radius,font.pointSize"
                }
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: fabState.containsMouse && !fabState.pressed ? 4 : 3
            }

            StateLayer {
                id: fabState

                color: root.session.nw.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer

                function onClicked(): void {
                    root.session.nw.fabMenuOpen = !root.session.nw.fabMenuOpen;
                }
            }

            MaterialIcon {
                id: fab

                anchors.centerIn: parent
                animate: true
                text: root.session.nw.fabMenuOpen ? "close" : "more_vert"
                color: root.session.nw.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer
                font.pointSize: Appearance.font.size.large
                fill: 1
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }

    component InfoRow: ColumnLayout {
        required property string label
        required property string value

        Layout.topMargin: Appearance.spacing.normal
        spacing: 0

        StyledText {
            text: parent.label
        }

        StyledText {
            text: parent.value
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.small
        }
    }
}
