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

    // Custom TDP values
    property int customStapm: Hardware.tdpStapmLimit
    property int customFast: Hardware.tdpFastLimit
    property int customSlow: Hardware.tdpSlowLimit

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
                text: "electric_bolt"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
                color: Colours.palette.m3tertiary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("AMD TDP Control")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("via RyzenAdj")
                color: Colours.palette.m3onSurfaceVariant
            }
            
            // Reset to Default button
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                text: qsTr("Reset to Default")
                icon: "restart_alt"
                visible: Hardware.hasRyzenAdj
                onClicked: Hardware.resetTdpToDefault()
            }

            // Not available fallback
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.extraLarge
                visible: !Hardware.hasRyzenAdj
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "warning"
                    font.pointSize: Appearance.font.size.extraLarge * 2
                    color: Colours.palette.m3error
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("RyzenAdj not available")
                    font.pointSize: Appearance.font.size.larger
                    color: Colours.palette.m3error
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Install ryzenadj for TDP control")
                    color: Colours.palette.m3outline
                }
            }

            // TDP Content
            ColumnLayout {
                Layout.fillWidth: true
                visible: Hardware.hasRyzenAdj
                spacing: Appearance.spacing.normal

                // =====================================================
                // Current TDP Status
                // =====================================================
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Current TDP Status")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: tdpStatusLayout.implicitHeight + Appearance.padding.large * 2

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    GridLayout {
                        id: tdpStatusLayout

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        columns: 2
                        rowSpacing: Appearance.spacing.normal
                        columnSpacing: Appearance.spacing.large

                        TdpStat {
                            Layout.fillWidth: true
                            label: "STAPM"
                            description: qsTr("Sustained power")
                            current: Hardware.tdpStapmValue
                            limit: Hardware.tdpStapmLimit
                        }

                        TdpStat {
                            Layout.fillWidth: true
                            label: "Fast PPT"
                            description: qsTr("Boost power")
                            current: Hardware.tdpFastValue
                            limit: Hardware.tdpFastLimit
                        }

                        TdpStat {
                            Layout.fillWidth: true
                            label: "Slow PPT"
                            description: qsTr("Average power")
                            current: Hardware.tdpSlowValue
                            limit: Hardware.tdpSlowLimit
                        }

                        TdpStat {
                            Layout.fillWidth: true
                            label: "Thermal"
                            description: qsTr("Temperature")
                            current: Hardware.tdpThermalValue
                            limit: Hardware.tdpThermalLimit
                            unit: "°C"
                        }
                    }
                }

                // =====================================================
                // TDP Presets
                // =====================================================
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("TDP Presets")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    text: qsTr("Quick power profiles for different scenarios")
                    color: Colours.palette.m3outline
                }

                // Preset buttons grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: Appearance.spacing.small
                    columnSpacing: Appearance.spacing.small

                    Repeater {
                        model: Hardware.tdpPresets

                        PresetCard {
                            Layout.fillWidth: true
                            required property var modelData
                            required property int index

                            name: modelData.name
                            stapm: modelData.stapm
                            fast: modelData.fast
                            slow: modelData.slow
                            isActive: Math.abs(Hardware.tdpStapmLimit - modelData.stapm) < 3

                            onClicked: {
                                Hardware.setTdpPreset(index);
                            }
                        }
                    }
                }

                // =====================================================
                // Custom TDP
                // =====================================================
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Custom TDP")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    text: qsTr("Fine-tune power limits (in Watts)")
                    color: Colours.palette.m3outline
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: customLayout.implicitHeight + Appearance.padding.large * 2

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: customLayout

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        // STAPM slider
                        TdpSlider {
                            Layout.fillWidth: true
                            label: "STAPM Limit"
                            description: qsTr("Sustained TDP - long-term power limit")
                            value: root.customStapm
                            from: 10
                            to: 100
                            onValueChanged: {
                                root.customStapm = value;
                            }
                        }

                        // Fast PPT slider
                        TdpSlider {
                            Layout.fillWidth: true
                            label: "Fast PPT Limit"
                            description: qsTr("Boost TDP - short burst power")
                            value: root.customFast
                            from: 15
                            to: 120
                            onValueChanged: {
                                root.customFast = value;
                            }
                        }

                        // Slow PPT slider
                        TdpSlider {
                            Layout.fillWidth: true
                            label: "Slow PPT Limit"
                            description: qsTr("Average TDP - medium-term limit")
                            value: root.customSlow
                            from: 10
                            to: 110
                            onValueChanged: {
                                root.customSlow = value;
                            }
                        }

                        // Apply button
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Appearance.spacing.small
                            spacing: Appearance.spacing.normal

                            Item { Layout.fillWidth: true }

                            TextButton {
                                text: qsTr("Reset to Current")
                                onClicked: {
                                    root.customStapm = Hardware.tdpStapmLimit;
                                    root.customFast = Hardware.tdpFastLimit;
                                    root.customSlow = Hardware.tdpSlowLimit;
                                }
                            }

                            IconTextButton {
                                icon: "check"
                                text: qsTr("Apply Custom TDP")
                                checked: true

                                onClicked: {
                                    Hardware.setTdp(root.customStapm, root.customFast, root.customSlow);
                                }
                            }
                        }
                    }
                }

                // =====================================================
                // Thermal Limit
                // =====================================================
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Thermal Limit")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: thermalLayout.implicitHeight + Appearance.padding.large * 2

                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: thermalLayout

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            MaterialIcon {
                                text: "thermostat"
                                font.pointSize: Appearance.font.size.extraLarge
                                color: Hardware.tdpThermalValue > 90 ? Colours.palette.m3error : Colours.palette.m3tertiary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: qsTr("CPU Temperature Limit")
                                    font.weight: 500
                                }

                                StyledText {
                                    text: qsTr("Current: %1°C / Limit: %2°C").arg(Hardware.tdpThermalValue.toFixed(0)).arg(Hardware.tdpThermalLimit.toFixed(0))
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: "60°C"
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledSlider {
                                id: thermalSlider
                                Layout.fillWidth: true
                                from: 60
                                to: 105
                                value: Hardware.tdpThermalLimit
                                stepSize: 5

                                onPressedChanged: {
                                    if (!pressed && value !== Hardware.tdpThermalLimit) {
                                        Hardware.setThermalLimit(Math.round(value));
                                    }
                                }
                            }

                            StyledText {
                                text: "105°C"
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }

                // Warning card
                StyledRect {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.normal
                    implicitHeight: warningRow.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3errorContainer

                    RowLayout {
                        id: warningRow
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: "warning"
                            color: Colours.palette.m3onErrorContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("TDP changes are temporary and reset on reboot. High TDP values may cause thermal throttling.")
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onErrorContainer
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Appearance.spacing.large }
        }
    }

    // =====================================================
    // COMPONENTS
    // =====================================================

    component TdpStat: ColumnLayout {
        property string label
        property string description
        property real current
        property real limit
        property string unit: "W"

        spacing: Appearance.spacing.small

        RowLayout {
            spacing: Appearance.spacing.small

            StyledText {
                text: parent.parent.label
                font.weight: 600
                color: Colours.palette.m3primary
            }

            StyledText {
                text: parent.parent.description
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                text: current.toFixed(1) + unit
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: "/ " + limit.toFixed(0) + unit
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // Progress bar
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Colours.palette.m3surfaceContainerHighest

            StyledRect {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(1, current / Math.max(1, limit)) * parent.width
                radius: parent.radius
                color: current / limit > 0.9 ? Colours.palette.m3error :
                       current / limit > 0.7 ? Colours.palette.m3tertiary : Colours.palette.m3primary
            }
        }
    }

    component PresetCard: StyledRect {
        id: presetRoot

        property string name
        property int stapm
        property int fast
        property int slow
        property bool isActive: false

        signal clicked()

        implicitHeight: presetLayout.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: isActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

        StateLayer {
            radius: presetRoot.radius
            color: isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

            onClicked: {
                presetRoot.clicked();
            }
        }

        ColumnLayout {
            id: presetLayout

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: 4

            StyledText {
                text: presetRoot.name
                font.weight: 600
                color: presetRoot.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            }

            StyledText {
                text: presetRoot.stapm + "W"
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                color: presetRoot.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
            }

            StyledText {
                text: qsTr("Fast: %1W").arg(presetRoot.fast)
                font.pointSize: Appearance.font.size.small
                color: presetRoot.isActive ? Qt.alpha(Colours.palette.m3onPrimaryContainer, 0.7) : Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component TdpSlider: ColumnLayout {
        property string label
        property string description
        property alias value: slider.value
        property alias from: slider.from
        property alias to: slider.to

        spacing: Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: parent.parent.label
                font.weight: 500
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: slider.value.toFixed(0) + "W"
                font.weight: 600
                color: Colours.palette.m3primary
            }
        }

        StyledText {
            text: parent.description
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledSlider {
            id: slider
            Layout.fillWidth: true
            stepSize: 5
        }
    }
}
