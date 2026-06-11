import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

StyledRect {
    id: root

    required property PersistentProperties visibilities

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3outline, 0.08)

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: icon.implicitHeight + Config.bar.sizes.itemPadding * 2

    StateLayer {
        anchors.fill: parent
        radius: root.radius

        function onClicked(): void {
            root.visibilities.fullscreenSession = !root.visibilities.fullscreenSession;
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -1

        text: "power_settings_new"
        color: Colours.palette.m3error
        font.bold: true
        font.pointSize: Config.bar.sizes.font.materialIcon
    }
}
