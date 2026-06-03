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
    property bool showAll: false

    readonly property int contentWidth:     640
    readonly property int maxResultsHeight: 550
    readonly property int searchBarPadding: 8
    readonly property int outerPadding:     8

    implicitWidth:  contentWidth
    implicitHeight: outerContainer.height

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher
        Anim {
            duration:           Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    // Reset when launcher opens
    Connections {
        target: root.visibilities

        function onLauncherChanged(): void {
            if (root.visibilities.launcher) {
                search.text     = "";
                root.searchText = "";
                root.showAll    = false;
                search.forceActiveFocus();
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SHADOW — under the single outer container
    // ═══════════════════════════════════════════════════════════════
    Elevation {
        anchors.fill: outerContainer
        radius:       outerContainer.radius
        level:        3
    }

    // ═══════════════════════════════════════════════════════════════
    // OUTER CONTAINER — one background wrapping search + results
    // ═══════════════════════════════════════════════════════════════
    StyledRect {
        id: outerContainer

        anchors.left:  parent.left
        anchors.right: parent.right
        anchors.top:   parent.top

        color:  Colours.palette.m3surface
        radius: Appearance.rounding.large
        clip:   true

        // Height = search bar + results (if visible)
        height: searchBarBorder.height
                + root.outerPadding * 2
                + ((root.searchText.length > 0 || root.showAll) ? resultsArea.height : 0)

        Behavior on height {
            enabled: root.visibilities.launcher
            Anim {
                duration:           Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        // ── Search bar: outline-only, no background ─────────────────
        Rectangle {
            id: searchBarBorder

            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.leftMargin:  root.outerPadding
            anchors.rightMargin: root.outerPadding
            anchors.topMargin:   root.outerPadding

            height: searchBarRow.implicitHeight + root.searchBarPadding * 2

            color:        Colours.tPalette.m3surfaceContainer
            radius:       Appearance.rounding.normal
            // border.color: Colours.palette.m3outline
            // border.width: 1

            Row {
                id: searchBarRow

                anchors.fill:         parent
                anchors.leftMargin:   Appearance.padding.large
                anchors.rightMargin:  Appearance.padding.normal
                anchors.topMargin:    root.searchBarPadding
                anchors.bottomMargin: root.searchBarPadding
                spacing:              Appearance.spacing.small

                // Search icon
                MaterialIcon {
                    id: searchIcon
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "search"
                    font.pointSize: Config.launcher.sizes.font.searchBarIcon
                    color:          Colours.palette.m3onSurfaceVariant
                }

                // Search text field
                StyledTextField {
                    id: search

                    width: parent.width
                           - searchIcon.width - parent.spacing
                           - (clearIcon.visible ? clearIcon.width + parent.spacing : 0)
                           - appsIcon.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter

                    topPadding:    Appearance.padding.small
                    bottomPadding: Appearance.padding.small

                    placeholderText: qsTr("Type to search apps or type \"?\" for more options...")

                    onTextChanged: {
                        root.searchText = text;
                        if (text.length > 0) root.showAll = false;
                    }

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

                    width:   search.text ? implicitWidth : 0
                    opacity: search.text ? 1 : 0
                    visible: opacity > 0
                    clip:    true

                    text:           "close"
                    font.pointSize: Config.launcher.sizes.font.searchBarIcon
                    color:          Colours.palette.m3onSurfaceVariant

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    search.text = ""
                    }

                    Behavior on width   { Anim { duration: Appearance.anim.durations.small } }
                    Behavior on opacity { Anim { duration: Appearance.anim.durations.small } }
                }

                // Show all apps button
                MaterialIcon {
                    id: appsIcon
                    
                    anchors.verticalCenter: parent.verticalCenter
                    
                    text:           "apps"
                    font.pointSize: Config.launcher.sizes.font.searchBarIcon
                    color:          root.showAll && root.searchText.length === 0 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            if (root.searchText.length === 0) {
                                root.showAll = !root.showAll;
                            } else {
                                search.text = "";
                                root.showAll = true;
                            }
                        }
                    }
                }
            }
        }

        // ── Results list — sits directly inside outerContainer ───────
        Item {
            id: resultsArea

            anchors.left:  parent.left
            anchors.right: parent.right
            anchors.top:   searchBarBorder.bottom

            visible: root.searchText.length > 0 || root.showAll
            opacity: visible ? 1 : 0

            Behavior on opacity { Anim { duration: Appearance.anim.durations.small } }

            // Use a plain property to compute desired height — avoids
            // assigning to read-only implicitHeight on Item
            readonly property int desiredHeight: Math.min(
                root.maxResultsHeight,
                appResultsList.contentHeight + Appearance.padding.normal * 2
            )
            height: visible ? desiredHeight : 0

            ListView {
                id: appResultsList

                anchors.fill:    parent
                anchors.margins: Appearance.padding.normal

                clip:                  true
                spacing:               0
                boundsBehavior:        Flickable.StopAtBounds
                highlightMoveDuration: 100

                model: ScriptModel {
                    values: (root.showAll && root.searchText.length === 0) ? Apps.list : Apps.search(root.searchText)
                    onValuesChanged: appResultsList.currentIndex = 0
                }

                delegate: SearchResultItem {
                    id: resultDelegate

                    width:       appResultsList.width
                    isSelected:  ListView.isCurrentItem
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
                    text:           "manage_search"
                    color:          Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.large
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text:           qsTr("No results")
                    color:          Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                    anchors.verticalCenter: parent.verticalCenter
                }

                Behavior on opacity { Anim {} }
            }
        }
    }
}
