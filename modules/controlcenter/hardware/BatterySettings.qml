pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    StyledFlickable {
        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: mainLayout.height

        ColumnLayout {
            id: mainLayout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            // Battery Icon & Percentage
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Hardware.batteryCharging ? "battery_charging_full" : 
                      Hardware.batteryPercent > 80 ? "battery_full" :
                      Hardware.batteryPercent > 50 ? "battery_3_bar" :
                      Hardware.batteryPercent > 20 ? "battery_2_bar" : "battery_alert"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
                color: Hardware.batteryPercent < 20 ? Colours.palette.m3error : 
                       Hardware.batteryCharging ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Hardware.batteryPercent + "%"
                font.pointSize: Appearance.font.size.extraLarge * 2
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (Hardware.batteryNotCharging && Hardware.conservationMode) {
                        return qsTr("Conservation Mode Active")
                    }
                    return Hardware.batteryStatus
                }
                color: Hardware.batteryCharging ? Colours.palette.m3primary : 
                       Hardware.batteryNotCharging ? Colours.palette.m3tertiary : 
                       Colours.palette.m3onSurfaceVariant
            }
            
            // Conservation mode explanation when active and battery > 60%
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: Hardware.conservationMode && Hardware.batteryPercent > 60
                text: qsTr("Battery will drain to 60% before charging resumes")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
            
            // Reset to Default button
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                text: qsTr("Reset to Default")
                icon: "restart_alt"
                onClicked: Hardware.resetBatteryToDefault()
            }

            // =====================================================
            // Battery Status Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Battery Status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: statusLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                GridLayout {
                    id: statusLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    columns: 2
                    rowSpacing: Appearance.spacing.normal
                    columnSpacing: Appearance.spacing.large

                    StatRow {
                        Layout.fillWidth: true
                        icon: "bolt"
                        label: qsTr("Power Draw")
                        value: Hardware.batteryPowerNow.toFixed(1) + " W"
                    }

                    StatRow {
                        Layout.fillWidth: true
                        icon: "schedule"
                        label: Hardware.batteryCharging ? qsTr("Time to Full") : qsTr("Time Remaining")
                        value: {
                            const mins = Hardware.batteryTimeRemaining;
                            if (mins <= 0) return "—";
                            const h = Math.floor(mins / 60);
                            const m = Math.round(mins % 60);
                            return h > 0 ? qsTr("%1h %2m").arg(h).arg(m) : qsTr("%1m").arg(m);
                        }
                    }

                    StatRow {
                        Layout.fillWidth: true
                        icon: "battery_std"
                        label: qsTr("Energy Now")
                        value: Hardware.batteryEnergyNow.toFixed(1) + " Wh"
                    }

                    StatRow {
                        Layout.fillWidth: true
                        icon: "battery_full"
                        label: qsTr("Full Capacity")
                        value: Hardware.batteryCurrentCapacity.toFixed(1) + " Wh"
                    }
                }
            }

            // =====================================================
            // Battery Health Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Battery Health")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: healthLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: healthLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Health bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: qsTr("Health")
                                font.weight: 500
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: Hardware.batteryHealth.toFixed(1) + "%"
                                font.weight: 600
                                color: Hardware.batteryHealth > 80 ? Colours.palette.m3primary :
                                       Hardware.batteryHealth > 50 ? Colours.palette.m3tertiary : Colours.palette.m3error
                            }
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 8
                            radius: 4
                            color: Colours.palette.m3surfaceContainerHighest

                            StyledRect {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * (Hardware.batteryHealth / 100)
                                radius: parent.radius
                                color: Hardware.batteryHealth > 80 ? Colours.palette.m3primary :
                                       Hardware.batteryHealth > 50 ? Colours.palette.m3tertiary : Colours.palette.m3error

                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    // Health stats
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: Appearance.spacing.small
                        columnSpacing: Appearance.spacing.large

                        StatRow {
                            Layout.fillWidth: true
                            icon: "loop"
                            label: qsTr("Cycle Count")
                            value: Hardware.batteryCycleCount.toString()
                            valueColor: Hardware.batteryCycleCount > 500 ? Colours.palette.m3error :
                                       Hardware.batteryCycleCount > 300 ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
                        }

                        StatRow {
                            Layout.fillWidth: true
                            icon: "design_services"
                            label: qsTr("Design Capacity")
                            value: Hardware.batteryDesignCapacity.toFixed(1) + " Wh"
                        }

                        StatRow {
                            Layout.fillWidth: true
                            icon: "inventory"
                            label: qsTr("Model")
                            value: Hardware.batteryModel || "—"
                        }

                        StatRow {
                            Layout.fillWidth: true
                            icon: "factory"
                            label: qsTr("Manufacturer")
                            value: Hardware.batteryManufacturer || "—"
                        }
                    }
                }
            }

            // =====================================================
            // Conservation Mode Section (Lenovo)
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                visible: Hardware.hasConservationMode
                text: qsTr("Battery Protection")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledRect {
                Layout.fillWidth: true
                visible: Hardware.hasConservationMode
                implicitHeight: conservationLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: conservationLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "battery_saver"
                            font.pointSize: Appearance.font.size.extraLarge
                            color: Hardware.conservationMode ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: qsTr("Conservation Mode")
                                font.weight: 500
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Limit charging to 60% to extend battery lifespan. Recommended when plugged in most of the time.")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.Wrap
                            }
                        }

                        StyledSwitch {
                            checked: Hardware.conservationMode
                            onToggled: {
                                Hardware.setConservationMode(checked);
                            }
                        }
                    }

                    // Info card when enabled
                    StyledRect {
                        Layout.fillWidth: true
                        visible: Hardware.conservationMode
                        implicitHeight: infoRow.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3primaryContainer

                        RowLayout {
                            id: infoRow
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.normal
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "info"
                                color: Colours.palette.m3onPrimaryContainer
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Battery will stop charging at 60% to preserve long-term health")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onPrimaryContainer
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                    
                    // USB Charging when laptop is off
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.normal
                        visible: Hardware.hasUsbCharging
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "usb"
                            font.pointSize: Appearance.font.size.extraLarge
                            color: Hardware.usbCharging ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: qsTr("Always-on USB Charging")
                                font.weight: 500
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Charge USB devices even when laptop is off or in sleep mode")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.Wrap
                            }
                        }

                        StyledSwitch {
                            checked: Hardware.usbCharging
                            onToggled: Hardware.setUsbCharging(checked)
                        }
                    }
                }
            }
            
            // =====================================================
            // Battery Info Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Battery Information")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: infoLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: infoLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small

                    InfoRow { label: qsTr("Technology"); value: Hardware.batteryTechnology || "Li-poly" }
                    InfoRow { label: qsTr("Voltage"); value: (Hardware.batteryPowerNow / Math.max(0.001, Hardware.batteryEnergyNow / Hardware.batteryCurrentCapacity)).toFixed(2) + " V" }
                    InfoRow { label: qsTr("Capacity Lost"); value: (Hardware.batteryDesignCapacity - Hardware.batteryCurrentCapacity).toFixed(1) + " Wh (" + (100 - Hardware.batteryHealth).toFixed(1) + "%)" }
                }
            }

            Item { Layout.preferredHeight: Appearance.spacing.large }
        }
    }

    // =====================================================
    // COMPONENTS
    // =====================================================

    component StatRow: RowLayout {
        property string icon
        property string label
        property string value
        property color valueColor: Colours.palette.m3onSurface

        spacing: Appearance.spacing.small

        MaterialIcon {
            text: parent.icon
            font.pointSize: Appearance.font.size.large
            color: Colours.palette.m3primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: parent.parent.label
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: parent.parent.value
                font.weight: 500
                color: parent.parent.valueColor
            }
        }
    }

    component InfoRow: RowLayout {
        property string label
        property string value

        Layout.fillWidth: true

        StyledText {
            text: parent.label
            color: Colours.palette.m3onSurfaceVariant
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: parent.value
            font.weight: 500
        }
    }
}
