pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Power Profile popout for bar - redesigned with segmented buttons and grid pills
Item {
    id: root

    required property var wrapper

    implicitWidth: layout.implicitWidth + Appearance.padding.normal - Config.border.thickness
    implicitHeight: layout.implicitHeight + Appearance.padding.normal

    // Busy state shimmer overlay
    opacity: Power._busy ? 0.7 : 1.0
    
    SequentialAnimation on opacity {
        running: Power._busy
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation { from: 0.7; to: 0.5; duration: 400; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 0.5; to: 0.7; duration: 400; easing.type: Easing.InOutQuad }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        // Battery Section - compact row with health and Long Life toggle
        RowLayout {
            Layout.fillWidth: true
            visible: Power.batteryAvailable
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: "battery_full"
                color: Power.batteryInfo.healthPercent > 50 ? Colours.palette.m3primary : Colours.palette.m3error
            }

            StyledText {
                text: qsTr("Battery")
                font.weight: 500
            }

            StyledText {
                text: Power.batteryInfo.healthPercent >= 0 
                    ? Math.round(Power.batteryInfo.healthPercent) + "%" 
                    : "--"
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            Item { Layout.fillWidth: true }

            // Long Life toggle (only if writable)
            RowLayout {
                visible: Power.chargeTypeWritable
                spacing: Appearance.spacing.small

                StyledText {
                    text: qsTr("Long Life")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3outline
                }

                StyledSwitch {
                    checked: Power.chargeType === "Long_Life"
                    onClicked: Power.setChargeType(checked ? "Long_Life" : "Standard")
                    enabled: !Power._busy && !Power.safeModeActive
                }
            }
        }

        // Divider between battery and power controls
        Rectangle {
            Layout.fillWidth: true
            visible: Power.batteryAvailable
            height: 1
            color: Colours.palette.m3outlineVariant
            opacity: 0.3
        }

        // Platform Profile section header
        StyledText {
            text: qsTr("Platform Profile")
            font.weight: 500
        }

        // Custom indicator (read-only, when firmware/tools modified profile)
        StyledRect {
            Layout.fillWidth: true
            visible: Power.platformProfile === "custom"
            implicitHeight: customRow.implicitHeight + Appearance.padding.small * 2
            radius: Appearance.rounding.small
            color: Colours.palette.m3tertiaryContainer

            RowLayout {
                id: customRow
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "tune"
                    color: Colours.palette.m3onTertiaryContainer
                    font.pointSize: Appearance.font.size.small
                }

                StyledText {
                    text: qsTr("Custom (firmware/tools)")
                    color: Colours.palette.m3onTertiaryContainer
                    font.pointSize: Appearance.font.size.small
                }
            }
        }

        // Platform Profile - Icon-only pills with sliding background
        Item {
            id: profileContainer
            
            readonly property var profiles: Power.availableProfiles.filter(p => p !== "custom")
            readonly property int activeIndex: profiles.indexOf(Power.platformProfile)
            readonly property int profileCount: profiles.length
            
            // Uniform segment size (square for icon-only)
            readonly property real segmentSize: Appearance.font.size.larger + Appearance.padding.normal * 2
            // Horizontal spacing between segments
            readonly property real segmentSpacing: Appearance.spacing.large * 2
            
            implicitWidth: (segmentSize * profileCount) + (segmentSpacing * (profileCount - 1))
            implicitHeight: segmentSize

            // Background track
            StyledRect {
                anchors.fill: parent
                radius: Appearance.rounding.full
                color: Colours.palette.m3surfaceContainerHigh
            }

            // Sliding active background
            StyledRect {
                id: activeIndicator
                
                visible: profileContainer.activeIndex >= 0
                
                // Position calculation: (size + spacing) * index
                x: profileContainer.activeIndex >= 0 
                    ? profileContainer.activeIndex * (profileContainer.segmentSize + profileContainer.segmentSpacing)
                    : 0
                
                implicitWidth: profileContainer.segmentSize
                implicitHeight: profileContainer.segmentSize
                
                radius: Appearance.rounding.full
                color: Colours.palette.m3primary
                
                Behavior on x {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
            }

            Row {
                id: profileRow
                anchors.fill: parent
                spacing: profileContainer.segmentSpacing

                Repeater {
                    id: profileRepeater
                    model: profileContainer.profiles

                    ProfileSegment {
                        required property string modelData
                        required property int index

                        profile: modelData
                        isActive: Power.platformProfile === modelData
                        segmentSize: profileContainer.segmentSize
                        enabled: !Power._busy && !Power.safeModeActive
                        onClicked: Power.setPlatformProfile(modelData)
                    }
                }
            }
        }

        // EPP section header (hidden when not controllable)
        StyledText {
            Layout.topMargin: Appearance.spacing.normal
            visible: Power.eppControllable
            text: qsTr("Energy Preference")
            font.weight: 500
        }

        // EPP - 2-column Grid Pills with icons (vertical center aligned)
        GridLayout {
            visible: Power.eppControllable
            columns: 2
            rowSpacing: Appearance.spacing.small
            columnSpacing: Appearance.spacing.small
            
            Repeater {
                model: Power.availableEpp

                EppChip {
                    required property string modelData

                    value: modelData
                    isActive: Power.epp === modelData
                    enabled: !Power._busy && !Power.safeModeActive
                    onClicked: Power.setEpp(modelData)
                }
            }
        }

        // Safe mode warning
        StyledRect {
            Layout.topMargin: Appearance.spacing.normal
            Layout.fillWidth: true
            visible: Power.safeModeActive
            implicitHeight: safeRow.implicitHeight + Appearance.padding.small * 2
            radius: Appearance.rounding.small
            color: Colours.palette.m3errorContainer

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

        // Open panel button
        StyledRect {
            Layout.topMargin: Appearance.spacing.small
            implicitWidth: expandBtn.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: expandBtn.implicitHeight + Appearance.padding.small

            radius: Appearance.rounding.normal
            color: Colours.palette.m3primaryContainer

            StateLayer {
                color: Colours.palette.m3onPrimaryContainer

                function onClicked(): void {
                    root.wrapper.detach("power");
                }
            }

            RowLayout {
                id: expandBtn

                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.leftMargin: Appearance.padding.smaller
                    text: qsTr("Open panel")
                    color: Colours.palette.m3onPrimaryContainer
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onPrimaryContainer
                    font.pointSize: Appearance.font.size.large
                }
            }
        }
    }

    // =====================================================
    // INLINE COMPONENTS
    // =====================================================

    // Platform Profile segment - icon only, transparent bg (active indicator is separate)
    component ProfileSegment: Item {
        id: segment

        required property string profile
        property bool isActive: false
        property real segmentSize: 40

        signal clicked()

        readonly property string icon: {
            switch (profile) {
                case "performance": return "bolt";
                case "low-power": return "eco";
                case "balanced": return "balance";
                default: return "settings";
            }
        }

        implicitWidth: segmentSize
        implicitHeight: segmentSize

        StateLayer {
            radius: Appearance.rounding.full
            color: segment.isActive ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            disabled: !segment.enabled

            function onClicked(): void {
                segment.clicked();
            }
        }

        MaterialIcon {
            id: iconItem
            anchors.centerIn: parent
            text: segment.icon
            color: segment.isActive ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.larger
            fill: segment.isActive ? 1 : 0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on fill { NumberAnimation { duration: 150 } }
        }
    }

    // EPP Chip (pill button with icon + label, vertical center aligned)
    component EppChip: StyledRect {
        id: chip

        required property string value
        property bool isActive: false

        signal clicked()

        readonly property string displayText: {
            switch (value) {
                case "default": return qsTr("Default");
                case "performance": return qsTr("Performance");
                case "balance_performance": return qsTr("Bal. Perf");
                case "balance_power": return qsTr("Bal. Power");
                case "power": return qsTr("Power Saver");
                default: return value;
            }
        }

        readonly property string icon: {
            switch (value) {
                case "default": return "settings_suggest";
                case "performance": return "bolt";
                case "balance_performance": return "speed";
                case "balance_power": return "eco";
                case "power": return "battery_saver";
                default: return "tune";
            }
        }

        implicitWidth: 130 + Appearance.padding.normal * 2
        implicitHeight: chipContent.implicitHeight + Appearance.padding.small * 2

        // Active = smaller radius (rounded rect), inactive = full radius (pill)
        radius: isActive ? Appearance.rounding.full : 8
        color: isActive ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh

        StateLayer {
            color: chip.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            disabled: !chip.enabled

            function onClicked(): void {
                chip.clicked();
            }
        }

        // Content aligned to left (vertical center, not horizontal center)
        RowLayout {
            id: chipContent
            anchors.left: parent.left
            anchors.leftMargin: Appearance.padding.normal
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                text: chip.icon
                color: chip.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
                fill: chip.isActive ? 1 : 0

                Behavior on fill { NumberAnimation { duration: 150 } }
            }

            StyledText {
                text: chip.displayText
                color: chip.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.small
                font.weight: chip.isActive ? 500 : 400
            }
        }

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on radius { NumberAnimation { duration: 150 } }
    }
}
