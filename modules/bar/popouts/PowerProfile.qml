pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "powerprofile" as PowerProfile

/**
 * Power Profile Popout - Orchestrator
 * 
 * Composes:
 * - BatteryStatusCard (health + time remaining)
 * - SafeModeWarning (error banner)
 * - ProfileIcon/GovernorIcon (profile selection)
 * - EppChip (energy preference)
 * - ChargeTypeChip (charge type selection)
 */
ColumnLayout {
    id: root

    required property Item wrapper

    // Computed properties for UPower
    readonly property bool isCharging: [
        UPowerDeviceState.Charging,
        UPowerDeviceState.FullyCharged,
        UPowerDeviceState.PendingCharge
    ].includes(UPower.displayDevice.state)
    readonly property int batteryPercent: Math.round(UPower.displayDevice.percentage * 100)

    spacing: Appearance.spacing.small

    property real shimmerOpacity: 1.0
    
    SequentialAnimation on shimmerOpacity {
        running: Power._busy
        loops: Animation.Infinite
        alwaysRunToEnd: false
        NumberAnimation { from: 1.0; to: 0.5; duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 0.5; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
    }
    
    // Reset opacity when not busy
    Behavior on shimmerOpacity {
        enabled: !Power._busy
        NumberAnimation { to: 1.0; duration: 150 }
    }

    // ═══════════════════════════════════════════════════
    // iOS Drag Handle (clickable to open panel)
    // ═══════════════════════════════════════════════════
    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 48
        implicitHeight: 16

        Rectangle {
            anchors.centerIn: parent
            width: 36
            height: 4
            radius: 2
            color: Colours.palette.m3outlineVariant
        }

        StateLayer {
            radius: Appearance.rounding.small

            function onClicked(): void {
                root.wrapper.detach("power");
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Battery Status Card
    // ═══════════════════════════════════════════════════
    PowerProfile.BatteryStatusCard {
        visible: Power.batteryAvailable
        isCharging: root.isCharging
        batteryPercent: root.batteryPercent
        healthPercent: Power.batteryInfo.healthPercent
        timeRemaining: root.isCharging 
            ? UPower.displayDevice.timeToFull 
            : UPower.displayDevice.timeToEmpty
    }

    // ═══════════════════════════════════════════════════
    // Safe Mode Warning
    // ═══════════════════════════════════════════════════
    PowerProfile.SafeModeWarning {
        active: Power.safeModeActive
    }

    // ═══════════════════════════════════════════════════
    // Profile Section
    // ═══════════════════════════════════════════════════
    PowerProfile.SectionHeader {
        visible: Power.availableProfiles && Power.availableProfiles.length > 0
        text: {
            switch (Power.platformProfile) {
                case "low-power": return qsTr("Power Saver")
                case "balanced": return qsTr("Balanced")
                case "performance": return qsTr("Performance")
                case "custom": return qsTr("Custom")
                default: return Power.platformProfile
            }
        }
    }

    RowLayout {
        visible: Power.availableProfiles && Power.availableProfiles.length > 0
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal
        opacity: root.shimmerOpacity

        Repeater {
            model: Power.availableProfiles.filter(p => p !== "custom")

            PowerProfile.ProfileIcon {
                required property string modelData
                required property int index

                Layout.fillWidth: true
                profile: modelData
                isActive: Power.platformProfile === modelData
                enabled: !Power._busy && !Power.safeModeActive

                onClicked: Power.setPlatformProfile(modelData)
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Governor Fallback (when Platform Profile NOT available)
    // ═══════════════════════════════════════════════════
    PowerProfile.SectionHeader {
        visible: (!Power.availableProfiles || Power.availableProfiles.length === 0) && Power.availableGovernors.length > 0
        text: {
            switch (Power.cpuGovernor) {
                case "powersave": return qsTr("Saver")
                case "performance": return qsTr("Performance")
                default: return Power.cpuGovernor
            }
        }
    }

    RowLayout {
        visible: (!Power.availableProfiles || Power.availableProfiles.length === 0) && Power.availableGovernors.length > 0
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal
        opacity: root.shimmerOpacity

        Repeater {
            model: Power.availableGovernors

            PowerProfile.GovernorIcon {
                required property string modelData
                required property int index

                Layout.fillWidth: true
                governor: modelData
                isActive: Power.cpuGovernor === modelData
                enabled: !Power._busy && !Power.safeModeActive

                onClicked: Power.setGovernor(modelData)
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // EPP Section (if available)
    // ═══════════════════════════════════════════════════
    PowerProfile.SectionHeader {
        visible: Power.eppAvailable && Power.eppControllable
        text: qsTr("Energy Preference")
    }

    GridLayout {
        visible: Power.eppAvailable && Power.eppControllable
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Appearance.spacing.smaller
        columnSpacing: Appearance.spacing.smaller
        opacity: root.shimmerOpacity

        Repeater {
            model: Power.availableEpp

            PowerProfile.EppChip {
                required property string modelData
                required property int index

                value: modelData
                isActive: Power.epp === modelData
                enabled: !Power._busy && !Power.safeModeActive

                onClicked: Power.setEpp(modelData)
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Charge Type Section (if available)
    // ═══════════════════════════════════════════════════
    PowerProfile.SectionHeader {
        visible: Power.chargeTypeWritable
        text: qsTr("Charge type")
    }

    GridLayout {
        visible: Power.chargeTypeWritable
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Appearance.spacing.smaller
        columnSpacing: Appearance.spacing.smaller
        opacity: root.shimmerOpacity

        Repeater {
            model: Power.availableChargeTypes

            PowerProfile.ChargeTypeChip {
                required property string modelData
                required property int index

                value: modelData
                isActive: Power.chargeType === modelData
                enabled: !Power._busy && !Power.safeModeActive

                onClicked: Power.setChargeType(modelData)
            }
        }
    }
}
