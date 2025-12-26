pragma ComponentBehavior: Bound

import "services"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities
    required property var panels
    required property real maxHeight

    readonly property int padding: 40  // Fixed 40px padding horizontal & vertical
    readonly property int rounding: Appearance.rounding.large
    readonly property int innerPadding: Appearance.padding.large

    // Tab state: 0=Apps, 1=Commands, 2=Calc, 3=Schemes, 4=Wallpapers, 5=Variants
    property int currentTab: 0

    // Dynamic width/height based on content
    implicitWidth: gridContent.implicitWidth + padding * 2
    implicitHeight: searchWrapper.implicitHeight + gridContent.implicitHeight + tabBar.implicitHeight + padding * 2 + Appearance.spacing.large * 2

    // Smooth animation for height changes
    Behavior on implicitHeight {
        enabled: root.visibilities.launcher
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }


    // Reset tab and cleanup when launcher closes
    Connections {
        target: root.visibilities

        function onLauncherChanged(): void {
            if (!root.visibilities.launcher) {
                root.currentTab = 0;
                // Reset visited tabs flags to free memory from lazy-loaded components
                gridContent.tab1Visited = false;
                gridContent.tab2Visited = false;
                gridContent.tab3Visited = false;
                gridContent.tab4Visited = false;
                gridContent.tab5Visited = false;
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SEARCH BAR (TOP)
    // ═══════════════════════════════════════════════════════════════
    StyledRect {
        id: searchWrapper

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.padding

        implicitHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearIcon.implicitHeight)

        MaterialIcon {
            id: searchIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Config.launcher.sizes.padding.searchBarHorizontal

            text: "search"
            font.pointSize: Config.launcher.sizes.font.searchBarIcon
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledTextField {
            id: search

            anchors.left: searchIcon.right
            anchors.right: clearIcon.left
            anchors.leftMargin: Appearance.spacing.small
            anchors.rightMargin: Appearance.spacing.small

            topPadding: Appearance.padding.normal
            bottomPadding: Appearance.padding.normal

            placeholderText: {
                const tabNames = ["apps", "commands", "calculator", "schemes", "wallpapers", "variants"];
                return qsTr("Search %1...").arg(tabNames[root.currentTab] || "");
            }

            onAccepted: {
                const currentItem = gridContent.currentList?.currentItem;
                if (currentItem) {
                    switch (root.currentTab) {
                        case 0: // Apps - ONLY apps close launcher
                            Apps.launch(currentItem.modelData);
                            root.visibilities.launcher = false;
                            break;
                        case 1: // Commands
                            currentItem.modelData.onClicked(gridContent);
                            break;
                        case 2: // Calc
                            currentItem.onClicked();
                            break;
                        case 3: // Schemes - don't close
                            currentItem.modelData.onClicked(gridContent);
                            break;
                        case 4: // Wallpapers - don't close
                            if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                                Wallpapers.previewColourLock = true;
                            Wallpapers.setWallpaper(currentItem.modelData.path);
                            break;
                        case 5: // Variants - don't close
                            currentItem.modelData.onClicked(gridContent);
                            break;
                    }
                }
            }

            // Grid navigation
            Keys.onUpPressed: gridContent.navigateUp()
            Keys.onDownPressed: gridContent.navigateDown()
            Keys.onLeftPressed: gridContent.navigateLeft()
            Keys.onRightPressed: gridContent.navigateRight()

            Keys.onEscapePressed: root.visibilities.launcher = false

            Keys.onPressed: event => {
                // Tab switching with Shift + < / >
                if (event.modifiers & Qt.ShiftModifier) {
                    if (event.key === Qt.Key_Greater || event.key === Qt.Key_Period) {
                        // Shift + > : Next tab
                        root.currentTab = (root.currentTab + 1) % 6;
                        event.accepted = true;
                        return;
                    } else if (event.key === Qt.Key_Less || event.key === Qt.Key_Comma) {
                        // Shift + < : Previous tab
                        root.currentTab = (root.currentTab + 5) % 6;
                        event.accepted = true;
                        return;
                    }
                }

                // Vim keybinds
                if (Config.launcher.vimKeybinds) {
                    if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_J) {
                            gridContent.navigateDown();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_K) {
                            gridContent.navigateUp();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_H) {
                            gridContent.navigateLeft();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_L) {
                            gridContent.navigateRight();
                            event.accepted = true;
                        }
                    }
                }
            }

            Component.onCompleted: forceActiveFocus()

            Connections {
                target: root.visibilities

                function onLauncherChanged(): void {
                    if (!root.visibilities.launcher)
                        search.text = "";
                    else
                        search.forceActiveFocus();
                }

                function onFullscreenSessionChanged(): void {
                    if (!root.visibilities.fullscreenSession)
                        search.forceActiveFocus();
                }
            }
        }

        MaterialIcon {
            id: clearIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Config.launcher.sizes.padding.searchBarHorizontal

            width: search.text ? implicitWidth : implicitWidth / 2
            opacity: {
                if (!search.text)
                    return 0;
                if (clearMouse.pressed)
                    return 0.7;
                if (clearMouse.containsMouse)
                    return 0.8;
                return 1;
            }

            text: "close"
            font.pointSize: Config.launcher.sizes.font.searchBarIcon
            color: Colours.palette.m3onSurfaceVariant

            MouseArea {
                id: clearMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: search.text ? Qt.PointingHandCursor : undefined

                onClicked: search.text = ""
            }

            Behavior on width {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB BAR (BOTTOM)
    // ═══════════════════════════════════════════════════════════════
    TabBar {
        id: tabBar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.bottomMargin: root.padding

        currentTab: root.currentTab

        onTabChanged: index => {
            root.currentTab = index;
            search.forceActiveFocus();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // GRID CONTENT (MIDDLE - BETWEEN SEARCH AND TAB BAR)
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: gridWrapper

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchWrapper.bottom
        anchors.bottom: tabBar.top
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.topMargin: Appearance.spacing.large
        anchors.bottomMargin: Appearance.spacing.large

        // Use gridContent's actual dimensions
        implicitWidth: gridContent.implicitWidth
        implicitHeight: gridContent.implicitHeight
        height: implicitHeight

        clip: true

        GridContent {
            id: gridContent

            width: implicitWidth
            height: implicitHeight

            content: root
            visibilities: root.visibilities
            panels: root.panels
            search: search
            currentTab: root.currentTab
            padding: root.padding
            rounding: root.rounding
        }

        // Empty state
        Row {
            id: empty

            opacity: gridContent.currentList?.count === 0 ? 1 : 0
            scale: gridContent.currentList?.count === 0 ? 1 : 0.5
            visible: opacity > 0

            spacing: Appearance.spacing.small
            padding: Appearance.padding.normal

            anchors.centerIn: parent

            MaterialIcon {
                text: "manage_search"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.large

                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: qsTr("No results")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal

                anchors.verticalCenter: parent.verticalCenter
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
    }
}
