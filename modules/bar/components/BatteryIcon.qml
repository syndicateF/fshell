pragma ComponentBehavior: Bound

import qs.services
import qs.config
import Quickshell.Services.UPower
import QtQuick

// Battery icon - iOS 16 style with percentage inside (original style)
Item {
    id: root

    required property bool showPercent

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: batteryIOS.implicitHeight

    Item {
        id: batteryIOS
        anchors.centerIn: parent
        implicitWidth: 35
        implicitHeight: 16

        readonly property real level: UPower.displayDevice.percentage
        readonly property real pct: level * 100
        readonly property bool charging: [
            UPowerDeviceState.Charging,
            UPowerDeviceState.FullyCharged,
            UPowerDeviceState.PendingCharge
        ].includes(UPower.displayDevice.state)

        readonly property color frameColor: {
            // Frame color dari color scheme - darker version for contrast
            if (charging) return Qt.darker(Colours.palette.m3secondary, 2.5);  // Secondary (charging)
            if (pct <= 20) return Qt.darker(Colours.palette.m3error, 2.5);  // Error (critical)
            return Qt.darker(Colours.palette.m3primary, 2.5);  // Primary (normal discharge)
        }
        readonly property color fillColor: {
            if (charging) return Colours.palette.m3secondary;
            if (pct <= 20) return Colours.palette.m3error;
            return Colours.palette.m3primary;
        }

        // BODY (iOS Solid Capsule)
        Rectangle {
            id: body
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 16
            radius: 6
            color: batteryIOS.frameColor
            clip: true
            
            // Fill dengan radius per-corner
            Rectangle {
                id: fill
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                
                readonly property bool isFull: batteryIOS.pct >= 99
                width: isFull ? parent.width : (parent.width - 6) * Math.min(batteryIOS.pct / 100, 1)
                height: parent.height
                color: batteryIOS.fillColor
                
                topLeftRadius: 6
                bottomLeftRadius: 6
                topRightRadius: isFull ? 6 : 0
                bottomRightRadius: isFull ? 6 : 0
            }

            // persentase di dalam
            Text {
                anchors.centerIn: parent
                text: Math.round(batteryIOS.pct).toString()
                font.pointSize: Config.bar.sizes.font.batteryPercentage
                font.bold: true
                color: Colours.palette.m3surface
                visible: root.showPercent
            }
        }

        // Pentil
        Rectangle {
            anchors.left: body.right
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 4.5
            color: batteryIOS.frameColor
            
            topLeftRadius: 0
            bottomLeftRadius: 0
            topRightRadius: 6
            bottomRightRadius: 6
        }
    }
}
