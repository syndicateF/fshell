pragma ComponentBehavior: Bound

import "../services"
import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property var modelData
    required property int index
    required property bool isSelected
    property int iconSize: 56

    signal clicked()
    signal hovered()

    // Hover pill — sized relative to cell
    Rectangle {
        id: bg
        anchors.centerIn: parent
        width:  Math.min(root.width - 8, root.iconSize + 52)
        height: Math.min(root.height - 6, root.iconSize + 64)
        radius: 14

        color: {
            if (mouseArea.pressed)
                return Colours.palette.m3primaryContainer;
            if (root.isSelected || mouseArea.containsMouse)
                return Colours.tPalette.m3primaryContainer;
            return "transparent";
        }
        opacity: {
            if (mouseArea.pressed) return 0.9;
            if (root.isSelected || mouseArea.containsMouse) return 0.55;
            return 0;
        }

        Behavior on color   { CAnim { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.clicked()
    }

    // Gentle scale on hover & press
    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: mouseArea.pressed ? 0.93 : (mouseArea.containsMouse ? 1.04 : 1.0)
        yScale: xScale
        Behavior on xScale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(root.width - 16, root.iconSize + 40)
        spacing: 6

        IconImage {
            source: Quickshell.iconPath(
                (root.modelData?.entry ?? root.modelData)?.icon,
                "application-x-executable")
            implicitSize: root.iconSize
            width:  root.iconSize
            height: root.iconSize
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            width: parent.width
            text: root.modelData?.name ?? ""
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.sans
            color: Colours.palette.m3onSurface
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.NoWrap
        }
    }
}
