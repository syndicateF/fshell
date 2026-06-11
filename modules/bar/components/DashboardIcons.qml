pragma ComponentBehavior: Bound

import qs.components
import qs.components.misc
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

// Unified System Resource Monitor Widget (CPU, GPU, iGPU, RAM)
// Renders circular progress rings stacked vertically inside a single glass container capsule
StyledRect {
    id: root

    required property Item bar
    required property PersistentProperties visibilities
    required property var popouts

    // Keep SystemUsage service active
    Ref {
        service: SystemUsage
    }

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: layout.implicitHeight + Config.bar.sizes.itemPadding * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3outline, 0.08)
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        // CPU gauge
        ResourceGauge {
            type: "cpu"
        }

        // dGPU gauge (Discrete NVIDIA - only if available)
        ResourceGauge {
            visible: SystemUsage.hasDGpu
            type: "dgpu"
        }

        // iGPU gauge (Integrated AMD - only if available)
        ResourceGauge {
            visible: SystemUsage.hasIGpu
            type: "igpu"
        }

        // RAM gauge
        ResourceGauge {
            type: "ram"
        }
    }

    // local component representing a single circular resource gauge
    component ResourceGauge: Item {
        id: gauge

        required property string type

        readonly property real usage: {
            switch (type) {
                case "cpu": return SystemUsage.cpuPerc
                case "dgpu": return SystemUsage.dGpuPerc
                case "igpu": return SystemUsage.iGpuPerc
                case "ram": return SystemUsage.memPerc
                default: return 0.0
            }
        }

        readonly property color barColor: {
            switch (type) {
                case "cpu": return Colours.palette.m3peach
                case "dgpu": return "#29B6F6"
                case "igpu": return "#BA68C8"
                case "ram": return "#7DD3C0"
                default: return Colours.palette.m3primary
            }
        }

        readonly property string iconText: {
            switch (type) {
                case "cpu": return "developer_board"
                case "dgpu": return "sports_esports"
                case "igpu": return "desktop_windows"
                case "ram": return "memory"
                default: return ""
            }
        }

        readonly property bool hovered: mouseArea.containsMouse

        implicitWidth: 28
        implicitHeight: 28

        // Premium scale-up on hover micro-interaction
        scale: hovered ? 1.08 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        // Circular progress ring
        CircularProgress {
            id: progressArc
            anchors.fill: parent
            value: gauge.usage
            strokeWidth: 3
            padding: 0
            spacing: 0
            fgColour: gauge.barColor
            bgColour: Qt.alpha(Colours.palette.m3outline, 0.12)
        }

        // Centered content (Icon & Percentage Text)
        Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height

            // Central Resource Icon (visible normally)
            MaterialIcon {
                id: resourceIcon
                anchors.centerIn: parent
                text: gauge.iconText
                color: gauge.barColor
                font.pointSize: 9

                opacity: gauge.hovered ? 0.0 : 1.0
                scale: gauge.hovered ? 0.8 : 1.0

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
            }

            // Percentage Text (visible on hover)
            Text {
                id: percentText
                anchors.centerIn: parent
                text: Math.round(Math.min(Math.max(gauge.usage, 0), 1) * 100).toString()
                font.pointSize: 7.5
                font.bold: true
                font.family: Appearance.font.family.sans
                color: gauge.barColor
                renderType: Text.NativeRendering

                opacity: gauge.hovered ? 1.0 : 0.0
                scale: gauge.hovered ? 1.0 : 0.8

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                popouts.currentName = "performance"
                popouts.currentCenter = root.mapToItem(bar, 0, root.height / 2).y
                popouts.hasCurrent = !popouts.hasCurrent
            }
        }
    }
}
