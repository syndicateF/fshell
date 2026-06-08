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

    // ── Auto-center the grid ──────────────────────────────────────────
    readonly property int _gridW: _cols * _cellW
    readonly property int _gridH: _rows * _cellH
    readonly property int _marginH: Math.max(0, Math.floor((width  - _gridW) / 2))
    readonly property int _marginV: Math.max(0, Math.floor((height - _gridH) / 2))

    GridView {
        id: grid

        anchors.fill: parent
        anchors.leftMargin:   root._marginH
        anchors.rightMargin:  root._marginH
        anchors.topMargin:    root._marginV
        anchors.bottomMargin: root._marginV

        cellWidth:  root._cellW
        cellHeight: root._cellH

        clip:           true
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel {
            values: root._apps
        }

        delegate: GridItemDelegate {
            width:    grid.cellWidth
            height:   grid.cellHeight
            iconSize: root._iconSz
            isSelected: grid.currentIndex === index
            onClicked: {
                grid.currentIndex = index;
                if (modelData) root.appLaunched(modelData);
            }
            onHovered: grid.currentIndex = index
        }

        // ── Empty state ───────────────────────────────────────────
        Item {
            anchors.centerIn: parent
            visible: grid.count === 0

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
}
