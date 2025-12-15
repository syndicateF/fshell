pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
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
                text: "tune"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
                color: Colours.palette.m3secondary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Quick Profiles")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("One-click system optimization")
                color: Colours.palette.m3onSurfaceVariant
            }

            // =====================================================
            // Profile Cards
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Available Profiles")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Apply settings and launch apps for different scenarios")
                color: Colours.palette.m3outline
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                Repeater {
                    model: Hardware.appProfiles

                    ProfileCard {
                        Layout.fillWidth: true
                        required property var modelData
                        required property int index

                        profileIndex: index
                        name: modelData.name
                        icon: modelData.icon
                        description: modelData.description
                        actions: modelData.actions
                        apps: modelData.apps

                        onApply: {
                            Hardware.applyProfile(index);
                        }
                    }
                }
            }

            // =====================================================
            // Current Status
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Current System State")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: stateLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                GridLayout {
                    id: stateLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    columns: 2
                    rowSpacing: Appearance.spacing.normal
                    columnSpacing: Appearance.spacing.large

                    StateItem {
                        Layout.fillWidth: true
                        icon: "bolt"
                        label: qsTr("Power Mode")
                        value: Hardware.customPowerMode
                        valueColor: Hardware.customPowerMode === "performance" ? Colours.palette.m3error :
                                   Hardware.customPowerMode === "balanced" ? Colours.palette.m3tertiary : Colours.palette.m3primary
                    }

                    StateItem {
                        Layout.fillWidth: true
                        icon: "speed"
                        label: qsTr("CPU Boost")
                        value: Hardware.cpuBoostEnabled ? qsTr("Enabled") : qsTr("Disabled")
                        valueColor: Hardware.cpuBoostEnabled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }

                    StateItem {
                        Layout.fillWidth: true
                        icon: "battery_saver"
                        label: qsTr("Conservation Mode")
                        value: Hardware.conservationMode ? qsTr("On (60%)") : qsTr("Off (100%)")
                        valueColor: Hardware.conservationMode ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }

                    StateItem {
                        Layout.fillWidth: true
                        icon: "videogame_asset"
                        label: qsTr("GPU Mode")
                        value: Hardware.gpuMode
                    }
                }
            }

            Item { Layout.preferredHeight: Appearance.spacing.large }
        }
    }

    // =====================================================
    // COMPONENTS
    // =====================================================

    component ProfileCard: StyledRect {
        id: profileCard

        property int profileIndex
        property string name
        property string icon
        property string description
        property var actions: []
        property var apps: []

        signal apply()

        implicitHeight: profileLayout.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: profileLayout

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledRect {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: profileCard.icon
                        font.pointSize: Appearance.font.size.larger
                        color: Colours.palette.m3onPrimaryContainer
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: profileCard.name
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 600
                    }

                    StyledText {
                        text: profileCard.description
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                IconTextButton {
                    icon: "play_arrow"
                    text: qsTr("Apply")
                    checked: true

                    onClicked: {
                        profileCard.apply();
                    }
                }
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.large

                // Settings changes
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: qsTr("Settings")
                        font.pointSize: Appearance.font.size.small
                        font.weight: 500
                        color: Colours.palette.m3primary
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: profileCard.actions

                            StyledRect {
                                required property var modelData
                                
                                implicitWidth: actionText.implicitWidth + Appearance.padding.small * 2
                                implicitHeight: actionText.implicitHeight + 4
                                radius: Appearance.rounding.small
                                color: Colours.palette.m3surfaceContainerHighest

                                StyledText {
                                    id: actionText
                                    anchors.centerIn: parent
                                    text: {
                                        switch (modelData.type) {
                                            case "power_profile": return "⚡ " + modelData.value;
                                            case "cpu_boost": return modelData.value ? "🚀 Boost ON" : "🐌 Boost OFF";
                                            case "conservation_mode": return modelData.value ? "🔋 60% limit" : "🔌 Full charge";
                                            default: return modelData.type;
                                        }
                                    }
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Apps to launch
                ColumnLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    visible: profileCard.apps.length > 0
                    spacing: 4

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Launch Apps")
                        font.pointSize: Appearance.font.size.small
                        font.weight: 500
                        color: Colours.palette.m3secondary
                    }

                    Flow {
                        Layout.alignment: Qt.AlignRight
                        layoutDirection: Qt.RightToLeft
                        spacing: 4

                        Repeater {
                            model: profileCard.apps

                            StyledRect {
                                required property string modelData
                                
                                implicitWidth: appText.implicitWidth + Appearance.padding.small * 2
                                implicitHeight: appText.implicitHeight + 4
                                radius: Appearance.rounding.small
                                color: Colours.palette.m3secondaryContainer

                                StyledText {
                                    id: appText
                                    anchors.centerIn: parent
                                    text: "📱 " + modelData
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSecondaryContainer
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component StateItem: RowLayout {
        property string icon
        property string label
        property string value
        property color valueColor: Colours.palette.m3onSurface

        spacing: Appearance.spacing.small

        MaterialIcon {
            text: parent.icon
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
}
