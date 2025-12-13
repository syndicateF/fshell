import "../services"
import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property DesktopEntry modelData
    required property int index
    required property PersistentProperties visibilities
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

    Row {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        anchors.topMargin: Appearance.padding.small
        anchors.bottomMargin: Appearance.padding.small
        spacing: Appearance.spacing.normal

        IconImage {
            id: icon

            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: 22

            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.modelData?.name ?? ""
            // EXACT same style as ActiveWindow title
            font.pixelSize: 15
            font.family: Appearance.font.family.sans
            font.hintingPreference: Font.PreferDefaultHinting
            font.variableAxes: ({ "wght": 450, "wdth": 100 })
            color: root.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            width: parent.width - icon.width - parent.spacing

            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
