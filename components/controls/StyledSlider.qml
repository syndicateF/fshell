import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Templates

Slider {
    id: root

    implicitHeight: 28
    implicitWidth: 200

    background: Item {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        // Track background (unfilled part) - FULL WIDTH
        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            
            implicitHeight: root.implicitHeight / 4

            color: Colours.palette.m3surfaceContainerHighest
            radius: Appearance.rounding.full
        }

        // Filled/Active part (from left to handle position)
        StyledRect {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            
            // Width should be from left edge to center of handle
            // At position 0, this should be minimal (just show a tiny bit or nothing)
            implicitWidth: Math.max(0, root.handle.x + root.handle.width / 2)
            implicitHeight: root.implicitHeight / 4
            visible: implicitWidth > 0

            color: Colours.palette.m3primary
            radius: Appearance.rounding.full
        }
    }

    handle: StyledRect {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2

        // Original elongated pill thumb
        implicitWidth: root.implicitHeight / 4.5
        implicitHeight: root.implicitHeight

        color: Colours.palette.m3primary
        radius: Appearance.rounding.full

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }
}
