pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    required property PersistentProperties visibilities

    readonly property var categories: Keybinds.categories
    readonly property bool isLoading: Keybinds.isLoading

    implicitWidth: Math.min(900, Screen.width * 0.8)
    implicitHeight: Math.min(700, Screen.height * 0.8)
    
    radius: Appearance.rounding.large
    color: Colours.palette.m3surfaceContainer
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3outline, 0.2)

    // Block ALL clicks from propagating to scrim behind us
    MouseArea {
        id: contentBlocker
        anchors.fill: parent
        // Accept the click and do nothing - prevents propagation to parent scrim
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        // Don't propagate composed events to parent
        propagateComposedEvents: false
    }

    // Header
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.large
        spacing: Appearance.spacing.normal

        // Title row
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: "keyboard"
                font.pointSize: Appearance.font.size.larger + 4
                color: Colours.palette.m3primary
            }

            Text {
                text: qsTr("Keyboard Shortcuts")
                font.pointSize: Appearance.font.size.larger
                font.weight: Font.Bold
                font.family: Appearance.font.family.sans
                color: Colours.palette.m3onSurface
            }

            Item { Layout.fillWidth: true }

            // Close button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: closeHover.hovered ? Qt.alpha(Colours.palette.m3primary, 0.1) : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }

                HoverHandler { id: closeHover }
                TapHandler { onTapped: root.visibilities.keybinds = false }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
        }

        // Loading indicator
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.isLoading

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.normal

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: root.isLoading
                }

                Text {
                    text: qsTr("Loading keybinds...")
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Categories
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.isLoading
            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: parent.width
                spacing: Appearance.spacing.large

                Repeater {
                    model: ["workspace", "window", "apps", "media", "system", "other"]

                    ColumnLayout {
                        id: categorySection
                        required property string modelData
                        
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small
                        visible: root.categories[modelData]?.length > 0

                        // Category header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: Keybinds.getCategoryIcon(categorySection.modelData)
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3primary
                            }

                            Text {
                                text: Keybinds.getCategoryName(categorySection.modelData)
                                font.pointSize: Appearance.font.size.normal
                                font.weight: Font.DemiBold
                                font.family: Appearance.font.family.sans
                                color: Colours.palette.m3primary
                            }

                            Text {
                                text: `(${root.categories[categorySection.modelData]?.length ?? 0})`
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            Item { Layout.fillWidth: true }
                        }

                        // Keybinds grid - 2 columns for better readability
                        Grid {
                            Layout.fillWidth: true
                            columns: 2
                            spacing: Appearance.spacing.small
                            
                            Repeater {
                                model: root.categories[categorySection.modelData] ?? []

                                KeybindItem {
                                    required property var modelData
                                    bind: modelData
                                    width: (root.implicitWidth - Appearance.spacing.large * 2 - Appearance.spacing.small) / 2
                                }
                            }
                        }
                    }
                }
            }
        }

        // Footer
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            Text {
                text: qsTr("%1 shortcuts").arg(Keybinds.binds.length)
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item { Layout.fillWidth: true }

            Text {
                text: qsTr("Press Escape to close")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
                opacity: 0.7
            }
        }
    }
}
