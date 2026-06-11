pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Premium Bluetooth Status Widget
// Renders a circular button that changes color and icon depending on adapter state
StyledRect {
    id: root

    required property Item bar
    required property var popouts

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: Config.bar.sizes.innerWidth
    radius: Config.border.rounding
    color: Colours.tPalette.m3surfaceContainer
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3outline, 0.08)
    clip: true

    readonly property bool isEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool hasConnected: Bluetooth.devices.values.some(d => d.connected)

    MaterialIcon {
        id: icon
        anchors.centerIn: parent
        text: {
            if (!root.isEnabled)
                return "bluetooth_disabled";
            if (root.hasConnected)
                return "bluetooth_connected";
            return "bluetooth";
        }
        color: root.isEnabled ? Colours.palette.m3primary : Colours.palette.m3outline
        font.pointSize: Config.bar.sizes.font.materialIcon
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            popouts.currentName = "bluetooth"
            popouts.currentCenter = root.mapToItem(bar, 0, root.height / 2).y
            popouts.hasCurrent = !popouts.hasCurrent
        }
    }
}
