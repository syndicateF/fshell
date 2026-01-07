pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import QtQuick

/**
 * ProfileIcon - Power profile selection button
 * 
 * Usage:
 *   ProfileIcon {
 *       profile: "balanced"
 *       isActive: Power.platformProfile === profile
 *       onClicked: Power.setPlatformProfile(profile)
 *   }
 */
StyledRect {
    id: root

    required property string profile
    property bool isActive: false

    signal clicked()

    readonly property string icon: {
        switch (profile) {
            case "low-power": return "eco"
            case "balanced": return "balance"
            case "performance": return "bolt"
            default: return "settings"
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
