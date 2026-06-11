pragma ComponentBehavior: Bound

import "../launcher/items"
import "../launcher/services"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick

/**
 * AppGrid Content — fullscreen grid with its own search bar.
 * Completely independent from the launcher module.
 */
Item {
    id: root

    required property PersistentProperties visibilities
    required property ShellScreen screen

    property string searchText: ""

    readonly property int _searchBarMaxWidth: 640
    readonly property int _searchBarPadding:  8

    // ── Search bar ────────────────────────────────────────────────────
    Rectangle {
        id: searchBar

        anchors.top: parent.top
        anchors.topMargin: Math.floor(root.height * 0.04)
        anchors.horizontalCenter: parent.horizontalCenter

        width: Math.min(root._searchBarMaxWidth, root.width - 80)
        height: searchRow.implicitHeight + root._searchBarPadding * 2

        color:  Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.normal

        Row {
            id: searchRow

            anchors.fill: parent
            anchors.leftMargin:   Appearance.padding.large
            anchors.rightMargin:  Appearance.padding.normal
            anchors.topMargin:    root._searchBarPadding
            anchors.bottomMargin: root._searchBarPadding
            spacing: Appearance.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text:           "search"
                font.pointSize: Config.launcher.sizes.font.searchBarIcon
                color:          Colours.palette.m3onSurfaceVariant
            }

            StyledTextField {
                id: searchField

                width: parent.width
                       - parent.children[0].width - parent.spacing
                       - (clearIcon.visible ? clearIcon.width + parent.spacing : 0)
                anchors.verticalCenter: parent.verticalCenter

                topPadding:    Appearance.padding.small
                bottomPadding: Appearance.padding.small

                placeholderText: qsTr("Search apps...")

                onTextChanged: root.searchText = text

                onAccepted: {
                    // Launch first result on Enter
                    if (root.searchText.length > 0) {
                        const results = Apps.search(root.searchText);
                        if (results.length > 0) {
                            Apps.launch(results[0]);
                            root.visibilities.appgrid = false;
                        }
                    }
                }

                Keys.onEscapePressed: {
                    root.visibilities.appgrid = false;
                }

                Component.onCompleted: forceActiveFocus()

                Connections {
                    target: root.visibilities
                    function onAppgridChanged(): void {
                        if (root.visibilities.appgrid)
                            searchField.forceActiveFocus();
                    }
                }
            }

            MaterialIcon {
                id: clearIcon

                anchors.verticalCenter: parent.verticalCenter

                width:   searchField.text ? implicitWidth : 0
                opacity: searchField.text ? 1 : 0
                visible: opacity > 0
                clip:    true

                text:           "close"
                font.pointSize: Config.launcher.sizes.font.searchBarIcon
                color:          Colours.palette.m3onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        searchField.text = "";
                        searchField.forceActiveFocus();
                    }
                }

                Behavior on width   { Anim { duration: Appearance.anim.durations.small } }
                Behavior on opacity { Anim { duration: Appearance.anim.durations.small } }
            }
        }
    }

    // ── Workspace Preview Strip ─────────────────────────────────────
    WorkspaceStrip {
        id: workspaceStrip

        anchors.top:              searchBar.bottom
        anchors.topMargin:        Appearance.padding.normal
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(root.width - 160, 1600)

        screen:       root.screen
        searchText:   root.searchText
        visibilities: root.visibilities
    }

    // ── App Grid ──────────────────────────────────────────────────────
    AppGrid {
        id: appGrid

        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    workspaceStrip.bottom
        anchors.topMargin: workspaceStrip.visible ? 0 : Appearance.padding.normal
        anchors.bottom: parent.bottom

        appList: root.searchText.length > 0
            ? Apps.search(root.searchText)
            : Apps.list

        onAppLaunched: app => {
            Apps.launch(app?.entry ?? app);
            root.visibilities.appgrid = false;
        }
    }
}
