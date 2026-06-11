pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Hyprland
import QtQuick

/**
 * Workspace thumbnail strip — GNOME Shell style.
 *
 * Matches GNOME's .workspace-thumbnails CSS:
 *   spacing: 6px, padding: 6px, compact proportions.
 *
 * Positioned between search bar and app grid.
 * Hides when search text is present.
 */
Item {
    id: root

    required property ShellScreen screen
    required property string searchText
    required property PersistentProperties visibilities

    // ── Dimensi — matching WorkspaceOverview.qml scale ───────────────
    readonly property var _monitor: Hypr.monitorFor(screen)
    readonly property real _scale: Config.overview.sizes.appgridStripScale

    // Get bar's exclusive zone as reliable fallback (always available from Config)
    readonly property real _barExclusiveZone: Visibilities.bars.get(screen)?.exclusiveZone ?? 0

    // Use bar's exclusiveZone as fallback when reserved[0] is 0 but bar should have zone
    readonly property var _reserved: {
        const monitorData = _monitor?.lastIpcObject ?? null
        const r = monitorData?.reserved ?? [0, 0, 0, 0]
        if (r[0] === 0 && _barExclusiveZone > 0)
            return [_barExclusiveZone, r[1], r[2], r[3]]
        return r
    }

    readonly property real _monitorW: _monitor ? (_monitor.width / _monitor.scale) : 1920
    readonly property real _monitorH: _monitor ? (_monitor.height / _monitor.scale) : 1080
    readonly property real _thumbW: (_monitor ? (_monitor.width / _monitor.scale - _reserved[0] - _reserved[2]) * _scale : 200)
    readonly property real _thumbH: (_monitor ? (_monitor.height / _monitor.scale - _reserved[1] - _reserved[3]) * _scale : 120)

    readonly property int  _spacing:  8
    readonly property int  _padV:     10

    // ── Visibilitas ─────────────────────────────────────────────────
    readonly property bool _showStrip: root.searchText.length === 0
    visible: _showStrip
    opacity: _showStrip ? 1 : 0
    height:  _showStrip ? _thumbH + _padV * 2 : 0

    Behavior on opacity { Anim { duration: Appearance.anim.durations.small } }
    Behavior on height  { Anim { duration: Appearance.anim.durations.normal } }

    // ── Sorted workspaces (exclude special ws with id < 0) ──────────
    readonly property var _sorted: {
        const arr = Hypr.workspaces.values.filter(
            w => w.id > 0
        ).slice();
        arr.sort((a, b) => a.id - b.id);
        return arr;
    }

    // ── Strip ───────────────────────────────────────────────────────
    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: Math.max(width, strip.width)
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        WheelHandler {
            orientation: Qt.Horizontal | Qt.Vertical
            onWheel: (event) => {
                const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                flickable.contentX = Math.max(0, Math.min(flickable.contentWidth - flickable.width, flickable.contentX - delta))
            }
        }

        Item {
            width: flickable.contentWidth
            height: flickable.contentHeight

            Row {
                id: strip
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: root._spacing

                Repeater {
                    model: ScriptModel {
                        values: root._sorted
                    }

                    WorkspaceThumbnail {
                        required property var modelData

                        workspace:     modelData
                        thumbWidth:    root._thumbW
                        thumbHeight:   root._thumbH
                        monitorWidth:  root._monitorW
                        monitorHeight: root._monitorH
                        reserved:      root._reserved
                        stripActive:   root._showStrip && root.visibilities.appgrid

                        onClicked: {
                            Hypr.dispatch(`workspace ${modelData.id}`);
                            root.visibilities.appgrid = false;
                        }
                    }
                }

            }
        }
    }
}
