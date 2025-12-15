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
                text: "developer_board"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Hardware.cpuModel
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("%1 cores / %2 threads").arg(Hardware.cpuCores).arg(Hardware.cpuThreads)
                color: Colours.palette.m3onSurfaceVariant
            }
            
            // Reset to Default button
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                text: qsTr("Reset to Default")
                icon: "restart_alt"
                onClicked: Hardware.resetCpuToDefault()
            }

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
                        value: Hardware.cpuTemp.toFixed(1) + "°C"
                        valueColor: Hardware.cpuTemp > 80 ? Colours.palette.m3error : 
                                   Hardware.cpuTemp > 60 ? Colours.palette.m3tertiary : 
                                   Colours.palette.m3onSurface
                    }

                    // Usage
                    StatRow {
                        Layout.fillWidth: true
                        icon: "speed"
                        label: qsTr("Utilization")
                        value: Hardware.cpuUsage + "%"
                    }

                    // Current Frequency
                    StatRow {
                        Layout.fillWidth: true
                        icon: "bolt"
                        label: qsTr("Current Freq")
                        value: (Hardware.cpuFreqCurrent / 1000).toFixed(2) + " GHz"
                    }

                    // Frequency Range
                    StatRow {
                        Layout.fillWidth: true
                        icon: "swap_vert"
                        label: qsTr("Freq Range")
                        value: (Hardware.cpuFreqMin / 1000).toFixed(1) + " - " + (Hardware.cpuFreqMax / 1000).toFixed(1) + " GHz"
                    }

                    // Governor
                    StatRow {
                        Layout.fillWidth: true
                        icon: "tune"
                        label: qsTr("Governor")
                        value: Hardware.cpuGovernor
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
            // Platform Profile Section (ACPI)
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Platform Profile")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Hardware.hasPlatformProfile
            }

            StyledText {
                text: qsTr("Hardware-level power management (fan curves, TDP)")
                color: Colours.palette.m3outline
                visible: Hardware.hasPlatformProfile
            }

            StyledRect {
                Layout.fillWidth: true
                visible: Hardware.hasPlatformProfile
                implicitHeight: platformProfileLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: platformProfileLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    Repeater {
                        model: Hardware.platformProfilesAvailable

                        OptionRow {
                            required property string modelData
                            required property int index

                            Layout.fillWidth: true

                            icon: modelData === "performance" ? "whatshot" :
                                  modelData === "balanced" ? "balance" :
                                  modelData === "low-power" ? "battery_saver" :
                                  modelData === "custom" ? "tune" : "settings"
                            label: modelData === "performance" ? qsTr("Performance") :
                                   modelData === "balanced" ? qsTr("Balanced") :
                                   modelData === "low-power" ? qsTr("Low Power") :
                                   modelData === "custom" ? qsTr("Custom") : modelData
                            description: modelData === "performance" ? qsTr("Full fan speed, maximum TDP") :
                                        modelData === "balanced" ? qsTr("Dynamic fan speed, moderate TDP") :
                                        modelData === "low-power" ? qsTr("Quiet fans, reduced TDP") :
                                        modelData === "custom" ? qsTr("User-defined settings") : ""
                            isSelected: Hardware.platformProfile === modelData

                            onClicked: {
                                Hardware.setPlatformProfile(modelData);
                            }
                        }
                    }
                }
            }

            // =====================================================
            // CPU Boost Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("CPU Boost")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Hardware.cpuBoostSupported
            }

            StyledText {
                text: qsTr("Allow CPU to exceed base frequency when needed")
                color: Colours.palette.m3outline
                visible: Hardware.cpuBoostSupported
            }

            StyledRect {
                Layout.fillWidth: true
                visible: Hardware.cpuBoostSupported
                implicitHeight: boostLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                RowLayout {
                    id: boostLayout

                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.large
                    anchors.topMargin: Appearance.padding.large
                    anchors.bottomMargin: Appearance.padding.large
                    anchors.rightMargin: Appearance.padding.small
                    spacing: Appearance.spacing.normal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: qsTr("Turbo Boost")
                            font.weight: 500
                        }

                        StyledText {
                            text: Hardware.cpuBoostEnabled ? 
                                  qsTr("CPU can boost up to %1 GHz").arg((Hardware.cpuFreqMax / 1000).toFixed(1)) :
                                  qsTr("CPU limited to base frequency")
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    StyledSwitch {
                        checked: Hardware.cpuBoostEnabled
                        onToggled: {
                            Hardware.setCpuBoost(checked);
                        }
                    }
                }
            }

            // =====================================================
            // Governor Section (Advanced)
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("CPU Governor")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Hardware.cpuGovernorsAvailable.length > 0
            }

            StyledText {
                text: qsTr("Low-level frequency scaling policy")
                color: Colours.palette.m3outline
                visible: Hardware.cpuGovernorsAvailable.length > 0
            }

            StyledRect {
                Layout.fillWidth: true
                visible: Hardware.cpuGovernorsAvailable.length > 0
                implicitHeight: governorLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: governorLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    Repeater {
                        model: Hardware.cpuGovernorsAvailable

                        OptionRow {
                            required property string modelData
                            required property int index

                            Layout.fillWidth: true

                            icon: modelData === "performance" ? "bolt" :
                                  modelData === "powersave" ? "eco" :
                                  modelData === "schedutil" ? "auto_mode" :
                                  modelData === "ondemand" ? "trending_up" :
                                  modelData === "conservative" ? "trending_down" : "tune"
                            label: modelData
                            description: modelData === "performance" ? qsTr("Always run at maximum frequency") :
                                        modelData === "powersave" ? qsTr("Always run at minimum frequency") :
                                        modelData === "schedutil" ? qsTr("Scheduler-driven frequency scaling") :
                                        modelData === "ondemand" ? qsTr("Scale up quickly, scale down slowly") :
                                        modelData === "conservative" ? qsTr("Scale up and down gradually") : ""
                            isSelected: Hardware.cpuGovernor === modelData

                            onClicked: {
                                Hardware.setCpuGovernor(modelData);
                            }
                        }
                    }
                }
            }
            // =====================================================
            // C-States (CPU Idle States) - Advanced
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("CPU Idle States (C-States)")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Driver: %1").arg(Hardware.cpuIdleDriver || "N/A")
                color: Colours.palette.m3outline
            }

            // Warning Box
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: warningLayout.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.normal
                color: Qt.alpha(Colours.palette.m3error, 0.1)
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3error, 0.3)

                RowLayout {
                    id: warningLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "warning"
                        color: Colours.palette.m3error
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("⚠️ Disabling C-States can help with latency issues and system freezes (like Lenovo Legion suspend bug), but significantly increases power consumption and heat. Use with caution on laptops.")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3error
                        wrapMode: Text.WordWrap
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: cstatesLayout.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: cstatesLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    Repeater {
                        model: Hardware.cpuCStates

                        delegate: RowLayout {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledRect {
                                Layout.preferredWidth: 50
                                Layout.preferredHeight: 28
                                radius: Appearance.rounding.small
                                color: modelData.disabled ? 
                                    Qt.alpha(Colours.palette.m3error, 0.2) : 
                                    Qt.alpha(Colours.palette.m3primary, 0.2)

                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    font.pointSize: Appearance.font.size.small
                                    font.weight: 600
                                    color: modelData.disabled ? Colours.palette.m3error : Colours.palette.m3primary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    text: modelData.desc
                                    font.pointSize: Appearance.font.size.small
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: qsTr("Latency: %1µs").arg(modelData.latency)
                                    font.pointSize: Appearance.font.size.smaller
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }

                            StyledSwitch {
                                checked: !modelData.disabled
                                onToggled: {
                                    Hardware.setCState(index, !checked);
                                }
                            }
                        }
                    }

                    StyledText {
                        visible: Hardware.cpuCStates.length === 0
                        text: qsTr("No C-State information available")
                        color: Colours.palette.m3onSurfaceVariant
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

        signal clicked()

        implicitHeight: optionLayout.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: isSelected ? Colours.palette.m3primaryContainer : "transparent"

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
                color: optionRoot.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: optionRoot.label
                    font.weight: 500
                    color: optionRoot.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: optionRoot.description !== ""
                    text: optionRoot.description
                    font.pointSize: Appearance.font.size.small
                    color: optionRoot.isSelected ? Qt.alpha(Colours.palette.m3onPrimaryContainer, 0.7) : Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                }
            }

            MaterialIcon {
                visible: optionRoot.isSelected
                text: "check_circle"
                color: Colours.palette.m3onPrimaryContainer
            }
        }
    }
}
