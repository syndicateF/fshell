pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Performance Popout - Ring Gauges Design
// Shows CPU, GPU, Memory, Storage with real-time updates
Item {
    id: root

    required property Item wrapper

    // Lazy loading - SystemUsage only polls when this popout is open
    Ref {
        service: SystemUsage
    }

    implicitWidth: container.implicitWidth
    implicitHeight: container.implicitHeight

    StyledClippingRect {
        id: container

        implicitWidth: 200
        implicitHeight: contentCol.height + 24
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: contentCol
            width: parent.width - 24
            x: 12
            y: 12
            spacing: 12

            // Drag handle
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 48
                implicitHeight: 12

                Rectangle {
                    anchors.centerIn: parent
                    width: 36
                    height: 4
                    radius: 2
                    color: Colours.palette.m3outlineVariant
                }
            }

            // CPU Ring Gauge
            RingGauge {
                Layout.alignment: Qt.AlignHCenter
                name: "CPU"
                usage: SystemUsage.cpuPerc
                temp: SystemUsage.cpuTemp
                gaugeColor: Colours.palette.m3primary
            }

            // iGPU Ring Gauge (AMD integrated - only if available)
            RingGauge {
                Layout.alignment: Qt.AlignHCenter
                visible: SystemUsage.hasIGpu
                name: "iGPU"
                usage: SystemUsage.iGpuPerc
                temp: SystemUsage.iGpuTemp
                gaugeColor: Colours.palette.m3tertiary
            }

            // dGPU Ring Gauge (NVIDIA discrete - only if available)
            RingGauge {
                Layout.alignment: Qt.AlignHCenter
                visible: SystemUsage.hasDGpu
                name: "dGPU"
                usage: SystemUsage.dGpuPerc
                temp: SystemUsage.dGpuTemp
                gaugeColor: Colours.palette.m3secondary
            }

            // Memory bar
            ResourceBar {
                Layout.fillWidth: true
                icon: "memory_alt"
                usage: SystemUsage.memPerc
                barColor: Colours.palette.m3tertiary
            }

            // Storage bar
            ResourceBar {
                Layout.fillWidth: true
                icon: "hard_drive_2"
                usage: SystemUsage.storagePerc
                barColor: Colours.palette.m3outline
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Ring Gauge Component (using CircularProgress)
    // ═══════════════════════════════════════════════════
    component RingGauge: Item {
        id: gauge

        required property string name
        required property real usage
        required property real temp
        required property color gaugeColor

        implicitWidth: 100
        implicitHeight: 100

        // Using CircularProgress instead of Canvas
        CircularProgress {
            anchors.fill: parent
            value: gauge.usage
            padding: 8
            strokeWidth: 10
            fgColour: gauge.gaugeColor
            bgColour: Colours.palette.m3surfaceContainerHighest
        }

        // Center text
        Column {
            anchors.centerIn: parent
            spacing: -2

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(gauge.usage * 100) + "%"
                font.pointSize: Appearance.font.size.normal
                font.weight: 600
                color: gauge.gaugeColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.name
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
            }
        }

        // Temp badge
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 0
            width: tempText.width + 8
            height: 16
            radius: 8
            color: Colours.palette.m3surfaceContainerHigh

            StyledText {
                id: tempText
                anchors.centerIn: parent
                text: Math.round(gauge.temp) + "°"
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Resource Bar Component
    // ═══════════════════════════════════════════════════
    component ResourceBar: Rectangle {
        id: bar

        required property string icon
        required property real usage
        required property color barColor

        implicitHeight: 28
        radius: 8
        color: Colours.palette.m3surfaceContainerHigh

        Row {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 8

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: bar.icon
                font.pointSize: Appearance.font.size.normal
                color: bar.barColor
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - parent.spacing - Appearance.font.size.normal * 1.5
                height: 12
                radius: 6
                color: Colours.palette.m3surfaceContainerHighest

                Rectangle {
                    width: parent.width * bar.usage
                    height: parent.height
                    radius: parent.radius
                    color: bar.barColor

                    Behavior on width {
                        NumberAnimation { duration: 500; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
