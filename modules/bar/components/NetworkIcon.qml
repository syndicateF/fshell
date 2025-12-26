pragma ComponentBehavior: Bound

import qs.services
import qs.config
import QtQuick

// Network icon - iOS style dengan signal bars
Item {
    id: root

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: wifiIOS.implicitHeight

    Item {
        id: wifiIOS
        anchors.centerIn: parent
        implicitWidth: 20
        implicitHeight: 16

        readonly property bool connected: Network.active !== null
        readonly property int strength: connected ? (Network.active.strength ?? 0) : 0
        readonly property int bars: Math.ceil(strength / 34)  // 0-3 bars
        readonly property color activeColor: Colours.palette.m3primary  // Accent color
        readonly property color inactiveColor: Colours.palette.m3outline

        // Base dot (always visible when connected)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 3
            height: 3
            radius: 1.5
            color: wifiIOS.connected ? wifiIOS.activeColor : wifiIOS.inactiveColor
            // REMOVED: Breathing animation that was causing 40% GPU load!
            // Signal strength is already shown via the bars - no need for pulsing.

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
}
