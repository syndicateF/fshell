pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: "wifi"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Wi-Fi settings")
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Network status")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("General network settings")
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

            spacing: Appearance.spacing.larger

            Toggle {
                label: qsTr("Wi-Fi enabled")
                checked: Network.wifiEnabled
                toggle.onToggled: {
                    Network.enableWifi(checked);
                }
            }
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Current connection")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Active network information")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: currentConnection.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: currentConnection

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.small / 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: connIcon.implicitHeight + Appearance.padding.normal * 2

                    radius: Appearance.rounding.normal
                    color: Network.active ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    MaterialIcon {
                        id: connIcon

                        anchors.centerIn: parent
                        text: Network.active ? getWifiIcon(Network.active.strength) : "signal_wifi_off"
                        color: Network.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.large
                        fill: Network.active ? 1 : 0

                        function getWifiIcon(strength: int): string {
                            if (strength >= 80) return "signal_wifi_4_bar";
                            if (strength >= 60) return "network_wifi_3_bar";
                            if (strength >= 40) return "network_wifi_2_bar";
                            if (strength >= 20) return "network_wifi_1_bar";
                            return "signal_wifi_0_bar";
                        }

                        Behavior on fill {
                            Anim {}
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Network.active?.ssid ?? qsTr("Not connected")
                        font.weight: 500
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Network.active ? qsTr("Signal: %1%").arg(Network.active.strength) : qsTr("No active connection")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    visible: Network.active
                    implicitWidth: implicitHeight
                    implicitHeight: disconnectIcon.implicitHeight + Appearance.padding.smaller * 2

                    radius: Appearance.rounding.full
                    color: Colours.palette.m3errorContainer

                    StateLayer {
                        color: Colours.palette.m3onErrorContainer

                        function onClicked(): void {
                            Network.disconnectFromNetwork();
                        }
                    }

                    MaterialIcon {
                        id: disconnectIcon

                        anchors.centerIn: parent
                        text: "link_off"
                        color: Colours.palette.m3onErrorContainer
                    }
                }
            }

            // Traffic info when connected
            Loader {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                active: Network.active !== null
                visible: active

                sourceComponent: RowLayout {
                    spacing: Appearance.spacing.large

                    RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: "download"
                            color: Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledText {
                            text: Network.formatSpeed(Network.downloadSpeed)
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.small
                        }
                    }

                    RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: "upload"
                            color: Colours.palette.m3tertiary
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledText {
                            text: Network.formatSpeed(Network.uploadSpeed)
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.small
                        }
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: Network.networkInterface
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }
                }
            }
            
            // Captive portal indicator
            Loader {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                active: Network.captivePortalDetected
                visible: active

                sourceComponent: StyledRect {
                    implicitHeight: captiveContent.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3tertiaryContainer

                    StateLayer {
                        color: Colours.palette.m3onTertiaryContainer

                        function onClicked(): void {
                            Network.openCaptivePortal();
                        }
                    }

                    RowLayout {
                        id: captiveContent
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "captive_portal"
                            color: Colours.palette.m3onTertiaryContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Sign in required - Tap to authenticate")
                            color: Colours.palette.m3onTertiaryContainer
                            font.pointSize: Appearance.font.size.small
                        }

                        MaterialIcon {
                            text: "open_in_new"
                            color: Colours.palette.m3onTertiaryContainer
                            font.pointSize: Appearance.font.size.small
                        }
                    }
                }
            }
        }
    }

    // Saved Networks Section
    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Saved networks (%1)").arg(Network.savedConnections.length)
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Manage saved Wi-Fi connections")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: savedNetworksContent.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: savedNetworksContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.small

            Repeater {
                model: ScriptModel {
                    values: [...Network.savedConnections].sort((a, b) => a.name.localeCompare(b.name))
                }

                delegate: Item {
                    id: savedNetwork

                    required property var modelData
                    readonly property bool isActive: Network.active?.ssid === modelData.name
                    readonly property bool inRange: modelData.inRange  // Use the inRange property from SavedConnection
                    readonly property var accessPoint: modelData.accessPoint

                    Layout.fillWidth: true
                    implicitHeight: savedNetworkInner.implicitHeight + Appearance.padding.normal * 2

                    StateLayer {
                        radius: Appearance.rounding.small
                        disabled: !savedNetwork.inRange && !savedNetwork.isActive

                        function onClicked(): void {
                            if (savedNetwork.inRange && !savedNetwork.isActive) {
                                Network.connectToNetwork(savedNetwork.modelData.name, "");
                            } else if (!savedNetwork.inRange) {
                                Network.showWarning(qsTr("Network '%1' is not in range").arg(savedNetwork.modelData.name), "warning");
                            }
                        }
                    }

                    RowLayout {
                        id: savedNetworkInner

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: savedIcon.implicitHeight + Appearance.padding.small * 2

                            radius: Appearance.rounding.small
                            color: savedNetwork.isActive ? Colours.palette.m3primaryContainer : savedNetwork.inRange ? Colours.palette.m3tertiaryContainer : Colours.tPalette.m3surfaceContainerHigh

                            MaterialIcon {
                                id: savedIcon

                                anchors.centerIn: parent
                                text: savedNetwork.isActive ? "wifi" : savedNetwork.inRange ? "bookmark" : "wifi_off"
                                color: savedNetwork.isActive ? Colours.palette.m3onPrimaryContainer : savedNetwork.inRange ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3outline
                                fill: savedNetwork.isActive ? 1 : 0
                                opacity: savedNetwork.inRange || savedNetwork.isActive ? 1 : 0.5
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: savedNetwork.modelData.name
                                elide: Text.ElideRight
                                opacity: savedNetwork.inRange || savedNetwork.isActive ? 1 : 0.5
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    if (savedNetwork.isActive) return qsTr("Connected");
                                    if (savedNetwork.inRange) {
                                        const ap = savedNetwork.accessPoint;
                                        return qsTr("In range - %1%").arg(ap?.strength ?? 0);
                                    }
                                    return qsTr("Out of range");
                                }
                                color: savedNetwork.isActive ? Colours.palette.m3primary : savedNetwork.inRange ? Colours.palette.m3tertiary : Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.small
                                elide: Text.ElideRight
                            }
                        }

                        // Connect button - only show if in range and not connected
                        StyledRect {
                            visible: savedNetwork.inRange && !savedNetwork.isActive
                            implicitWidth: implicitHeight
                            implicitHeight: connectSavedIcon.implicitHeight + Appearance.padding.smaller * 2

                            radius: Appearance.rounding.full
                            color: "transparent"

                            StateLayer {
                                function onClicked(): void {
                                    Network.connectToNetwork(savedNetwork.modelData.name, "");
                                }
                            }

                            MaterialIcon {
                                id: connectSavedIcon

                                anchors.centerIn: parent
                                text: "link"
                                color: Colours.palette.m3onSurface
                            }
                        }

                        // Forget button - opens confirmation dialog
                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: forgetIcon.implicitHeight + Appearance.padding.smaller * 2

                            radius: Appearance.rounding.full
                            color: "transparent"

                            StateLayer {
                                color: Colours.palette.m3error

                                function onClicked(): void {
                                    // Open confirmation dialog
                                    root.session.nw.networkToForget = savedNetwork.modelData;
                                    root.session.nw.forgetDialogOpen = true;
                                }
                            }

                            MaterialIcon {
                                id: forgetIcon

                                anchors.centerIn: parent
                                text: "delete"
                                color: Colours.palette.m3error
                            }
                        }
                    }
                }
            }

            // Empty state
            Loader {
                Layout.fillWidth: true
                active: Network.savedConnections.length === 0
                visible: active

                sourceComponent: ColumnLayout {
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "wifi_off"
                        font.pointSize: Appearance.font.size.extraLarge
                        color: Colours.palette.m3outline
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No saved networks")
                        color: Colours.palette.m3outline
                    }
                }
            }
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Quick actions")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Network management actions")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: quickActions.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: quickActions

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.normal

            ActionButton {
                icon: "wifi_find"
                label: qsTr("Scan for networks")
                sublabel: Network.scanning ? qsTr("Scanning...") : qsTr("Refresh available networks")
                loading: Network.scanning
                onClicked: Network.rescanWifi()
            }
            
            ActionButton {
                visible: Network.captivePortalDetected
                icon: "captive_portal"
                label: qsTr("Open sign-in page")
                sublabel: qsTr("Authenticate with network portal")
                onClicked: Network.openCaptivePortal()
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
        text: qsTr("Statistics and details")
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
                text: qsTr("Available networks")
            }

            StyledText {
                text: Network.networks.length.toString()
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Saved networks")
            }

            StyledText {
                text: Network.savedConnections.length.toString()
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
            
            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("In range")
            }

            StyledText {
                text: Network.savedConnections.filter(c => c.inRange).length.toString()
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Wi-Fi status")
            }

            StyledText {
                text: Network.wifiEnabled ? qsTr("Enabled") : qsTr("Disabled")
                color: Network.wifiEnabled ? Colours.palette.m3primary : Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Active interface")
            }

            StyledText {
                text: Network.networkInterface || qsTr("None")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle

            cLayer: 2
        }
    }

    component ActionButton: Item {
        id: actionBtn

        required property string icon
        required property string label
        property string sublabel: ""
        property bool loading: false

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: actionInner.implicitHeight + Appearance.padding.normal * 2

        StateLayer {
            radius: Appearance.rounding.small

            function onClicked(): void {
                actionBtn.clicked();
            }
        }

        RowLayout {
            id: actionInner

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: actionIcon.implicitHeight + Appearance.padding.normal * 2

                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh

                CircularIndicator {
                    anchors.fill: parent
                    running: actionBtn.loading
                }

                MaterialIcon {
                    id: actionIcon

                    anchors.centerIn: parent
                    text: actionBtn.icon
                    color: Colours.palette.m3onSurface
                    opacity: actionBtn.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: actionBtn.label
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !!actionBtn.sublabel
                    text: actionBtn.sublabel
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                text: "chevron_right"
                color: Colours.palette.m3outline
            }
        }
    }
}
