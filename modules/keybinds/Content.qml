pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
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

    implicitWidth: Math.min(1200, Screen.width * 0.85)
    implicitHeight: Math.min(700, Screen.height * 0.8)
    
    radius: 8
    color: Colours.palette.m3surface

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

        // Search bar - matches launcher style
        StyledRect {
            Layout.fillWidth: true
            color: Colours.tPalette.m3surfaceContainer
            radius: Appearance.rounding.full
            implicitHeight: Math.max(searchIcon.implicitHeight, searchField.implicitHeight, clearIcon.implicitHeight)

            MaterialIcon {
                id: searchIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Appearance.spacing.normal
                text: "search"
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledTextField {
                id: searchField
                anchors.left: searchIcon.right
                anchors.right: clearIcon.left
                anchors.leftMargin: Appearance.spacing.small
                anchors.rightMargin: Appearance.spacing.small
                topPadding: Appearance.padding.normal
                bottomPadding: Appearance.padding.normal
                placeholderText: qsTr("Search shortcuts...")
                
                // Debounce search input to prevent lag during rapid typing
                onTextChanged: searchDebounce.restart()
                
                Component.onCompleted: {
                    Qt.callLater(() => searchField.forceActiveFocus());
                }
            }
            
            // Debounce timer for search (100ms delay) - no animation
            Timer {
                id: searchDebounce
                interval: 100
                onTriggered: root.searchQuery = searchField.text
            }

            MaterialIcon {
                id: clearIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Appearance.spacing.normal
                width: searchField.text ? implicitWidth : 0
                opacity: searchField.text ? (clearMouse.pressed ? 0.7 : (clearMouse.containsMouse ? 0.8 : 1)) : 0
                text: "close"
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3onSurfaceVariant

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: searchField.text ? Qt.PointingHandCursor : undefined
                    onClicked: {
                        searchField.text = "";
                        searchField.forceActiveFocus();
                    }
                }

                Behavior on width { Anim { duration: Appearance.anim.durations.small } }
                Behavior on opacity { Anim { duration: Appearance.anim.durations.small } }
            }
        }

        // Keyboard layout warning banner
        Rectangle {
            Layout.fillWidth: true
            visible: Keybinds.showLayoutWarning
            implicitHeight: warningContent.implicitHeight + Appearance.spacing.small * 2
            radius: Appearance.rounding.small
            color: Qt.alpha(Colours.palette.m3errorContainer, 0.8)
            
            Row {
                id: warningContent
                anchors.centerIn: parent
                spacing: Appearance.spacing.small
                
                MaterialIcon {
                    text: "warning"
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onErrorContainer
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: qsTr("Multiple keyboard layouts detected. Key symbols may not match your current layout.")
                    font.pointSize: Appearance.font.size.small
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onErrorContainer
                    anchors.verticalCenter: parent.verticalCenter
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

                    // Category section (simple, no accent colors or borders)
                    Item {
                        id: categoryCard
                        required property string modelData
                        required property int index
                        
                        Layout.fillWidth: true
                        visible: root.filteredCategories[modelData]?.length > 0
                        
                        // Card dimensions
                        implicitHeight: categoryContent.implicitHeight + Appearance.spacing.small * 2
                        
                        // Staggered fade-in animation
                        opacity: 0
                        Component.onCompleted: fadeIn.start()
                        
                        SequentialAnimation {
                            id: fadeIn
                            PauseAnimation { duration: categoryCard.index * 50 }
                            NumberAnimation {
                                target: categoryCard
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        ColumnLayout {
                            id: categoryContent
                            anchors.fill: parent
                            anchors.margins: Appearance.spacing.small
                            spacing: Appearance.spacing.small

                            // Category header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small

                                MaterialIcon {
                                    text: Keybinds.getCategoryIcon(categoryCard.modelData)
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                Text {
                                    text: Keybinds.getCategoryName(categoryCard.modelData)
                                    font.pointSize: Appearance.font.size.normal
                                    font.weight: Font.DemiBold
                                    font.family: Appearance.font.family.sans
                                    color: Colours.palette.m3onSurface
                                }

                                Text {
                                    text: `(${root.filteredCategories[categoryCard.modelData]?.length ?? 0})`
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                Item { Layout.fillWidth: true }
                            }

                            // Grid layout with vertical items
                            Grid {
                                id: keybindGrid
                                Layout.fillWidth: true
                                columns: 6
                                spacing: Appearance.spacing.small
                                
                                readonly property real itemWidth: (width - (spacing * (columns - 1))) / columns
                                
                                Repeater {
                                    model: root.filteredCategories[categoryCard.modelData] ?? []

                                    KeybindItem {
                                        required property var modelData
                                        required property int index
                                        bind: modelData
                                        width: keybindGrid.itemWidth
                                        animationDelay: index * 10
                                    }
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
