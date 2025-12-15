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
            // Fill color dari color scheme
            if (charging) return Colours.palette.m3secondary;  // Secondary (charging)
            if (pct <= 20) return Colours.palette.m3error;  // Error (critical)
            if (pct <= 100) return Colours.palette.m3primary;  // Primary (normal discharge)
            return Colours.palette.m3onSurface;  // Neutral (fallback)
        }

        // BODY tanpa outline (iOS Solid Capsule)
        Rectangle {
            id: body
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 16
            radius: 6
            color: batteryIOS.frameColor
            clip: true
            
            // isi fill dengan radius per-corner
            Rectangle {
                id: fill
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                // Width: maksimal sampai (body.width - margin) untuk avoid area rounded body di kanan
                // Ketika 100%, boleh full width untuk merge dengan body rounding
                readonly property real maxFillWidth: batteryIOS.pct >= 99 ? parent.width : parent.width - 6
                width: Math.max(0, Math.min((maxFillWidth) * (batteryIOS.pct / 100), maxFillWidth))
                height: parent.height
                color: batteryIOS.fillColor
                
                // Left side always rounded
                topLeftRadius: 6
                bottomLeftRadius: 6
                // Right side: flat (fill never reaches the rounded corner area of body)
                topRightRadius: 0
                bottomRightRadius: 0

                // Breathing animation when charging
                SequentialAnimation on opacity {
                    running: batteryIOS.charging
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.7; duration: 1500; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.7; to: 1; duration: 1500; easing.type: Easing.InOutQuad }
                }

                // Pulse animation when low battery (not charging)
                SequentialAnimation on scale {
                    running: !batteryIOS.charging && batteryIOS.pct <= 20
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 1.08; duration: 800; easing.type: Easing.OutQuad }
                    NumberAnimation { from: 1.08; to: 1; duration: 800; easing.type: Easing.InQuad }
                    PauseAnimation { duration: 2000 }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.1
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 500
                        easing.type: Easing.OutQuad
                    }
                }
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

        // Pentil (tip) iOS - rounded trapezoid
        Canvas {
            id: pentilCanvas
            anchors.left: body.right
            anchors.leftMargin: 0.5
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 7
            
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                
                ctx.fillStyle = batteryIOS.frameColor
                ctx.beginPath()
                
                // Start from left side (wider)
                ctx.moveTo(0, height * 0.2) // Top left (20% from top)
                
                // Top line going right and inward
                ctx.lineTo(width, height * 0.35) // Top right (35% from top, narrower)
                
                // Right side (rounded tip)
                ctx.arcTo(width + 1, height * 0.5, width, height * 0.65, 1.5) // Rounded corner
                
                // Bottom line going left
                ctx.lineTo(0, height * 0.8) // Bottom left (80% from top)
                
                // Left side (connect back with slight curve)
                ctx.arcTo(-0.5, height * 0.5, 0, height * 0.2, 1) // Rounded corner
                
                ctx.closePath()
                ctx.fill()
            }
            
            Connections {
                target: batteryIOS
                function onFrameColorChanged() { pentilCanvas.requestPaint() }
            }
        }
    }
}
