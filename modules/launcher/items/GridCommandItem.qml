import "../services"
import qs.components
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    required property var modelData
    required property int index
    required property var gridContent
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

        MaterialIcon {
            id: icon

            text: root.modelData?.icon ?? ""
            font.pointSize: Config.launcher.sizes.font.gridItemIcon
            color: root.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant

            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.modelData?.name ?? ""
            // EXACT same style as ActiveWindow title
            font.pointSize: Config.launcher.sizes.font.gridItemName
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
