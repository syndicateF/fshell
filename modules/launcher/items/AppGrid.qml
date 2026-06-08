pragma ComponentBehavior: Bound

import "../services"
import qs.components
import qs.config
import qs.services
import Quickshell
import QtQuick


Item {
    id: root

    required property var appList

    signal appLaunched(var app)

    property var _apps: []

    function _rebuildApps() {
        var result = [];
        if (!root.appList) { root._apps = []; return; }
        for (var i = 0; i < root.appList.length; i++) {
            if (root.appList[i]) result.push(root.appList[i]);
        }
        root._apps = result;
    }

    onAppListChanged: _rebuildApps()
    Component.onCompleted: _rebuildApps()

    // ── Config ────────────────────────────────────────────────────────
    readonly property int _cols:    Config.launcher.appGrid.columns
    readonly property int _rows:    Config.launcher.appGrid.rows
    readonly property int _iconSz:  Config.launcher.appGrid.iconSize
    readonly property int _spacing: Config.launcher.appGrid.spacing

    // ── Cell size = content + spacing ─────────────────────────────────
    readonly property int _contentW: _iconSz + Config.launcher.appGrid.contentW
    readonly property int _contentH: _iconSz + Config.launcher.appGrid.contentH
    readonly property int _cellW: _contentW + _spacing
    readonly property int _cellH: _contentH + _spacing

    // ── Page layout ──────────────────────────────────────────────────
    // Each page holds exactly _cols × _rows apps, laid out in a fixed grid.
    // Pages are arranged side-by-side horizontally; the ListView snaps
    // one full page at a time (horizontal carousel / pager).
    readonly property int _appsPerPage: _cols * _rows
    readonly property int _pageCount:   Math.max(1, Math.ceil(_apps.length / _appsPerPage))

    // ── Dot indicator dimensions ──────────────────────────────────────
    readonly property int _dotSize:    8
    readonly property int _dotSpacing: 6
    readonly property int _dotBarH:    _dotSize + 12   // vertical room for dots + breathing space

    // ── Grid dimensions (one page) ───────────────────────────────────
    readonly property int _gridW: _cols * _cellW
    readonly property int _gridH: _rows * _cellH

    // ── Horizontal centering margin (grid centred inside page width) ──
    readonly property int _marginH: Math.max(0, Math.floor((width - _gridW) / 2))

    // ── Vertical centering margin (grid centred in available height above dots) ──
    readonly property int _availH:   height - _dotBarH
    readonly property int _marginV:  Math.max(0, Math.floor((_availH - _gridH) / 2))

    // ── Page carousel ────────────────────────────────────────────────
    ListView {
        id: pageView

        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: dotRow.top

        orientation:          ListView.Horizontal
        snapMode:             ListView.SnapOneItem
        highlightMoveDuration: 300
        highlightRangeMode:   ListView.StrictlyEnforceRange
        boundsBehavior:       Flickable.StopAtBounds
        clip:                 true

        // Disable the default blue highlight rectangle
        highlightFollowsCurrentItem: true
        highlight: Item {}

        model: root._pageCount

        delegate: Item {
            id: pageDelegate

            // Bind index via required property (ComponentBehavior: Bound)
            required property int index

            width:  pageView.width
            height: pageView.height

            // ── Apps for this page ────────────────────────────────
            readonly property int _pageStart: pageDelegate.index * root._appsPerPage
            readonly property int _pageEnd:   Math.min(_pageStart + root._appsPerPage, root._apps.length)

            // ── Inner grid of cells ───────────────────────────────
            Item {
                // Centre the grid horizontally and vertically within the page
                x:      root._marginH
                y:      root._marginV
                width:  root._gridW
                height: root._gridH

                Repeater {
                    model: pageDelegate._pageEnd - pageDelegate._pageStart

                    // Wrap in an inline Item so `index` is injected by the
                    // Repeater into this inline scope (ComponentBehavior: Bound
                    // does NOT auto-inject Repeater roles into external files).
                    // We then forward it explicitly to GridItemDelegate.
                    delegate: Item {
                        required property int index

                        readonly property int _globalIndex: pageDelegate._pageStart + index
                        readonly property int _col: index % root._cols
                        readonly property int _row: Math.floor(index / root._cols)

                        x:      _col * root._cellW
                        y:      _row * root._cellH
                        width:  root._cellW
                        height: root._cellH

                        GridItemDelegate {
                            anchors.fill: parent

                            index:      parent.index
                            modelData:  root._apps[parent._globalIndex] ?? null
                            iconSize:   root._iconSz
                            isSelected: false

                            onClicked: {
                                if (modelData) root.appLaunched(modelData);
                            }
                        }
                    }
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────
        Item {
            anchors.centerIn: parent
            visible: root._apps.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "apps"
                    font.pointSize: 48
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.3
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No apps found")
                    font.pointSize: Appearance.font.size.normal
                    font.family:    Appearance.font.family.sans
                    color:          Colours.palette.m3onSurfaceVariant
                    opacity:        0.5
                }
            }
        }
    }

    // ── Dot pagination indicator ──────────────────────────────────────
    Row {
        id: dotRow

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     4

        spacing: root._dotSpacing
        visible: root._pageCount > 1

        Repeater {
            model: root._pageCount

            delegate: Rectangle {
                required property int index

                readonly property bool _active: pageView.currentIndex === index

                width:  _active ? root._dotSize * 2.2 : root._dotSize
                height: root._dotSize
                radius: root._dotSize / 2

                color: _active
                    ? Colours.palette.m3primary
                    : Colours.palette.m3onSurfaceVariant
                opacity: _active ? 1.0 : 0.35

                Behavior on width   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color   { CAnim { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    pageView.currentIndex = index
                }
            }
        }
    }
}
