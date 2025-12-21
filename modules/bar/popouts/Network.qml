pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

// Network popout - iOS Sheet style (Feature Rich)
ColumnLayout {
    id: root

    required property Item wrapper

    // Computed properties
    readonly property bool isEnabled: Network.wifiEnabled && !Network.airplaneMode
    readonly property bool isScanning: Network.scanning
    readonly property var activeNetwork: Network.active
    readonly property var savedNetworks: Network.networks.filter(n => n.isSaved && !n.active)
    readonly property var availableNetworks: Network.networks.filter(n => !n.isSaved && !n.active)

    // Error handling
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
        visible: opacity > 0
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
    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Appearance.padding.small
        implicitWidth: 32
        implicitHeight: 4
        radius: 2
        color: Colours.palette.m3outlineVariant

        StateLayer {
            radius: Appearance.rounding.small

            function onClicked(): void {
                root.wrapper.detach("network");
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
                width: parent.width
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: Network.airplaneMode ? "airplanemode_active" : "wifi"
                    color: root.isEnabled ? Colours.palette.m3primary : Colours.palette.m3outline
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: Network.airplaneMode ? qsTr("Airplane Mode") : qsTr("Wi-Fi")
                        font.weight: 600
                    }

                    StyledText {
                        visible: root.isEnabled
                        text: {
                            if (root.activeNetwork)
                                return root.activeNetwork.ssid;
                            return qsTr("Not connected");
                        }
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                    }
                }

                // Spacer
                Item { Layout.fillWidth: true }

                StyledSwitch {
                    checked: Network.wifiEnabled
                    enabled: !Network.airplaneMode
                    onClicked: Network.toggleWifi()
                }
            }

            // Status badges row - animated height
            Item {
                readonly property bool hasBadges: root.isScanning || Network.airplaneMode || Network.captivePortalDetected

                Layout.fillWidth: true
                implicitHeight: (root.isEnabled && hasBadges) ? badgesContent.implicitHeight : 0
                clip: true

                Behavior on implicitHeight { Anim {} }

                RowLayout {
                    id: badgesContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    opacity: parent.hasBadges ? 1 : 0
                    scale: parent.hasBadges ? 1 : 0.8

                    Behavior on opacity { Anim {} }
                    Behavior on scale { Anim {} }

                    // Scanning badge
                    Item {
                        implicitWidth: root.isScanning ? scanBadge.implicitWidth : 0
                        implicitHeight: scanBadge.implicitHeight
                        clip: true

                        Behavior on implicitWidth { Anim {} }

                        StyledRect {
                            id: scanBadge
                            implicitWidth: scanLabel.implicitWidth + Appearance.padding.normal * 2
                            implicitHeight: scanLabel.implicitHeight + Appearance.padding.small
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3tertiaryContainer

                            opacity: root.isScanning ? 1 : 0
                            scale: root.isScanning ? 1 : 0.8

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

                    // Captive Portal badge
                    Item {
                        implicitWidth: Network.captivePortalDetected ? portalBadge.implicitWidth : 0
                        implicitHeight: portalBadge.implicitHeight
                        clip: true

                        Behavior on implicitWidth { Anim {} }

                        StyledRect {
                            id: portalBadge
                            implicitWidth: portalLabel.implicitWidth + Appearance.padding.normal * 2
                            implicitHeight: portalLabel.implicitHeight + Appearance.padding.small
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3secondaryContainer

                            opacity: Network.captivePortalDetected ? 1 : 0
                            scale: Network.captivePortalDetected ? 1 : 0.8

                            Behavior on opacity { Anim {} }
                            Behavior on scale { Anim {} }

                            StateLayer {
                                radius: Appearance.rounding.full
                                color: Colours.palette.m3onSecondaryContainer
                                function onClicked(): void {
                                    Network.openCaptivePortal();
                                }
                            }

                            RowLayout {
                                id: portalLabel
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.smaller

                                MaterialIcon {
                                    text: "login"
                                    font.pointSize: Appearance.font.size.smaller
                                    color: Colours.palette.m3onSecondaryContainer
                                }

                                StyledText {
                                    text: qsTr("Sign in")
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
    // Quick Actions - always visible so airplane mode can be toggled
    // ═══════════════════════════════════════════════════
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        // Scan button
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Appearance.rounding.small
            color: root.isScanning ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerHigh

            StateLayer {
                color: root.isScanning ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                disabled: root.isScanning || !root.isEnabled  // Disabled when scanning or airplane/wifi off

                function onClicked(): void {
                    if (!root.isScanning && root.isEnabled) {
                        Network.rescanWifi();
                    }
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.smaller

                MaterialIcon {
                    text: root.isScanning ? "wifi_find" : "search"
                    font.pointSize: Appearance.font.size.normal
                    color: root.isScanning ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                }

                StyledText {
                    text: root.isScanning ? qsTr("Stop") : qsTr("Scan")
                    font.pointSize: Appearance.font.size.small
                    color: root.isScanning ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                }
            }
        }

        // Airplane mode toggle
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Appearance.rounding.small
            color: Network.airplaneMode ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

            StateLayer {
                color: Network.airplaneMode ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                function onClicked(): void {
                    Network.toggleAirplaneMode();
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.smaller

                MaterialIcon {
                    text: "airplanemode_active"
                    font.pointSize: Appearance.font.size.normal
                    color: Network.airplaneMode ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }

                StyledText {
                    text: qsTr("Airplane")
                    font.pointSize: Appearance.font.size.small
                    color: Network.airplaneMode ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Connected Section
    // ═══════════════════════════════════════════════════
    RowLayout {
        visible: root.isEnabled && root.activeNetwork
        spacing: Appearance.spacing.small

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        StyledText {
            text: qsTr("Connected")
            font.pointSize: Appearance.font.size.small
            // color: Colours.palette.m3primary
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }
    }

    // Connected network card
    StyledRect {
        visible: root.isEnabled && root.activeNetwork
        Layout.fillWidth: true
        implicitWidth: 280
        implicitHeight: connectedRow.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainerHigh





        RowLayout {
            id: connectedRow

            width: parent.width - Appearance.padding.normal * 2
            x: Appearance.padding.normal
            y: Appearance.padding.small
            spacing: Appearance.spacing.small

            // anchors.fill: parent
            // anchors.margins: Appearance.padding.small
            // spacing: Appearance.spacing.normal

            MaterialIcon {
                text: Icons.getNetworkIcon(root.activeNetwork?.strength ?? 0)
                color: Colours.palette.m3primary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: root.activeNetwork?.ssid ?? ""
                    font.weight: 600
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    text: qsTr("Signal: %1%").arg(root.activeNetwork?.strength ?? 0)
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3outline
                }
            }

            // Disconnect button
            StyledRect {
                implicitWidth: 28
                implicitHeight: 28
                radius: Appearance.rounding.full
                color: Colours.palette.m3primary

                StateLayer {
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3onPrimary

                    function onClicked(): void {
                        Network.disconnectFromNetwork();
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "link_off"
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3onPrimary
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Available Section - animated height
    // ═══════════════════════════════════════════════════
    Item {
        readonly property bool shouldShow: root.isEnabled && root.availableNetworks.length > 0

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
                    // color: Colours.palette.m3tertiary
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colours.palette.m3outlineVariant
                }
            }

            // Available networks card
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
                            values: root.availableNetworks.slice(0, 4)
                        }

                        NetworkRow {
                            required property var modelData
                            width: parent.width
                            network: modelData
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // INLINE COMPONENTS
    // ═══════════════════════════════════════════════════

    component NetworkRow: Item {
        id: row

        required property var network
        readonly property bool loading: Network.connecting && Network.lastConnectedSSID === network.ssid

        implicitHeight: 40

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
                text: Icons.getNetworkIcon(row.network.strength)
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                text: row.network.ssid
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            // Lock icon if secured
            MaterialIcon {
                visible: row.network.isSecure && !row.network.isSaved
                text: "lock"
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
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
                        if (row.network.isSaved) {
                            Network.connectToNetwork(row.network.ssid, "", true);
                        } else if (row.network.isSecure) {
                            Network.pendingNetworkFromBar = row.network;
                            Network.openPasswordDialogOnPanelOpen = true;
                            root.wrapper.detach("network");
                        } else {
                            Network.connectToNetwork(row.network.ssid, "", false);
                        }
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: row.network.isSecure && !row.network.isSaved ? "key" : "link"
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3outline
                    opacity: row.loading ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
