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

            // Header
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "flash_on"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Power Control")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Direct CPU governor control via sysfs")
                color: Colours.palette.m3onSurfaceVariant
            }

            // Warning badge for AMD systems
            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                visible: Hardware.cpuDriver === "amd-pstate-epp" || Hardware.cpuDriver === "amd-pstate"
                implicitWidth: warningRow.implicitWidth + Appearance.padding.normal * 2
                implicitHeight: warningRow.implicitHeight + Appearance.padding.small * 2
                radius: Appearance.rounding.small
                color: Qt.alpha(Colours.palette.m3tertiary, 0.2)

                RowLayout {
                    id: warningRow
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "check_circle"
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3tertiary
                    }

                    StyledText {
                        text: qsTr("AMD C-state safe mode active")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3tertiary
                    }
                }
            }

            // =====================================================
            // Power Mode Selection
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Power Mode")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Select your power profile - all modes are safe and won't cause freezes")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: modeLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: modeLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    Repeater {
                        model: Hardware.customPowerModesAvailable

                        OptionRow {
                            required property string modelData
                            required property int index

                            Layout.fillWidth: true

                            icon: modelData === "performance" ? "bolt" :
                                  modelData === "balanced" ? "balance" :
                                  modelData === "power-saver" ? "eco" : "settings"
                            label: modelData === "performance" ? qsTr("Performance") :
                                   modelData === "balanced" ? qsTr("Balanced (Safe)") :
                                   modelData === "power-saver" ? qsTr("Power Saver (Safe)") : modelData
                            description: {
                                const config = Hardware.customPowerModeConfigs[modelData];
                                return config ? config.description : "";
                            }
                            isSelected: Hardware.customPowerMode === modelData

                            onClicked: {
                                Hardware.setCustomPowerMode(modelData);
                            }
                        }
                    }
                }
            }

            // =====================================================
            // Current Status Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Current Status")
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

                    // Governor
                    StatRow {
                        Layout.fillWidth: true
                        icon: "tune"
                        label: qsTr("Governor")
                        value: Hardware.cpuGovernor
                    }

                    // EPP
                    StatRow {
                        Layout.fillWidth: true
                        icon: "eco"
                        label: qsTr("Energy Pref")
                        value: Hardware.cpuEpp || qsTr("N/A")
                    }

                    // Driver
                    StatRow {
                        Layout.fillWidth: true
                        icon: "memory"
                        label: qsTr("Driver")
                        value: Hardware.cpuDriver
                    }
                }
            }

            // =====================================================
            // Advanced: EPP Selection
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Energy Performance Preference")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Hardware.cpuEppAvailable.length > 0
            }

            StyledText {
                text: qsTr("Fine-tune power vs performance balance")
                color: Colours.palette.m3outline
                visible: Hardware.cpuEppAvailable.length > 0
            }

            StyledRect {
                Layout.fillWidth: true
                visible: Hardware.cpuEppAvailable.length > 0
                implicitHeight: eppLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: eppLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    Repeater {
                        model: Hardware.cpuEppAvailable

                        OptionRow {
                            required property string modelData
                            required property int index

                            Layout.fillWidth: true

                            icon: modelData === "performance" ? "bolt" :
                                  modelData === "balance_performance" ? "speed" :
                                  modelData === "balance_power" ? "eco" :
                                  modelData === "power" ? "battery_saver" : "tune"
                            label: modelData.replace(/_/g, " ")
                            description: modelData === "performance" ? qsTr("Maximum CPU performance") :
                                        modelData === "balance_performance" ? qsTr("Prefer performance, save power when idle") :
                                        modelData === "balance_power" ? qsTr("Prefer power saving, boost when needed") :
                                        modelData === "power" ? qsTr("Maximum power saving (may cause issues)") : ""
                            isSelected: Hardware.cpuEpp === modelData
                            warning: modelData === "power"

                            onClicked: {
                                Hardware.setCpuEpp(modelData);
                            }
                        }
                    }
                }
            }

            // Bottom spacing
            Item {
                Layout.preferredHeight: Appearance.padding.large
            }
        }
    }

    // =====================================================
    // COMPONENTS
    // =====================================================

    component StatRow: RowLayout {
        required property string icon
        required property string label
        required property string value
        property color valueColor: Colours.palette.m3onSurface

        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: parent.icon
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true
            text: parent.label
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: parent.value
            font.weight: 500
            color: parent.valueColor
        }
    }

    component OptionRow: StyledRect {
        id: optionRoot

        required property string icon
        required property string label
        property string description: ""
        property bool isSelected: false
        property bool warning: false

        signal clicked()

        implicitHeight: optionLayout.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: isSelected ? Colours.palette.m3primaryContainer : 
               warning ? Qt.alpha(Colours.palette.m3error, 0.1) : "transparent"

        StateLayer {
            radius: optionRoot.radius
            color: isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            onClicked: {
                optionRoot.clicked();
            }
        }

        RowLayout {
            id: optionLayout

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: optionRoot.icon
                color: optionRoot.isSelected ? Colours.palette.m3onPrimaryContainer : 
                       optionRoot.warning ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: optionRoot.label
                    font.weight: 500
                    color: optionRoot.isSelected ? Colours.palette.m3onPrimaryContainer : 
                           optionRoot.warning ? Colours.palette.m3error : Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: optionRoot.description !== ""
                    text: optionRoot.description
                    font.pointSize: Appearance.font.size.small
                    color: optionRoot.isSelected ? Qt.alpha(Colours.palette.m3onPrimaryContainer, 0.7) : 
                           optionRoot.warning ? Qt.alpha(Colours.palette.m3error, 0.7) : Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                }
            }

            MaterialIcon {
                visible: optionRoot.isSelected
                text: "check_circle"
                color: Colours.palette.m3onPrimaryContainer
            }

            MaterialIcon {
                visible: optionRoot.warning && !optionRoot.isSelected
                text: "warning"
                color: Colours.palette.m3error
            }
        }
    }
}
