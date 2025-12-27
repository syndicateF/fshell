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

    // Search query
    property string searchQuery: ""
    
    // Filtered categories based on search
    readonly property var filteredCategories: {
        if (searchQuery.trim() === "") {
            return Keybinds.categories;
        }
        
        const query = searchQuery.toLowerCase().trim();
        const result = {
            window: [],
            workspace: [],
            apps: [],
            system: [],
            media: [],
            other: []
        };
        
        // Filter each category
        for (const cat of Object.keys(result)) {
            const items = Keybinds.categories[cat] ?? [];
            result[cat] = items.filter(bind => {
                const desc = (bind.description ?? "").toLowerCase();
                const key = (bind.key ?? "").toLowerCase();
                const arg = (bind.arg ?? "").toLowerCase();
                return desc.includes(query) || key.includes(query) || arg.includes(query);
            });
        }
        
        return result;
    }

    // Header with search bar
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.large
        spacing: Appearance.spacing.normal

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: Appearance.rounding.full
            color: Colours.palette.m3surfaceContainerHighest
            border.width: searchField.activeFocus ? 2 : 0
            border.color: Colours.palette.m3primary

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.normal
                anchors.rightMargin: Appearance.spacing.normal
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "search"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                }

                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    font.pointSize: Appearance.font.size.normal
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurface
                    clip: true
                    
                    onTextChanged: root.searchQuery = text
                    
                    // Placeholder
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 0
                        verticalAlignment: Text.AlignVCenter
                        text: qsTr("Search shortcuts...")
                        font: searchField.font
                        color: Colours.palette.m3onSurfaceVariant
                        opacity: 0.6
                        visible: searchField.text.length === 0 && !searchField.activeFocus
                    }
                    
                    // Focus on open
                    Component.onCompleted: {
                        Qt.callLater(() => searchField.forceActiveFocus());
                    }
                }

                // Clear button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    visible: searchField.text.length > 0
                    color: clearHover.hovered ? Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.1) : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "close"
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    HoverHandler { id: clearHover }
                    TapHandler { onTapped: { searchField.text = ""; searchField.forceActiveFocus(); } }
                }
            }
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
                        visible: root.filteredCategories[modelData]?.length > 0

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
                                text: `(${root.filteredCategories[categorySection.modelData]?.length ?? 0})`
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
                                model: root.filteredCategories[categorySection.modelData] ?? []

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
