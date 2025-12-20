pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    required property Session session
    readonly property bool smallVrr: width <= 400

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.bottomMargin: 0
        spacing: Appearance.spacing.small

        // Header
        RowLayout {
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.smaller

            StyledText {
                text: qsTr("Displays")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            Item { Layout.fillWidth: true }

            // VRR Toggle (Global setting) - disabled if no monitor supports VRR
            ToggleButton {
                toggled: Monitors.globalVrr > 0
                icon: "display_settings"
                label: root.smallVrr ? "" : (Monitors.globalVrr === 0 ? "VRR" : Monitors.globalVrr === 1 ? "VRR On" : "VRR FS")
                accent: Monitors.globalVrr > 0 ? "Tertiary" : "Secondary"
                // Disable if no monitor supports VRR
                enabled: Monitors.anyMonitorSupportsVrr
                opacity: enabled ? 1 : 0.5

                function onClicked(): void {
                    if (!Monitors.anyMonitorSupportsVrr) return;
                    // Cycle through VRR modes: 0 -> 1 -> 2 -> 0
                    const nextVrr = (Monitors.globalVrr + 1) % 3;
                    Monitors.setGlobalVrr(nextVrr);
                }

                ToolTip.visible: !enabled && hovered
                ToolTip.text: qsTr("No monitors with high refresh rate detected")
                ToolTip.delay: 500
            }

            // VSYNC Toggle - inverted allow_tearing (VSYNC ON = tearing OFF)
            ToggleButton {
                toggled: !Monitors.allowTearing
                icon: "sync"
                label: root.smallVrr ? "" : "VSYNC"
                accent: !Monitors.allowTearing ? "Secondary" : "Secondary"

                function onClicked(): void {
                    // Toggle: if VSYNC is on (tearing off), turn off VSYNC (tearing on), and vice versa
                    Monitors.setAllowTearing(!Monitors.allowTearing);
                }
            }

            // Settings toggle - shows GlobalInfo when no monitor selected
            ToggleButton {
                toggled: !Monitors.selectedMonitor
                icon: "settings"
                accent: "Primary"

                function onClicked(): void {
                    if (Monitors.selectedMonitor)
                        Monitors.selectMonitor(null);
                    else {
                        // Select first monitor
                        if (Monitors.monitorCount > 0)
                            Monitors.selectMonitor(Monitors.monitors.values[0]);
                    }
                }
            }
        }

        // Global settings info row
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                text: qsTr("%1 display(s)").arg(Monitors.monitorCount)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }

            Item { Layout.fillWidth: true }

            // VRR status badge
            StyledRect {
                visible: Monitors.globalVrr > 0
                implicitWidth: vrrBadgeRow.implicitWidth + Appearance.padding.small * 2
                implicitHeight: vrrBadgeRow.implicitHeight + 4

                radius: Appearance.rounding.full
                color: Colours.palette.m3tertiaryContainer

                RowLayout {
                    id: vrrBadgeRow
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "display_settings"
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onTertiaryContainer
                    }

                    StyledText {
                        text: Monitors.globalVrr === 1 ? "VRR On" : "VRR Fullscreen"
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3onTertiaryContainer
                    }
                }
            }
        }

        // Monitor list - wrapped in container like Network (height fits content)
        StyledRect {
            Layout.fillWidth: true
            // Height fits content, not fillHeight - same as Network list
            implicitHeight: monitorColumn.implicitHeight + Appearance.padding.normal * 2
            
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer
            
            ColumnLayout {
                id: monitorColumn

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.small / 2

                // Monitor cards
                Repeater {
                    model: Monitors.monitors

                    MonitorCard {
                        required property var modelData

                        // Use Layout.fillWidth for ColumnLayout child
                        Layout.fillWidth: true
                        monitor: modelData

                        onClicked: {
                            Monitors.selectMonitor(modelData);
                        }
                    }
                }
            }
        }

        // Spacer to push content up
        Item { Layout.fillHeight: true }
    }

    // ToggleButton component - matching Bluetooth style with animations
    component ToggleButton: StyledRect {
        id: toggleBtn

        required property bool toggled
        property string icon
        property string label: ""
        property string accent: "Secondary"
        
        // Expose hovered state for tooltip
        readonly property bool hovered: toggleStateLayer.containsMouse

        function onClicked(): void {}

        Layout.preferredWidth: implicitWidth + (toggleStateLayer.pressed ? Appearance.padding.normal * 2 : toggled ? Appearance.padding.small * 2 : 0)
        implicitWidth: toggleBtnInner.implicitWidth + Appearance.padding.large * 2
        implicitHeight: toggleBtnIcon.implicitHeight + Appearance.padding.normal * 2

        radius: toggled || toggleStateLayer.pressed ? Appearance.rounding.small : Math.min(width, height) / 2 * Math.min(1, Appearance.rounding.scale)
        color: toggled ? Colours.palette[`m3${accent.toLowerCase()}`] : Colours.palette[`m3${accent.toLowerCase()}Container`]

        StateLayer {
            id: toggleStateLayer

            color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]

            function onClicked(): void {
                toggleBtn.onClicked();
            }
        }

        RowLayout {
            id: toggleBtnInner

            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            MaterialIcon {
                id: toggleBtnIcon

                visible: !!text
                fill: toggleBtn.toggled ? 1 : 0
                text: toggleBtn.icon
                color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
                font.pointSize: Appearance.font.size.large

                Behavior on fill {
                    Anim {}
                }
            }

            Loader {
                asynchronous: true
                active: !!toggleBtn.label
                visible: active

                sourceComponent: StyledText {
                    text: toggleBtn.label
                    color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
                }
            }
        }

        Behavior on radius {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on color {
            CAnim {}
        }
    }
}
