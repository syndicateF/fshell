pragma ComponentBehavior: Bound

import "items"
import "services"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities
    required property ShellScreen screen

    property string searchText: ""

    readonly property int contentWidth: 500
    readonly property int maxResultsHeight: 550
    readonly property int searchBarHeight: 48
    readonly property int searchBarPadding: 8

    implicitWidth: contentWidth + searchBarPadding * 2
    implicitHeight: searchWrapper.implicitHeight + (resultsWrapper.visible ? resultsWrapper.implicitHeight + Appearance.spacing.normal : 0)

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    // Reset when launcher opens
    Connections {
        target: root.visibilities

        function onLauncherChanged(): void {
            if (root.visibilities.launcher) {
                search.text = "";
                root.searchText = "";
                search.forceActiveFocus();
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SEARCH BAR (pill-shaped, with shadow)
    // ═══════════════════════════════════════════════════════════════
    Elevation {
        anchors.fill: searchWrapper
        radius: searchWrapper.radius
        level: 3
    }

    StyledRect {
        id: searchWrapper

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        implicitHeight: searchRow.implicitHeight + root.searchBarPadding * 2

        Row {
            id: searchRow

            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.normal
            anchors.topMargin: root.searchBarPadding
            anchors.bottomMargin: root.searchBarPadding

            spacing: Appearance.spacing.small

            // Search icon
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                font.pointSize: Config.launcher.sizes.font.searchBarIcon
                color: Colours.palette.m3onSurfaceVariant
            }

            // Search text field
            StyledTextField {
                id: search

                width: parent.width - parent.children[0].implicitWidth - clearIcon.implicitWidth - parent.spacing * 3
                anchors.verticalCenter: parent.verticalCenter

                topPadding: Appearance.padding.small
                bottomPadding: Appearance.padding.small

                placeholderText: qsTr("Search apps...")

                onTextChanged: root.searchText = text

                onAccepted: {
                    if (appResultsList.currentItem?.modelData) {
                        Apps.launch(appResultsList.currentItem.modelData);
                        root.visibilities.launcher = false;
                    }
                }

                Keys.onUpPressed: {
                    if (appResultsList.currentIndex > 0)
                        appResultsList.currentIndex--;
                }
                Keys.onDownPressed: {
                    if (appResultsList.currentIndex < appResultsList.count - 1)
                        appResultsList.currentIndex++;
                }

                Keys.onEscapePressed: root.visibilities.launcher = false

                // Vim keybinds
                Keys.onPressed: event => {
                    if (Config.launcher.vimKeybinds && (event.modifiers & Qt.ControlModifier)) {
                        if (event.key === Qt.Key_J) {
                            if (appResultsList.currentIndex < appResultsList.count - 1)
                                appResultsList.currentIndex++;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_K) {
                            if (appResultsList.currentIndex > 0)
                                appResultsList.currentIndex--;
                            event.accepted = true;
                        }
                    }
                }

                Component.onCompleted: forceActiveFocus()

                Connections {
                    target: root.visibilities

                    function onLauncherChanged(): void {
                        if (root.visibilities.launcher)
                            search.forceActiveFocus();
                    }
                }
            }

            // Clear button
            MaterialIcon {
                id: clearIcon

                anchors.verticalCenter: parent.verticalCenter

                width: search.text ? implicitWidth : 0
                opacity: search.text ? 1 : 0
                visible: opacity > 0
                clip: true

                text: "close"
                font.pointSize: Config.launcher.sizes.font.searchBarIcon
                color: Colours.palette.m3onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: search.text = ""
                }

                Behavior on width { Anim { duration: Appearance.anim.durations.small } }
                Behavior on opacity { Anim { duration: Appearance.anim.durations.small } }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // RESULTS AREA
    // ═══════════════════════════════════════════════════════════════
    Elevation {
        anchors.fill: resultsWrapper
        radius: resultsWrapper.radius
        level: 2
        visible: resultsWrapper.visible
    }

    StyledRect {
        id: resultsWrapper

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchWrapper.bottom
        anchors.topMargin: Appearance.spacing.normal

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large

        visible: root.searchText.length > 0

        implicitHeight: resultsContent.implicitHeight

        Behavior on implicitHeight {
            enabled: root.visibilities.launcher
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        clip: true

        Item {
            id: resultsContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            implicitHeight: Math.min(root.maxResultsHeight, appResultsList.contentHeight + Appearance.padding.normal * 2)

            // App results (vertical list)
            ListView {
                id: appResultsList

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 100

                model: ScriptModel {
                    values: Apps.search(root.searchText)
                    onValuesChanged: appResultsList.currentIndex = 0
                }

                delegate: SearchResultItem {
                    id: resultDelegate

                    width: appResultsList.width
                    isSelected: ListView.isCurrentItem
                    searchQuery: root.searchText

                    onClicked: {
                        appResultsList.currentIndex = resultDelegate.index;
                        Apps.launch(resultDelegate.modelData);
                        root.visibilities.launcher = false;
                    }

                    onHovered: appResultsList.currentIndex = resultDelegate.index
                }
            }

            // Empty state
            Row {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small
                visible: appResultsList.count === 0 && root.searchText.length > 0
                opacity: visible ? 1 : 0

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

                Behavior on opacity { Anim {} }
            }
        }
    }
}
