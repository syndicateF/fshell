pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Wayland
import QtQuick

/**
 * Single workspace thumbnail — GNOME-style compact preview.
 *
 * Uses ScreencopyView for live window content, styled after
 * GNOME Shell's .workspace-thumbnail (border-radius: 3px)
 * and .workspace-thumbnail-indicator (border: 3px solid).
 */
Item {
    id: root

    required property var  workspace
    required property real thumbWidth
    required property real thumbHeight
    required property real monitorWidth
    required property real monitorHeight
    required property var  reserved
    required property bool stripActive

    signal clicked()

    width:  thumbWidth
    height: thumbHeight

    readonly property bool _isActive: workspace.id === Hypr.activeWsId
    readonly property real _scaleX:   thumbWidth  / (monitorWidth - reserved[0] - reserved[2])
    readonly property real _scaleY:   thumbHeight / (monitorHeight - reserved[1] - reserved[3])

    // ── Filter windows in this workspace ────────────────────────────
    readonly property var _windows: root.workspace?.toplevels?.values ?? []

    // ── Hover scale (subtle, GNOME-like) ────────────────────────────
    transform: Scale {
        origin.x: root.width  / 2
        origin.y: root.height / 2
        xScale: ma.containsMouse ? 1.03 : 1.0
        yScale: xScale
        Behavior on xScale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
    }


    // ── Thumbnail content (GNOME: .workspace-thumbnail) ─────────────
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 3  // GNOME: border-radius: 3px
        clip: true
        color: Colours.palette.m3surfaceContainer

        // ── Live window previews ────────────────────────────────────
        Repeater {
            model: root._windows

            delegate: Item {
                required property var modelData
                required property int index

                readonly property var _ipc: modelData.lastIpcObject
                readonly property var _wayland: modelData.wayland ?? null

                x:      Math.max(0, ((_ipc?.at?.[0] ?? 0) - root.reserved[0]) * root._scaleX)
                y:      Math.max(0, ((_ipc?.at?.[1] ?? 0) - root.reserved[1]) * root._scaleY)
                width:  Math.max(4, (_ipc?.size?.[0] ?? 80) * root._scaleX)
                height: Math.max(4, (_ipc?.size?.[1] ?? 60) * root._scaleY)
                clip:   true

                Rectangle {
                    anchors.fill: parent
                    radius: 1
                    color: Colours.palette.m3surfaceContainerHighest

                    // HD downscaling: offscreen layer with bilinear + mipmapping
                    // prevents jagged / pixelated thumbnails on fractional scale
                    layer.enabled: true
                    layer.smooth: true
                    layer.mipmap: true

                    ScreencopyView {
                        id: scView
                        anchors.fill: parent
                        captureSource: root.stripActive ? parent.parent._wayland : null
                        live: false
                        paintCursor: false

                        // Delay capture until recording context is ready
                        onCaptureSourceChanged: {
                            if (captureSource)
                                captureDelay.restart();
                            else
                                captureDelay.stop();
                        }

                        Timer {
                            id: captureDelay
                            interval: 150
                            onTriggered: scView.captureFrame()
                        }
                    }
                }
            }
        }

        // ── Subtle overlay for inactive workspaces ──────────────────
        Rectangle {
            anchors.fill: parent
            radius: 3
            color: "black"
            opacity: root._isActive ? 0 : 0.15
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    // ── Mouse interaction ───────────────────────────────────────────
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
