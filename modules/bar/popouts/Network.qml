pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

// Network popout - Bluetooth style (minimalist)
ColumnLayout {
    id: root

    required property Item wrapper

    spacing: Appearance.spacing.small

    // Title with connection state
    StyledText {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.small
        text: {
            if (Network.airplaneMode) return qsTr("Wi-Fi (airplane mode)");
            if (!Network.wifiEnabled) return qsTr("Wi-Fi (disabled)");
            if (Network.active) return qsTr("Wi-Fi (%1)").arg(Network.active.ssid);
            return qsTr("Wi-Fi");
        }
        font.weight: 500
    }

    // WiFi toggle
    Toggle {
        label: qsTr("Enabled")
        checked: Network.wifiEnabled
        disabled: Network.airplaneMode
        toggle.onToggled: {
            Network.toggleWifi();
        }
    }

    // Airplane mode toggle
    Toggle {
        label: qsTr("Airplane mode")
        checked: Network.airplaneMode
        toggle.onToggled: {
            Network.toggleAirplaneMode();
        }
    }

    // Network count + captive portal indicator
    StyledText {
        Layout.topMargin: Appearance.spacing.small
        Layout.rightMargin: Appearance.padding.small
        text: {
            let msg = qsTr("%1 network%2 available").arg(Network.networks.length).arg(Network.networks.length === 1 ? "" : "s");
            if (Network.captivePortalDetected) msg += qsTr(" (sign-in required)");
            return msg;
        }
        color: Network.captivePortalDetected ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.small
        
        MouseArea {
            anchors.fill: parent
            visible: Network.captivePortalDetected
            cursorShape: Qt.PointingHandCursor
            onClicked: Network.openCaptivePortal()
        }
    }

    // Network list
    Repeater {
        model: ScriptModel {
            values: [...Network.networks].sort((a, b) => {
                if (a.active !== b.active) return b.active - a.active;
                if (a.isSaved !== b.isSaved) return b.isSaved - a.isSaved;
                return b.strength - a.strength;
            }).slice(0, 5)
        }

        RowLayout {
            id: networkItem

            required property var modelData
            readonly property bool isConnecting: Network.connecting && Network.lastConnectedSSID === modelData.ssid

            Layout.fillWidth: true
            Layout.rightMargin: Appearance.padding.small
            spacing: Appearance.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity { Anim {} }
            Behavior on scale { Anim {} }

            // Network icon
            MaterialIcon {
                text: Icons.getNetworkIcon(networkItem.modelData.strength)
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            // SSID
            StyledText {
                Layout.leftMargin: Appearance.spacing.small / 2
                Layout.rightMargin: Appearance.spacing.small / 2
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font.weight: networkItem.modelData.active ? 500 : 400
            }

            // Connect button
            StyledRect {
                id: connectBtn

                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Appearance.padding.small

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: networkItem.isConnecting
                }

                StateLayer {
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: networkItem.isConnecting || !Network.wifiEnabled || Network.airplaneMode

                    function onClicked(): void {
                        if (networkItem.modelData.active) {
                            Network.disconnectFromNetwork();
                        } else if (networkItem.modelData.isSaved) {
                            Network.connectToNetwork(networkItem.modelData.ssid, "", true);
                        } else if (networkItem.modelData.isSecure) {
                            Network.pendingNetworkFromBar = networkItem.modelData;
                            Network.openPasswordDialogOnPanelOpen = true;
                            root.wrapper.detach("network");
                        } else {
                            Network.connectToNetwork(networkItem.modelData.ssid, "", false);
                        }
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : networkItem.modelData.isSecure && !networkItem.modelData.isSaved ? "key" : "link"
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: networkItem.isConnecting ? 0 : 1
                    Behavior on opacity { Anim {} }
                }
            }
        }
    }

    // Open panel button (sama dengan Bluetooth)
    StyledRect {
        Layout.topMargin: Appearance.spacing.small
        implicitWidth: expandBtn.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: expandBtn.implicitHeight + Appearance.padding.small

        radius: Appearance.rounding.normal
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer

            function onClicked(): void {
                root.wrapper.detach("network");
            }
        }

        RowLayout {
            id: expandBtn

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            StyledText {
                Layout.leftMargin: Appearance.padding.smaller
                text: qsTr("Open panel")
                color: Colours.palette.m3onPrimaryContainer
            }

            MaterialIcon {
                text: "chevron_right"
                color: Colours.palette.m3onPrimaryContainer
                font.pointSize: Appearance.font.size.large
            }
        }
    }

    // Toggle component (sama dengan Bluetooth)
    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle
        property bool disabled: false

        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
            opacity: parent.disabled ? 0.5 : 1
        }

        StyledSwitch {
            id: toggle
            enabled: !parent.disabled
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
