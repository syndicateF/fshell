pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Item wrapper

    // Refresh power data when popout is created (Clean Architecture)
    Component.onCompleted: Power.refresh()

    // Computed properties for UPower
    readonly property bool isCharging: [
        UPowerDeviceState.Charging,
        UPowerDeviceState.FullyCharged,
        UPowerDeviceState.PendingCharge
    ].includes(UPower.displayDevice.state)
    readonly property int batteryPercent: Math.round(UPower.displayDevice.percentage * 100)

    spacing: Appearance.spacing.small

    // Busy state shimmer effect - on separate property to not affect text
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
    // Status Card (Battery info)
    // ═══════════════════════════════════════════════════
    StyledRect {
        Layout.fillWidth: true
        visible: Power.batteryAvailable
        implicitWidth: 280
        implicitHeight: statusContent.height + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainerHigh

        ColumnLayout {
            id: statusContent
            width: parent.width - Appearance.padding.normal * 2
            x: Appearance.padding.normal
            y: Appearance.padding.normal
            spacing: Appearance.spacing.small

            // Header row
            RowLayout {
                width: parent.width
                spacing: Appearance.spacing.normal

                // Battery icon with background
                StyledRect {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: Appearance.rounding.small
                    color: root.isCharging 
                        ? Qt.alpha(Colours.palette.m3primary, 0.2)
                        : Qt.alpha(Colours.palette.m3tertiary, 0.2)

                    Behavior on color { ColorAnimation { duration: 200 } }

                    // MaterialIcon {
                    //     anchors.centerIn: parent
                    //     text: root.isCharging ? "bolt" : "battery_full"
                    //     font.pointSize: Appearance.font.size.normal
                    //     color: root.isCharging ? Colours.palette.m3primary : Colours.palette.m3tertiary
                    // }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "favorite"
                        font.pointSize: Appearance.font.size.small
                        // color: Colours.palette.m3primary
                        color: root.isCharging ? Colours.palette.m3primary : Colours.palette.m3tertiary
                        fill: 1
                    }

                }

                ColumnLayout {
                    spacing: 0

                    // StyledText {
                    //     text: qsTr("Power")
                    //     font.weight: 600
                    // }
                    StyledText {
                        text: "Health " + Math.round(Power.batteryInfo.healthPercent) + "%"
                        // font.pointSize: 8
                        font.weight: 600
                        // color: Colours.palette.m3primary
                    }
                    StyledText {
                        readonly property int timeRemaining: root.isCharging 
                            ? UPower.displayDevice.timeToFull 
                            : UPower.displayDevice.timeToEmpty

                        text: {
                            if (timeRemaining <= 0) {
                                return root.isCharging ? qsTr("Calculating...") : qsTr("Unknown");
                            }
                            const hours = Math.floor(timeRemaining / 3600);
                            const minutes = Math.floor((timeRemaining % 3600) / 60);
                            if (hours > 0) {
                                return qsTr("%1h %2m %3").arg(hours).arg(minutes).arg(root.isCharging ? qsTr("to full") : qsTr("remaining"));
                            }
                            return qsTr("%1m %2").arg(minutes).arg(root.isCharging ? qsTr("to full") : qsTr("remaining"));
                        }
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                    }
                }

                // Item { Layout.fillWidth: true }
            }

            // Battery progress bar
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Colours.palette.m3surfaceContainerHighest

                Rectangle {
                    width: parent.width * (root.batteryPercent / 100)
                    height: parent.height
                    radius: 3
                    color: root.isCharging ? Colours.palette.m3primary : Colours.palette.m3tertiary

                    Behavior on width { NumberAnimation { duration: 300 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Safe Mode Warning
    // ═══════════════════════════════════════════════════
    StyledRect {
        visible: opacity > 0
        Layout.fillWidth: true
        implicitHeight: safeRow.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3errorContainer

        opacity: Power.safeModeActive ? 1 : 0
        scale: Power.safeModeActive ? 1 : 0.9

        Behavior on opacity { Anim {} }
        Behavior on scale { Anim {} }

        RowLayout {
            id: safeRow
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: "warning"
                color: Colours.palette.m3onErrorContainer
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                text: qsTr("Safe mode active")
                color: Colours.palette.m3onErrorContainer
                font.pointSize: Appearance.font.size.small
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // Profile Section Header
    // ═══════════════════════════════════════════════════
    RowLayout {
        visible: Power.availableProfiles && Power.availableProfiles.length > 0
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Rectangle { Layout.fillWidth: true; height: 0.5; color: Colours.palette.m3outlineVariant }
        
        StyledText {
            text: {
                switch (Power.platformProfile) {
                    case "low-power": return qsTr("Power Saver")
                    case "balanced": return qsTr("Balanced")
                    case "performance": return qsTr("Performance")
                    case "custom": return qsTr("Custom")
                    default: return Power.platformProfile
                }
            }
            font.pointSize: Appearance.font.size.small
            // color: Colours.palette.m3tertiary
        }
        
        Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant }
    }

    // ═══════════════════════════════════════════════════
    // Profile Icons Row (horizontal, icon-only)
    // ═══════════════════════════════════════════════════
    RowLayout {
        visible: Power.availableProfiles && Power.availableProfiles.length > 0
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal
        opacity: root.shimmerOpacity

        Repeater {
            model: Power.availableProfiles.filter(p => p !== "custom")

            ProfileIcon {
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
    // GOVERNOR FALLBACK (shown when Platform Profile NOT available)
    // ═══════════════════════════════════════════════════
    RowLayout {
        visible: (!Power.availableProfiles || Power.availableProfiles.length === 0) && Power.availableGovernors.length > 0
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Rectangle { Layout.fillWidth: true; height: 0.5; color: Colours.palette.m3outlineVariant }
        
        StyledText {
            text: {
                switch (Power.cpuGovernor) {
                    case "powersave": return qsTr("Saver")
                    case "performance": return qsTr("Performance")
                    default: return Power.cpuGovernor
                }
            }
            font.pointSize: Appearance.font.size.small
        }
        
        Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant }
    }

    RowLayout {
        visible: (!Power.availableProfiles || Power.availableProfiles.length === 0) && Power.availableGovernors.length > 0
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal
        opacity: root.shimmerOpacity

        Repeater {
            model: Power.availableGovernors

            GovernorIcon {
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
    // EPP Section Header (HIDDEN if EPP not available)
    // ═══════════════════════════════════════════════════
    RowLayout {
        visible: Power.eppAvailable && Power.eppControllable
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant }
        StyledText {
            text: qsTr("Energy Preference")
            font.pointSize: Appearance.font.size.small
            // color: Colours.palette.m3tertiary
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant }
    }

    // ═══════════════════════════════════════════════════
    // EPP Grid (HIDDEN if EPP not available)
    // ═══════════════════════════════════════════════════
    GridLayout {
        visible: Power.eppAvailable && Power.eppControllable
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Appearance.spacing.smaller
        columnSpacing: Appearance.spacing.smaller
        opacity: root.shimmerOpacity

        Repeater {
            model: Power.availableEpp

            EppChip {
                required property string modelData
                required property int index

                value: modelData
                isActive: Power.epp === modelData
                enabled: !Power._busy && !Power.safeModeActive

                onClicked: Power.setEpp(modelData)
            }
        }
    }
    RowLayout {
        visible: Power.chargeTypeWritable
        spacing: Appearance.spacing.small

        Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant }
        StyledText {
            text: qsTr("Charge type")
            font.pointSize: Appearance.font.size.small
            // color: Colours.palette.m3tertiary
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant }
    }
    // ═══════════════════════════════════════════════════
    // Long Life Mode Card
    // ═══════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════
    // Charge Type Grid (Dynamic)
    // ═══════════════════════════════════════════════════
    GridLayout {
        visible: Power.chargeTypeWritable
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Appearance.spacing.smaller
        columnSpacing: Appearance.spacing.smaller
        opacity: root.shimmerOpacity

        Repeater {
            model: Power.availableChargeTypes

            ChargeTypeChip {
                required property string modelData
                required property int index

                value: modelData
                isActive: Power.chargeType === modelData
                enabled: !Power._busy && !Power.safeModeActive

                onClicked: Power.setChargeType(modelData)
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // INLINE COMPONENTS
    // ═══════════════════════════════════════════════════

    // Profile icon button (horizontal row, icon-only)
    component ProfileIcon: StyledRect {
        id: profileIcon

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
        
        // Solid primary bg when active, surface when inactive
        color: isActive 
            ? Colours.palette.m3primary
            : Colours.palette.m3surfaceContainerHigh

        Behavior on color { ColorAnimation { duration: 150 } }

        StateLayer {
            color: profileIcon.isActive 
                ? Colours.palette.m3onPrimary 
                : Colours.palette.m3onSurface
            disabled: !profileIcon.enabled

            function onClicked(): void {
                profileIcon.clicked();
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: profileIcon.icon
            font.pointSize: Appearance.font.size.larger
            // Bright icon color when active
            color: profileIcon.isActive 
                ? Colours.palette.m3onPrimary
                : Colours.palette.m3onSurfaceVariant
            fill: profileIcon.isActive ? 1 : 0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on fill { NumberAnimation { duration: 150 } }
        }
    }

    // EPP Chip
    component EppChip: StyledRect {
        id: eppChip

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
            : Colours.palette.m3surfaceContainerHigh

        Behavior on color { ColorAnimation { duration: 150 } }

        StateLayer {
            color: eppChip.isActive 
                ? Colours.palette.m3onSecondaryContainer 
                : Colours.palette.m3onSurface
            disabled: !eppChip.enabled

            function onClicked(): void {
                eppChip.clicked();
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                text: eppChip.icon
                font.pointSize: Appearance.font.size.smaller
                color: eppChip.isActive 
                    ? Colours.palette.m3onSecondaryContainer 
                    : Colours.palette.m3onSurfaceVariant
                fill: eppChip.isActive ? 1 : 0

                Behavior on fill { NumberAnimation { duration: 150 } }
            }

            StyledText {
                text: eppChip.displayText
                font.pointSize: Appearance.font.size.smaller
                color: eppChip.isActive 
                    ? Colours.palette.m3onSecondaryContainer 
                    : Colours.palette.m3onSurfaceVariant
            }
        }
    }
    
    // Charge Type Chip
    component ChargeTypeChip: StyledRect {
        id: ctChip

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
            : Colours.palette.m3surfaceContainerHigh

        Behavior on color { ColorAnimation { duration: 150 } }

        StateLayer {
            color: ctChip.isActive 
                ? Colours.palette.m3onTertiaryContainer 
                : Colours.palette.m3onSurface
            disabled: !ctChip.enabled

            function onClicked(): void {
                ctChip.clicked();
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                text: ctChip.icon
                font.pointSize: Appearance.font.size.smaller
                color: ctChip.isActive 
                    ? Colours.palette.m3onTertiaryContainer 
                    : Colours.palette.m3onSurfaceVariant
                fill: ctChip.isActive ? 1 : 0

                Behavior on fill { NumberAnimation { duration: 150 } }
            }

            StyledText {
                text: ctChip.displayText
                font.pointSize: Appearance.font.size.smaller
                color: ctChip.isActive 
                    ? Colours.palette.m3onTertiaryContainer 
                    : Colours.palette.m3onSurfaceVariant
            }
        }
    }
    
    // GovernorIcon - for fallback when Platform Profile is not available
    component GovernorIcon: StyledRect {
        id: govIcon

        required property string governor
        property bool isActive: false
        property bool enabled: true

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
            : Colours.palette.m3surfaceContainerHigh

        Behavior on color { ColorAnimation { duration: 150 } }

        StateLayer {
            color: govIcon.isActive 
                ? Colours.palette.m3onPrimary 
                : Colours.palette.m3onSurface
            disabled: !govIcon.enabled

            function onClicked(): void {
                govIcon.clicked();
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: govIcon.icon
            font.pointSize: Appearance.font.size.larger
            color: govIcon.isActive 
                ? Colours.palette.m3onPrimary
                : Colours.palette.m3onSurfaceVariant
            fill: govIcon.isActive ? 1 : 0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on fill { NumberAnimation { duration: 150 } }
        }
    }
}
