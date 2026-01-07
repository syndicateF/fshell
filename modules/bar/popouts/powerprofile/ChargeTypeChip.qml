pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * ChargeTypeChip - Charge type selector chip (standard/long-life/express)
 * 
 * Usage:
 *   ChargeTypeChip {
 *       value: "Standard"
 *       isActive: Power.chargeType === value
 *       onClicked: Power.setChargeType(value)
 *   }
 */
StyledRect {
    id: root

    required property string value
    property bool isActive: false

    signal clicked()

    readonly property string displayText: {
        // Replace underscores with spaces and Capitalize
        let s = value.replace(/_/g, " ");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    readonly property string icon: {
        const v = value.toLowerCase();
        if (v.includes("standard") || v.includes("normal")) return "battery_full";
        if (v.includes("long") || v.includes("life") || v.includes("saver") || v.includes("conservation")) return "battery_saver";
        if (v.includes("express") || v.includes("rapid") || v.includes("fast")) return "bolt";
        if (v.includes("trickle")) return "history_toggle_off";
        return "battery_std";
    }

    Layout.fillWidth: true
    implicitHeight: 36
    radius: Appearance.rounding.small
    color: isActive 
        ? Colours.palette.m3tertiaryContainer 
        : Colours.tPalette.m3surfaceContainer

    Behavior on color { ColorAnimation { duration: 150 } }

    StateLayer {
        color: root.isActive 
            ? Colours.palette.m3onTertiaryContainer 
            : Colours.palette.m3onSurface
        disabled: !root.enabled

        function onClicked(): void {
            root.clicked();
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.smaller

        MaterialIcon {
            text: root.icon
            font.pointSize: Appearance.font.size.smaller
            color: root.isActive 
                ? Colours.palette.m3onTertiaryContainer 
                : Colours.palette.m3onSurfaceVariant
            fill: root.isActive ? 1 : 0

            Behavior on fill { NumberAnimation { duration: 150 } }
        }

        StyledText {
            text: root.displayText
            font.pointSize: Appearance.font.size.smaller
            color: root.isActive 
                ? Colours.palette.m3onTertiaryContainer 
                : Colours.palette.m3onSurfaceVariant
        }
    }
}
