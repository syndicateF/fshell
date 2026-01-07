pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import QtQuick

/**
 * GovernorIcon - CPU governor selection button (fallback when platform profiles unavailable)
 * 
 * Usage:
 *   GovernorIcon {
 *       governor: "powersave"
 *       isActive: Power.cpuGovernor === governor
 *       onClicked: Power.setGovernor(governor)
 *   }
 */
StyledRect {
    id: root

    required property string governor
    property bool isActive: false

    signal clicked()

    readonly property string icon: {
        switch (governor) {
            case "powersave": return "eco"
            case "performance": return "bolt"
            default: return "speed"
        }
    }

    implicitWidth: 44
    implicitHeight: 44
    radius: Appearance.rounding.small
    
    color: isActive 
        ? Colours.palette.m3primary
        : Colours.tPalette.m3surfaceContainer

    Behavior on color { ColorAnimation { duration: 150 } }

    StateLayer {
        color: root.isActive 
            ? Colours.palette.m3onPrimary 
            : Colours.palette.m3onSurface
        disabled: !root.enabled

        function onClicked(): void {
            root.clicked();
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        font.pointSize: Appearance.font.size.larger
        color: root.isActive 
            ? Colours.palette.m3onPrimary
            : Colours.palette.m3onSurfaceVariant
        fill: root.isActive ? 1 : 0

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on fill { NumberAnimation { duration: 150 } }
    }
}
