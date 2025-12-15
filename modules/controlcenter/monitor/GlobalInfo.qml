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

Item {
    id: root

    required property Session session

    implicitWidth: settingsLayout.implicitWidth
    implicitHeight: settingsLayout.implicitHeight

    ColumnLayout {
        id: settingsLayout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.spacing.normal

        // Header Icon
        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "desktop_windows"
            font.pointSize: Appearance.font.size.extraLarge * 3
            font.bold: true
        }

        // Header Title
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Display settings")
            font.pointSize: Appearance.font.size.large
            font.bold: true
        }

        // =====================================================
        // VRR (Variable Refresh Rate) Section
        // =====================================================
        StyledText {
            Layout.topMargin: Appearance.spacing.large
            text: qsTr("Variable Refresh Rate")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        StyledText {
            text: qsTr("Adaptive sync settings for displays")
            color: Colours.palette.m3outline
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: vrrContent.implicitHeight + Appearance.padding.large * 2

            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: vrrContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.large

                spacing: Appearance.spacing.larger

                // VRR Status Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: vrrIcon.implicitHeight + Appearance.padding.normal * 2

                        radius: Appearance.rounding.normal
                        color: Monitors.globalVrr > 0 ? Colours.palette.m3tertiaryContainer : Colours.tPalette.m3surfaceContainerHigh

                        MaterialIcon {
                            id: vrrIcon

                            anchors.centerIn: parent
                            text: "display_settings"
                            color: Monitors.globalVrr > 0 ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.large
                            fill: Monitors.globalVrr > 0 ? 1 : 0

                            Behavior on fill { Anim {} }
                        }

                        Behavior on color { CAnim {} }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Monitors.vrrModes[Monitors.globalVrr]?.name ?? qsTr("Off")
                            font.weight: 500
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Monitors.vrrModes[Monitors.globalVrr]?.description ?? qsTr("Variable refresh rate disabled")
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                            elide: Text.ElideRight
                        }
                    }
                }

                // VRR Mode Toggle
                Toggle {
                    label: qsTr("VRR Enabled")
                    checked: Monitors.globalVrr > 0
                    toggle.onToggled: {
                        Monitors.setGlobalVrr(checked ? 1 : 0);
                    }
                }

                Toggle {
                    label: qsTr("Fullscreen Only")
                    checked: Monitors.globalVrr === 2
                    enabled: Monitors.globalVrr > 0
                    opacity: enabled ? 1 : 0.5
                    toggle.onToggled: {
                        Monitors.setGlobalVrr(checked ? 2 : 1);
                    }
                }
            }
        }

        // =====================================================
        // Display Summary Section
        // =====================================================
        StyledText {
            Layout.topMargin: Appearance.spacing.large
            text: qsTr("Display summary")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        StyledText {
            text: qsTr("Connected display information")
            color: Colours.palette.m3outline
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: summaryContent.implicitHeight + Appearance.padding.large * 2

            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: summaryContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.large

                spacing: Appearance.spacing.small / 2

                // Summary header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: summaryIcon.implicitHeight + Appearance.padding.normal * 2

                        radius: Appearance.rounding.normal
                        color: Colours.palette.m3primaryContainer

                        MaterialIcon {
                            id: summaryIcon

                            anchors.centerIn: parent
                            text: "monitor"
                            color: Colours.palette.m3onPrimaryContainer
                            font.pointSize: Appearance.font.size.large
                            fill: 1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("%1 display(s) connected").arg(Monitors.globalInfo.totalMonitors || 0)
                            font.weight: 500
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Total: %1×%2").arg(Monitors.globalInfo.totalWidth || 0).arg(Monitors.globalInfo.totalHeight || 0)
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                            elide: Text.ElideRight
                        }
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    Layout.bottomMargin: Appearance.spacing.small
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                }

                InfoRow { label: qsTr("Active displays"); value: String(Monitors.globalInfo.activeMonitors || 0); valueColor: Colours.palette.m3primary }
                InfoRow { label: qsTr("Disabled displays"); value: String(Monitors.globalInfo.disabledMonitors || 0); visible: (Monitors.globalInfo.disabledMonitors || 0) > 0; valueColor: Colours.palette.m3error }
            }
        }

        // =====================================================
        // Compositor Info Section
        // =====================================================
        StyledText {
            Layout.topMargin: Appearance.spacing.large
            text: qsTr("Compositor")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        StyledText {
            text: qsTr("Hyprland compositor information")
            color: Colours.palette.m3outline
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: compositorContent.implicitHeight + Appearance.padding.large * 2

            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: compositorContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Appearance.padding.large

                spacing: Appearance.spacing.small / 2

                // Compositor header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: compIcon.implicitHeight + Appearance.padding.normal * 2

                        radius: Appearance.rounding.normal
                        color: Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            id: compIcon

                            anchors.centerIn: parent
                            text: "terminal"
                            color: Colours.palette.m3onSecondaryContainer
                            font.pointSize: Appearance.font.size.large
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: "Hyprland"
                            font.weight: 500
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Monitors.globalInfo.hyprlandVersion || qsTr("Unknown version")
                            color: Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.small
                            elide: Text.ElideRight
                        }
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    Layout.bottomMargin: Appearance.spacing.small
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                }

                InfoRow { label: qsTr("Commit"); value: (Monitors.globalInfo.hyprlandCommit || "-").slice(0, 12); visible: (Monitors.globalInfo.hyprlandCommit || "") !== "" }
                InfoRow { label: qsTr("Branch"); value: Monitors.globalInfo.hyprlandBranch || "-"; visible: (Monitors.globalInfo.hyprlandBranch || "") !== "" }
            }
        }

        // =====================================================
        // Per-Monitor Details Section
        // =====================================================
        StyledText {
            Layout.topMargin: Appearance.spacing.large
            text: qsTr("Connected displays")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        StyledText {
            text: qsTr("Detailed information for each display")
            color: Colours.palette.m3outline
        }

        // Per-monitor cards
        Repeater {
            model: Object.keys(Monitors.monitorData)

            StyledRect {
                id: monitorCard
                required property string modelData
                required property int index
                
                readonly property var mon: Monitors.monitorData[modelData] ?? {}

                Layout.fillWidth: true
                implicitHeight: monitorDetailColumn.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                // Make card clickable - navigate to MonitorSettings
                MouseArea {
                    id: cardMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    z: 100  // High z-index to ensure it captures click
                    
                    onClicked: mouse => {
                        mouse.accepted = true;  // Prevent propagation
                        const targetName = monitorCard.modelData;
                        
                        // Find and select the monitor using Qt.callLater to avoid race conditions
                        Qt.callLater(() => {
                            const hyprMon = Monitors.monitors.values.find(m => m?.name === targetName);
                            if (hyprMon) {
                                Monitors.selectMonitor(hyprMon);
                            }
                        });
                    }
                    
                    // Hover effect
                    Rectangle {
                        anchors.fill: parent
                        radius: monitorCard.radius
                        color: Qt.alpha(Colours.palette.m3onSurface, cardMouseArea.pressed ? 0.1 : cardMouseArea.containsMouse ? 0.08 : 0)
                    }
                }

                ColumnLayout {
                    id: monitorDetailColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small / 2

                    // Monitor header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: monIcon.implicitHeight + Appearance.padding.normal * 2

                            radius: Appearance.rounding.normal
                            color: monitorCard.mon.focused ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                            MaterialIcon {
                                id: monIcon

                                anchors.centerIn: parent
                                text: "monitor"
                                fill: monitorCard.mon.focused ? 1 : 0
                                color: monitorCard.mon.focused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline

                                Behavior on fill { Anim {} }
                            }

                            Behavior on color { CAnim {} }
                        }

                        // Monitor info - takes remaining space
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small

                                StyledText {
                                    text: monitorCard.modelData
                                    font.weight: 500
                                }

                                // Badges
                                StyledRect {
                                    visible: monitorCard.mon.focused ?? false
                                    implicitWidth: focusLabel.implicitWidth + 8
                                    implicitHeight: focusLabel.implicitHeight + 2
                                    radius: Appearance.rounding.full
                                    color: Colours.palette.m3primaryContainer

                                    StyledText {
                                        id: focusLabel
                                        anchors.centerIn: parent
                                        text: qsTr("Focused")
                                        font.pointSize: Appearance.font.size.smaller
                                        color: Colours.palette.m3onPrimaryContainer
                                    }
                                }

                                StyledRect {
                                    visible: monitorCard.mon.vrr ?? false
                                    implicitWidth: vrrLabel.implicitWidth + 8
                                    implicitHeight: vrrLabel.implicitHeight + 2
                                    radius: Appearance.rounding.full
                                    color: Colours.palette.m3tertiaryContainer

                                    StyledText {
                                        id: vrrLabel
                                        anchors.centerIn: parent
                                        text: "VRR"
                                        font.pointSize: Appearance.font.size.smaller
                                        color: Colours.palette.m3onTertiaryContainer
                                    }
                                }

                                // Spacer to push chevron to right
                                Item { Layout.fillWidth: true }
                            }

                            StyledText {
                                text: (monitorCard.mon.make ?? "") + (monitorCard.mon.model ? ` ${monitorCard.mon.model}` : "")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outline
                                visible: text !== ""
                            }
                        }

                        // Chevron arrow - navigate to MonitorSettings
                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: "chevron_right"
                            color: Colours.palette.m3outline
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.small
                        Layout.bottomMargin: Appearance.spacing.small
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }

                    // Monitor details
                    InfoRow { label: qsTr("Resolution"); value: `${monitorCard.mon.width ?? 0}×${monitorCard.mon.height ?? 0}` }
                    InfoRow { label: qsTr("Refresh Rate"); value: `${(monitorCard.mon.refreshRate ?? 0).toFixed(2)} Hz`; valueColor: Colours.palette.m3tertiary }
                    InfoRow { label: qsTr("Scale"); value: `${(monitorCard.mon.scale ?? 1).toFixed(2)}x` }
                    InfoRow { label: qsTr("Position"); value: `${monitorCard.mon.x ?? 0}, ${monitorCard.mon.y ?? 0}` }
                    InfoRow { label: qsTr("Physical Size"); value: `${monitorCard.mon.physicalWidth ?? 0}×${monitorCard.mon.physicalHeight ?? 0} mm` }
                    InfoRow { label: qsTr("Pixel Format"); value: monitorCard.mon.currentFormat ?? "Unknown" }
                    InfoRow { label: qsTr("DPMS"); value: monitorCard.mon.dpmsStatus ? qsTr("On") : qsTr("Off"); valueColor: monitorCard.mon.dpmsStatus ? Colours.palette.m3primary : Colours.palette.m3error }
                    InfoRow { label: qsTr("Workspace"); value: monitorCard.mon.activeWorkspace?.name ?? "-" }
                }
            }
        }

        // Bottom spacer
        Item { Layout.preferredHeight: Appearance.padding.large }
    }

    // =====================================================
    // Components
    // =====================================================

    component InfoRow: RowLayout {
        property string label
        property string value
        property color valueColor: Colours.palette.m3onSurface

        Layout.fillWidth: true

        StyledText {
            text: label
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: value
            font.pointSize: Appearance.font.size.small
            color: valueColor
        }
    }

    component Toggle: RowLayout {
        property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
