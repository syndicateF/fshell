pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import QtQuick

// Network icon - iOS style WiFi bars OR USB icon when tethering
Item {
    id: root

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: Math.max(wifiIOS.implicitHeight, usbIcon.implicitHeight)

    // USB tethering takes priority over WiFi display
    readonly property bool showUsb: Network.usbTetheringConnected
    readonly property bool showWifi: !showUsb

    // WiFi icon (iOS style signal bars)
    Item {
        id: wifiIOS
        anchors.centerIn: parent
        implicitWidth: 20
        implicitHeight: 16
        
        // Smooth hide when USB connected
        opacity: root.showWifi ? 1 : 0
        scale: root.showWifi ? 1 : 0.8
        visible: opacity > 0
        
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        readonly property bool connected: Network.active !== null
        readonly property int strength: connected ? (Network.active.strength ?? 0) : 0
        readonly property int bars: Math.ceil(strength / 34)  // 0-3 bars
        readonly property color activeColor: Colours.palette.m3primary
        readonly property color inactiveColor: Colours.palette.m3outline

        // Base dot (always visible when connected)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 3
            height: 3
            radius: 1.5
            color: wifiIOS.connected ? wifiIOS.activeColor : wifiIOS.inactiveColor

            Behavior on color {
                ColorAnimation { duration: 300; easing.type: Easing.OutBack }
            }
        }

        // Arc 1 (small)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            width: 8
            height: 3
            radius: 4
            color: "transparent"
            border.width: 2
            border.color: wifiIOS.bars >= 1 ? wifiIOS.activeColor : wifiIOS.inactiveColor

            Behavior on border.color {
                ColorAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
        }

        // Arc 2 (medium)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 7
            anchors.horizontalCenter: parent.horizontalCenter
            width: 13
            height: 5
            radius: 6.5
            color: "transparent"
            border.width: 2
            border.color: wifiIOS.bars >= 2 ? wifiIOS.activeColor : wifiIOS.inactiveColor

            Behavior on border.color {
                ColorAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
        }

        // Arc 3 (large)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: 18
            height: 7
            radius: 9
            color: "transparent"
            border.width: 2
            border.color: wifiIOS.bars >= 3 ? wifiIOS.activeColor : wifiIOS.inactiveColor

            Behavior on border.color {
                ColorAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
        }
    }

    // USB tethering icon (Material icon)
    MaterialIcon {
        id: usbIcon
        anchors.centerIn: parent
        text: "usb"
        font.pointSize: 14
        color: Colours.palette.m3primary
        
        // Smooth show when USB connected
        opacity: root.showUsb ? 1 : 0
        scale: root.showUsb ? 1 : 0.5
        visible: opacity > 0
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
    }
}
