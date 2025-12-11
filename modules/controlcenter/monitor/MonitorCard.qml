pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var monitor
    readonly property bool isSelected: Monitors.selectedMonitor === monitor

    signal clicked()

    implicitHeight: content.implicitHeight + Appearance.padding.normal * 2

    radius: Appearance.rounding.small
    // Same pattern as Network card - always has bg with alpha based on selection
    color: Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, isSelected ? 1 : 0)

    StateLayer {
        id: stateLayer
        color: root.monitor?.focused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

        function onClicked(): void {
            root.clicked();
        }
    }

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Appearance.padding.normal

        spacing: Appearance.spacing.normal

        // Monitor icon with status - SAMA PERSIS dengan Network card
        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: monitorIcon.implicitHeight + Appearance.padding.normal * 2

            radius: Appearance.rounding.small
            color: {
                if (root.monitor?.disabled) return Colours.palette.m3errorContainer;
                if (!(root.monitor?.dpmsStatus ?? true)) return Colours.tPalette.m3surfaceContainerHighest;
                if (root.monitor?.focused) return Colours.palette.m3primaryContainer;
                return Colours.palette.m3secondaryContainer;
            }

            // Hover overlay on icon - SAMA dengan Network card
            StyledRect {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.alpha(
                    root.monitor?.focused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSecondaryContainer,
                    stateLayer.pressed ? 0.1 : stateLayer.containsMouse ? 0.08 : 0
                )
            }

            MaterialIcon {
                id: monitorIcon
                anchors.centerIn: parent
                text: {
                    if (root.monitor?.disabled) return "desktop_access_disabled";
                    if (!(root.monitor?.dpmsStatus ?? true)) return "screen_lock_portrait";
                    return "desktop_windows";
                }
                color: {
                    if (root.monitor?.disabled) return Colours.palette.m3onErrorContainer;
                    if (!(root.monitor?.dpmsStatus ?? true)) return Colours.palette.m3onSurface;
                    if (root.monitor?.focused) return Colours.palette.m3onPrimaryContainer;
                    return Colours.palette.m3onSecondaryContainer;
                }
                font.pointSize: Appearance.font.size.large
            }
        }

        // Monitor info - SAMA PERSIS dengan Network card (TANPA Layout.alignment)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            // Row pertama - hanya nama
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.monitor?.name ?? ""
                    elide: Text.ElideRight
                }
            }

            // Row kedua - info resolusi
            StyledText {
                Layout.fillWidth: true
                readonly property var cachedData: Monitors.getMonitorData(root.monitor?.name ?? "")
                readonly property real refreshRate: cachedData?.refreshRate ?? root.monitor?.refreshRate ?? 0
                
                text: `${root.monitor?.width ?? 0}×${root.monitor?.height ?? 0} @ ${refreshRate.toFixed(0)}Hz` + (root.monitor?.model ? " • " + root.monitor.model : "")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }

        // Primary badge - DI LUAR ColumnLayout, center vertical (seperti saved icon di Network)
        StyledRect {
            visible: root.monitor?.focused ?? false
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: primaryLabel.implicitWidth + Appearance.padding.smaller * 2
            implicitHeight: primaryLabel.implicitHeight + 2

            radius: Appearance.rounding.full
            color: Colours.palette.m3primary

            StyledText {
                id: primaryLabel
                anchors.centerIn: parent
                text: qsTr("Primary")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onPrimary
            }
        }

        // Disabled badge - DI LUAR ColumnLayout, center vertical
        StyledRect {
            visible: root.monitor?.disabled ?? false
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: disabledLabel.implicitWidth + Appearance.padding.smaller * 2
            implicitHeight: disabledLabel.implicitHeight + 2

            radius: Appearance.rounding.full
            color: Colours.palette.m3error

            StyledText {
                id: disabledLabel
                anchors.centerIn: parent
                text: qsTr("Disabled")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onError
            }
        }

        // Arrow - center vertical (seperti Network)
        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            text: "chevron_right"
            color: Colours.palette.m3outline
        }
    }
}
