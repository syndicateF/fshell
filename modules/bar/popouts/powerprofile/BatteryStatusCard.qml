pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * BatteryStatusCard - Battery info display with health, time remaining, and progress bar
 * 
 * Usage:
 *   BatteryStatusCard {
 *       isCharging: root.isCharging
 *       batteryPercent: root.batteryPercent
 *       healthPercent: Power.batteryInfo.healthPercent
 *       timeRemaining: UPower.displayDevice.timeToFull
 *   }
 */
StyledRect {
    id: root

    property bool isCharging: false
    property int batteryPercent: 0
    property real healthPercent: 100.0
    property int timeRemaining: 0

    Layout.fillWidth: true
    implicitWidth: 280
    implicitHeight: statusContent.height + Appearance.padding.normal * 2
    radius: Appearance.rounding.small
    color: Colours.tPalette.m3surfaceContainer

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

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "favorite"
                    font.pointSize: Appearance.font.size.small
                    color: root.isCharging ? Colours.palette.m3primary : Colours.palette.m3tertiary
                    fill: 1
                }
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: "Health " + Math.round(root.healthPercent) + "%"
                    font.weight: 600
                }

                StyledText {
                    text: {
                        if (root.timeRemaining <= 0) {
                            return root.isCharging ? qsTr("Calculating...") : qsTr("Unknown");
                        }
                        const hours = Math.floor(root.timeRemaining / 3600);
                        const minutes = Math.floor((root.timeRemaining % 3600) / 60);
                        if (hours > 0) {
                            return qsTr("%1h %2m %3").arg(hours).arg(minutes).arg(root.isCharging ? qsTr("to full") : qsTr("remaining"));
                        }
                        return qsTr("%1m %2").arg(minutes).arg(root.isCharging ? qsTr("to full") : qsTr("remaining"));
                    }
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3outline
                }
            }
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
