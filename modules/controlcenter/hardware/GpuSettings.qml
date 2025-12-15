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
                text: "videogame_asset"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Hardware.gpuModel
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Driver: %1").arg(Hardware.gpuDriver)
                color: Colours.palette.m3onSurfaceVariant
            }
            
            // Reset to Default button
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                text: qsTr("Reset to Default")
                icon: "restart_alt"
                visible: Hardware.hasNvidiaGpu
                onClicked: Hardware.resetGpuToDefault()
            }

            // No GPU fallback
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.extraLarge
                visible: !Hardware.hasNvidiaGpu
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "videocam_off"
                    font.pointSize: Appearance.font.size.extraLarge * 2
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No NVIDIA GPU detected")
                    font.pointSize: Appearance.font.size.larger
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Make sure nvidia-smi is installed and working")
                    color: Colours.palette.m3outline
                }
            }

            // GPU Content (only show if NVIDIA GPU exists)
            ColumnLayout {
                Layout.fillWidth: true
                visible: Hardware.hasNvidiaGpu
                spacing: Appearance.spacing.normal

                // =====================================================
                // Real-time Stats Section
                // =====================================================
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Real-time Statistics")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: statsLayout.implicitHeight + Appearance.padding.large * 2

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    GridLayout {
                        id: statsLayout

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        columns: 2
                        rowSpacing: Appearance.spacing.normal
                        columnSpacing: Appearance.spacing.large

                        // Temperature
                        StatRow {
                            Layout.fillWidth: true
                            icon: "thermostat"
                            label: qsTr("Temperature")
                            value: Hardware.gpuTemp + "°C"
                            valueColor: Hardware.gpuTemp > 80 ? Colours.palette.m3error : 
                                       Hardware.gpuTemp > 60 ? Colours.palette.m3tertiary : 
                                       Colours.palette.m3onSurface
                        }

                        // Power Draw
                        StatRow {
                            Layout.fillWidth: true
                            icon: "bolt"
                            label: qsTr("Power Draw")
                            value: Hardware.gpuPowerDraw.toFixed(1) + "W"
                        }

                        // GPU Utilization
                        StatRow {
                            Layout.fillWidth: true
                            icon: "speed"
                            label: qsTr("GPU Usage")
                            value: Hardware.gpuUsage + "%"
                        }

                        // Memory Utilization
                        StatRow {
                            Layout.fillWidth: true
                            icon: "memory"
                            label: qsTr("Memory Usage")
                            value: Hardware.gpuMemoryUsage + "%"
                        }

                        // Graphics Clock
                        StatRow {
                            Layout.fillWidth: true
                            icon: "timeline"
                            label: qsTr("GPU Clock")
                            value: Hardware.gpuClockGraphics + " / " + Hardware.gpuClockMaxGraphics + " MHz"
                        }

                        // Memory Clock
                        StatRow {
                            Layout.fillWidth: true
                            icon: "storage"
                            label: qsTr("Mem Clock")
                            value: Hardware.gpuClockMemory + " / " + Hardware.gpuClockMaxMemory + " MHz"
                        }

                        // VRAM
                        StatRow {
                            Layout.fillWidth: true
                            icon: "sd_card"
                            label: qsTr("VRAM")
                            value: Hardware.gpuMemoryUsed + " / " + Hardware.gpuMemoryTotal + " MiB"
                        }

                        // Power State
                        StatRow {
                            Layout.fillWidth: true
                            icon: "power_settings_new"
                            label: qsTr("Power State")
                            value: Hardware.gpuPowerState
                        }
                    }
                }

                // =====================================================
                // Power Limit Section
                // =====================================================
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Power Limit")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    text: Hardware.gpuPowerLimitSupported ? 
                          qsTr("Limit GPU power consumption (affects performance)") :
                          qsTr("Power limit control is not supported on this laptop GPU")
                    color: Hardware.gpuPowerLimitSupported ? 
                           Colours.palette.m3outline : Colours.palette.m3error
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: powerLimitLayout.implicitHeight + Appearance.padding.large * 2
                    visible: Hardware.gpuPowerLimitSupported

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: powerLimitLayout

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        // Current power info
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.large

                            ColumnLayout {
                                spacing: 2

                                StyledText {
                                    text: qsTr("Current")
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    text: Hardware.gpuPowerLimit.toFixed(0) + "W"
                                    font.pointSize: Appearance.font.size.larger
                                    font.weight: 600
                                    color: Colours.palette.m3primary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            ColumnLayout {
                                spacing: 2

                                StyledText {
                                    text: qsTr("Default")
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    text: Hardware.gpuPowerDefault.toFixed(0) + "W"
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }

                            ColumnLayout {
                                spacing: 2

                                StyledText {
                                    text: qsTr("Range")
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    text: Hardware.gpuPowerMin.toFixed(0) + " - " + Hardware.gpuPowerMax.toFixed(0) + "W"
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }

                        // Power limit slider
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: Hardware.gpuPowerMin.toFixed(0) + "W"
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledSlider {
                                id: powerLimitSlider
                                Layout.fillWidth: true
                                
                                from: Hardware.gpuPowerMin
                                to: Hardware.gpuPowerMax
                                value: Hardware.gpuPowerLimit
                                stepSize: 5

                                onPressedChanged: {
                                    if (!pressed && value !== Hardware.gpuPowerLimit) {
                                        Hardware.setGpuPowerLimit(Math.round(value));
                                    }
                                }
                            }

                            StyledText {
                                text: Hardware.gpuPowerMax.toFixed(0) + "W"
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        // Quick presets
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            PresetButton {
                                Layout.fillWidth: true
                                label: qsTr("Eco")
                                watts: Math.max(Hardware.gpuPowerMin, 40)
                                isActive: Hardware.gpuPowerLimit <= 40

                                onClicked: {
                                    Hardware.setGpuPowerLimit(Math.max(Hardware.gpuPowerMin, 40));
                                }
                            }

                            PresetButton {
                                Layout.fillWidth: true
                                label: qsTr("Balanced")
                                watts: Math.round((Hardware.gpuPowerMin + Hardware.gpuPowerMax) / 2)
                                isActive: Math.abs(Hardware.gpuPowerLimit - (Hardware.gpuPowerMin + Hardware.gpuPowerMax) / 2) < 10

                                onClicked: {
                                    Hardware.setGpuPowerLimit(Math.round((Hardware.gpuPowerMin + Hardware.gpuPowerMax) / 2));
                                }
                            }

                            PresetButton {
                                Layout.fillWidth: true
                                label: qsTr("Default")
                                watts: Hardware.gpuPowerDefault
                                isActive: Math.abs(Hardware.gpuPowerLimit - Hardware.gpuPowerDefault) < 5

                                onClicked: {
                                    Hardware.resetGpuPowerLimit();
                                }
                            }

                            PresetButton {
                                Layout.fillWidth: true
                                label: qsTr("Max")
                                watts: Hardware.gpuPowerMax
                                isActive: Hardware.gpuPowerLimit >= Hardware.gpuPowerMax - 5

                                onClicked: {
                                    Hardware.setGpuPowerLimit(Hardware.gpuPowerMax);
                                }
                            }
                        }
                    }
                }

                // Unsupported power limit info card
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: unsupportedLayout.implicitHeight + Appearance.padding.large * 2
                    visible: !Hardware.gpuPowerLimitSupported

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    RowLayout {
                        id: unsupportedLayout

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "info"
                            font.pointSize: Appearance.font.size.extraLarge
                            color: Colours.palette.m3tertiary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            StyledText {
                                text: qsTr("Power Limit Locked by BIOS")
                                font.weight: 500
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Laptop GPUs typically have power limits managed by the BIOS/vBIOS and cannot be adjusted via software. Current power draw: %1W").arg(Hardware.gpuPowerDraw.toFixed(1))
                                wrapMode: Text.Wrap
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }

                // =====================================================
                // Persistence Mode Section
                // =====================================================
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Persistence Mode")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    text: qsTr("Keep GPU initialized for faster application startup")
                    color: Colours.palette.m3outline
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: persistenceLayout.implicitHeight + Appearance.padding.large * 2

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    RowLayout {
                        id: persistenceLayout

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: qsTr("Persistence Mode")
                                font.weight: 500
                            }

                            StyledText {
                                text: Hardware.gpuPersistenceMode ? 
                                      qsTr("GPU stays initialized, uses more idle power") :
                                      qsTr("GPU can fully power down when idle")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        StyledSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            checked: Hardware.gpuPersistenceMode
                            onToggled: {
                                Hardware.setGpuPersistenceMode(checked);
                            }
                        }
                    }
                }

                // =====================================================
                // VRAM Usage Visual
                // =====================================================
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("VRAM Usage")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: vramLayout.implicitHeight + Appearance.padding.large * 2

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: vramLayout

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: Hardware.gpuMemoryUsed + " MiB"
                                font.pointSize: Appearance.font.size.larger
                                font.weight: 600
                                color: Colours.palette.m3primary
                            }

                            StyledText {
                                text: " / " + Hardware.gpuMemoryTotal + " MiB"
                                font.pointSize: Appearance.font.size.larger
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: ((Hardware.gpuMemoryUsed / Math.max(1, Hardware.gpuMemoryTotal)) * 100).toFixed(1) + "%"
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        // VRAM bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 12

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Colours.palette.m3surfaceContainerHighest
                            }

                            Rectangle {
                                width: parent.width * (Hardware.gpuMemoryUsed / Math.max(1, Hardware.gpuMemoryTotal))
                                height: parent.height
                                radius: height / 2
                                color: {
                                    const usage = Hardware.gpuMemoryUsed / Math.max(1, Hardware.gpuMemoryTotal);
                                    if (usage > 0.9) return Colours.palette.m3error;
                                    if (usage > 0.7) return Colours.palette.m3tertiary;
                                    return Colours.palette.m3primary;
                                }

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
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
            color: Colours.palette.m3tertiary
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

    component PresetButton: StyledRect {
        id: presetRoot

        required property string label
        required property real watts
        property bool isActive: false

        signal clicked()

        implicitHeight: 36
        radius: Appearance.rounding.small
        color: isActive ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerHighest

        StateLayer {
            radius: presetRoot.radius
            color: isActive ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
            onClicked: {
                presetRoot.clicked();
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: presetRoot.label
                font.pointSize: Appearance.font.size.small
                font.weight: 500
                color: presetRoot.isActive ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: presetRoot.watts.toFixed(0) + "W"
                font.pointSize: Appearance.font.size.smaller
                color: presetRoot.isActive ? Qt.alpha(Colours.palette.m3onTertiaryContainer, 0.7) : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
