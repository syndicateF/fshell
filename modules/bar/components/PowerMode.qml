pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell.Services.UPower
import QtQuick

// PowerMode - icon mode + title status (vertical style, dengan popout)
StyledRect {
    id: root

    // Tokyo Night color scheme
    readonly property color colour: {
        const charging = [
            UPowerDeviceState.Charging,
            UPowerDeviceState.FullyCharged,
            UPowerDeviceState.PendingCharge
        ].includes(UPower.displayDevice.state);
        const pct = UPower.displayDevice.percentage * 100;
        
        // Tokyo Night colors
        if (charging) return "#9ece6a";  // Tokyo Night Green
        if (pct <= 20) return "#f7768e";  // Tokyo Night Red/Pink (critical)
        if (pct <= 100) return "#7aa2f7";  // Tokyo Night Blue (normal discharge)
        return Colours.palette.m3onSurface;  // Neutral (fallback)
    }

    // Current mode info
    readonly property string currentIcon: {
        const p = PowerProfiles.profile;
        if (p === PowerProfile.PowerSaver)
            return "energy_savings_leaf";
        if (p === PowerProfile.Performance)
            return "rocket_launch";
        return "balance";
    }
    
    readonly property string currentLabel: {
        const p = PowerProfiles.profile;
        if (p === PowerProfile.PowerSaver)
            return "Powersave";
        if (p === PowerProfile.Performance)
            return "Performance";
        return "Balanced";
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding
    
    clip: true
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: content.implicitHeight + Config.bar.sizes.itemPadding * 2

    Column {
        id: content
        anchors.centerIn: parent
        spacing: Appearance.spacing.smaller

        // Mode icon
        MaterialIcon {
            id: modeIcon
            anchors.horizontalCenter: parent.horizontalCenter
            animate: true
            text: root.currentIcon
            color: root.colour
            font.pointSize: Config.bar.sizes.font.materialIcon
            fill: 1
            
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // Mode label - rotated for vertical bar
        Item {
            id: labelContainer
            anchors.horizontalCenter: parent.horizontalCenter
            width: modeLabel.implicitHeight
            height: Math.min(modeLabel.implicitWidth, 100)
            
            Text {
                id: modeLabel
                text: root.currentLabel
                font.pointSize: Config.bar.sizes.font.powerModeLabel
                font.family: Appearance.font.family.sans
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes: ({ "wght": Config.bar.sizes.textWeight, "wdth": Config.bar.sizes.textWidth })
                color: root.colour
                renderType: Text.NativeRendering
                
                Behavior on color { ColorAnimation { duration: 300 } }
                
                transform: [
                    Rotation {
                        angle: 90
                        origin.x: modeLabel.implicitHeight / 2
                        origin.y: modeLabel.implicitHeight / 2
                    }
                ]
            }
        }
    }
}
