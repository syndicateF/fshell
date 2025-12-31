pragma ComponentBehavior: Bound

import qs.services
import qs.config
import Quickshell.Services.UPower
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    required property bool showPercent

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: batteryIOS.implicitHeight

    Item {
        id: batteryIOS
        anchors.centerIn: parent
        
        readonly property real bodyWidth: 30
        readonly property real bodyHeight: 16
        readonly property real bodyRadius: 5
        readonly property real terminalWidth: 2.5
        readonly property real terminalHeight: 4.5
        readonly property real terminalGap: 1
        
        implicitWidth: bodyWidth + terminalGap + terminalWidth
        implicitHeight: bodyHeight

        readonly property real level: UPower.displayDevice.percentage
        readonly property real pct: level * 100
        readonly property bool charging: [
            UPowerDeviceState.Charging,
            UPowerDeviceState.FullyCharged,
            UPowerDeviceState.PendingCharge
        ].includes(UPower.displayDevice.state)

        readonly property color frameColor: {
            if (charging) return Qt.darker(Colours.palette.m3secondary, 2.5);
            if (pct <= 20) return Qt.darker(Colours.palette.m3error, 2.5);
            return Qt.darker(Colours.palette.m3primary, 2.5);
        }
        readonly property color fillColor: {
            if (charging) return Colours.palette.m3secondary;
            if (pct <= 20) return Colours.palette.m3error;
            return Colours.palette.m3primary;
        }

        Item {
            id: bodyContainer
            anchors.verticalCenter: parent.verticalCenter
            width: batteryIOS.bodyWidth
            height: batteryIOS.bodyHeight
            
            // Enable layer for masking
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: bodyContainer.width
                    height: bodyContainer.height
                    radius: batteryIOS.bodyRadius
                }
            }
            
            // Frame (background)
            Rectangle {
                id: frame
                anchors.fill: parent
                color: batteryIOS.frameColor
            }
            
            // Fill - PLAIN RECTANGLE, no radius! Masked by body shape.
            Rectangle {
                id: fill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(batteryIOS.pct / 100, 1)
                color: batteryIOS.fillColor
                
                // NO RADIUS - the OpacityMask clips it to body shape
            }
        }
        
        // Percentage text (outside mask layer so it's always visible)
        Text {
            anchors.centerIn: bodyContainer
            text: Math.round(batteryIOS.pct).toString()
            font.pointSize: Config.bar.sizes.font.batteryPercentage
            font.bold: true
            color: Colours.palette.m3surface
            visible: root.showPercent
        }

        // Terminal (pentil)
        Rectangle {
            anchors.left: bodyContainer.right
            anchors.leftMargin: batteryIOS.terminalGap
            anchors.verticalCenter: parent.verticalCenter
            width: batteryIOS.terminalWidth
            height: batteryIOS.terminalHeight
            color: batteryIOS.frameColor
            
            topLeftRadius: 0
            bottomLeftRadius: 0
            topRightRadius: batteryIOS.bodyRadius
            bottomRightRadius: batteryIOS.bodyRadius
        }
    }
}