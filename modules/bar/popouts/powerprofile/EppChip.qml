pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * EppChip - Energy Performance Preference selector chip
 * 
 * Usage:
 *   EppChip {
 *       value: "balance_performance"
 *       isActive: Power.epp === value
 *       onClicked: Power.setEpp(value)
 *   }
 */
StyledRect {
    id: root

    required property string value
    property bool isActive: false

    signal clicked()

    readonly property string displayText: {
        switch (value) {
            case "default": return qsTr("Default")
            case "performance": return qsTr("Performance")
            case "balance_performance": return qsTr("Bal. Perf")
            case "balance_power": return qsTr("Bal. Power")
            case "power": return qsTr("Power Saver")
            default: return value
        }
    }

    readonly property string icon: {
        switch (value) {
            case "default": return "settings_suggest"
            case "performance": return "bolt"
            case "balance_performance": return "speed"
            case "balance_power": return "eco"
            case "power": return "battery_saver"
            default: return "tune"
        }
    }

    Layout.fillWidth: true
    implicitHeight: 36
    radius: Appearance.rounding.small
    color: isActive 
        ? Colours.palette.m3secondaryContainer 
        : Colours.tPalette.m3surfaceContainer

    Behavior on color { ColorAnimation { duration: 150 } }

    StateLayer {
        color: root.isActive 
            ? Colours.palette.m3onSecondaryContainer 
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
                ? Colours.palette.m3onSecondaryContainer 
                : Colours.palette.m3onSurfaceVariant
            fill: root.isActive ? 1 : 0

            Behavior on fill { NumberAnimation { duration: 150 } }
        }

        StyledText {
            text: root.displayText
            font.pointSize: Appearance.font.size.smaller
            color: root.isActive 
                ? Colours.palette.m3onSecondaryContainer 
                : Colours.palette.m3onSurfaceVariant
        }
    }
}
