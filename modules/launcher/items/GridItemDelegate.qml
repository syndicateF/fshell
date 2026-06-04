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

    signal clicked()
    signal hovered()

    implicitWidth: 96
    implicitHeight: 110

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: {
            if (mouseArea.pressed) return Colours.palette.m3primaryContainer;
            if (root.isSelected || mouseArea.containsMouse) return Colours.tPalette.m3primaryContainer;
            return "transparent";
        }
        Behavior on color { CAnim { duration: Appearance.anim.durations.small } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.clicked()
    }

    Column {
        id: col
        width: root.width
        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        IconImage {
            id: appIcon
            source: Quickshell.iconPath(
                (root.modelData?.entry ?? root.modelData)?.icon,
                "application-x-executable")
            implicitSize: 48
            width: 48
            height: 48
            x: (col.width - 48) / 2
        }

        Text {
            width: col.width
            text: root.modelData?.name ?? ""
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.sans
            color: Colours.palette.m3onSurface
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
    }
}
