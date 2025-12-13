import qs.components
import qs.components.images
import qs.components.effects
import qs.services
import qs.config
import Caelestia.Models
import Quickshell
import QtQuick

Item {
    id: root

    required property FileSystemEntry modelData
    required property int index
    required property PersistentProperties visibilities
    required property var panels
    required property var content
    required property bool isSelected

    signal clicked()
    signal hovered()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
        onEntered: root.hovered()
    }

    Column {
        anchors.fill: parent
        anchors.margins: Appearance.padding.smaller
        spacing: Appearance.spacing.small

        StyledClippingRect {
            id: image

            anchors.horizontalCenter: parent.horizontalCenter
            color: Colours.tPalette.m3surfaceContainer
            radius: Appearance.rounding.small

            width: parent.width
            height: width / 16 * 9

            MaterialIcon {
                anchors.centerIn: parent
                text: "image"
                color: Colours.tPalette.m3outline
                font.pointSize: Appearance.font.size.normal
                font.weight: 600
            }

            CachingImage {
                path: root.modelData.path
                smooth: true

                anchors.fill: parent
            }
        }

        StyledText {
            id: label

            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.modelData.relativePath
            font.pointSize: Appearance.font.size.small
            font.weight: root.isSelected ? Font.Medium : Font.Normal
            color: root.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
        }
    }
}
