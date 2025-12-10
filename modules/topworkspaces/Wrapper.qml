pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    readonly property real rounding: Config.border.rounding
    readonly property int activeWsId: Config.bar.workspaces.perMonitorWorkspaces ? (Hypr.monitorFor(screen).activeWorkspace?.id ?? 1) : Hypr.activeWsId
    readonly property bool onSpecial: (Config.bar.workspaces.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace.name !== ""

    readonly property var occupied: Hypr.workspaces.values.reduce((acc, curr) => {
        acc[curr.id] = curr.lastIpcObject.windows > 0;
        return acc;
    }, {})
    readonly property int groupOffset: Math.floor((activeWsId - 1) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown

    readonly property bool isVisible: visibilities.topworkspaces
    property real targetImplicitHeight: 0
    property bool isOpening: false
    property real blur: onSpecial ? 1 : 0

    // Auto-close topworkspaces saat overview tutup
    Connections {
        target: root.visibilities
        
        function onOverviewChanged() {
            if (!root.visibilities.overview) {
                // Overview tutup, topworkspaces juga tutup
                root.visibilities.topworkspaces = false;
            }
        }
    }

    // Trigger visibility saat workspace berubah (normal atau special)
    // TAPI hanya kalau overview TIDAK aktif
    onActiveWsIdChanged: {
        if (!visibilities.overview) {
            visibilities.topworkspaces = true
            hideTimer.restart()
        }
    }

    // Trigger visibility saat special workspace toggle
    // TAPI hanya kalau overview TIDAK aktif
    onOnSpecialChanged: {
        if (!visibilities.overview) {
            visibilities.topworkspaces = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.visibilities.topworkspaces = false
    }

    visible: height > 0
    implicitHeight: targetImplicitHeight
    implicitWidth: content.implicitWidth + outerMargin * 2

    // Outer margin - space antara content dengan edge wrapper (semua sisi) - sama seperti OSD
    readonly property real outerMargin: Appearance.padding.large

    onIsVisibleChanged: {
        if (isVisible) {
            isOpening = true
            Qt.callLater(() => {
                targetImplicitHeight = content.implicitHeight + outerMargin * 2
            })
        } else {
            isOpening = false
            targetImplicitHeight = 0
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: root.isOpening ? Appearance.anim.durations.expressiveDefaultSpatial : Appearance.anim.durations.normal
            easing.bezierCurve: root.isOpening ? Appearance.anim.curves.expressiveDefaultSpatial : Appearance.anim.curves.emphasized
        }
    }

    StyledClippingRect {
        id: content

        // Inner padding dari config
        readonly property real hPadding: Config.bar.workspaces.topWorkspacesHPadding
        readonly property real vPadding: Appearance.padding.large

        // Anchor ke bottom supaya animasi close benar (tertutup dari atas)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: outerMargin
        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: layout.implicitWidth + hPadding * 2
        // Container height dari config
        implicitHeight: Config.bar.workspaces.topWorkspacesContainerHeight

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        Item {
            anchors.fill: parent
            scale: root.onSpecial ? 0.8 : 1
            opacity: root.onSpecial ? 0.5 : 1

            layer.enabled: root.blur > 0
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: root.blur
                blurMax: 32
            }

            Loader {
                active: Config.bar.workspaces.occupiedBg
                asynchronous: true

                anchors.fill: parent
                anchors.margins: Appearance.padding.small

                sourceComponent: HorizontalOccupiedBg {
                    workspaces: workspaces
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                }
            }

            RowLayout {
                id: layout

                anchors.centerIn: parent
                spacing: Config.bar.workspaces.topWorkspacesSpacing

                Repeater {
                    id: workspaces

                    model: Config.bar.workspaces.shown

                    HorizontalWorkspace {
                        activeWsId: root.activeWsId
                        occupied: root.occupied
                        groupOffset: root.groupOffset
                    }
                }
            }

            Loader {
                anchors.verticalCenter: parent.verticalCenter
                active: Config.bar.workspaces.activeIndicator
                asynchronous: true

                sourceComponent: HorizontalActiveIndicator {
                    activeWsId: root.activeWsId
                    workspaces: workspaces
                    mask: layout
                }
            }

            MouseArea {
                id: workspaceMouseArea
                
                property point dragStart
                property bool isDragging: false
                property bool isDraggingUp: false
                
                anchors.fill: layout
                
                onPressed: event => {
                    dragStart = Qt.point(event.x, event.y);
                    isDragging = false;
                    isDraggingUp = false;
                }
                
                onPositionChanged: event => {
                    const dragY = event.y - dragStart.y;
                    // Jika drag ke bawah cukup jauh, set flag dragging (untuk open overview)
                    if (dragY > Config.overview.dragThreshold) {
                        isDragging = true;
                        isDraggingUp = false;
                    }
                    // Jika drag ke atas cukup jauh, set flag dragging up (untuk close topworkspaces)
                    else if (dragY < -Config.overview.dragThreshold) {
                        isDraggingUp = true;
                        isDragging = false;
                    }
                }
                
                onReleased: event => {
                    if (isDragging) {
                        // Drag ke bawah - trigger overview (hanya saat overview belum aktif)
                        if (!root.visibilities.overview) {
                            root.visibilities.overview = true;
                        }
                    } else if (isDraggingUp) {
                        // Drag ke atas - tutup topworkspaces
                        root.visibilities.topworkspaces = false;
                    } else {
                        // Click detected - pindah workspace
                        const child = layout.childAt(event.x, event.y);
                        if (child && child.ws !== undefined) {
                            const ws = child.ws;
                            if (Hypr.activeWsId !== ws)
                                Hypr.dispatch(`workspace ${ws}`);
                            else
                                Hypr.dispatch("togglespecialworkspace special");
                        }
                    }
                    isDragging = false;
                    isDraggingUp = false;
                }
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on opacity {
                Anim {}
            }
        }

        // Special workspace overlay (icon muncul saat di special workspace)
        Loader {
            id: specialWs

            anchors.fill: parent
            anchors.margins: Appearance.padding.small

            active: opacity > 0
            asynchronous: true

            scale: root.onSpecial ? 1 : 0.5
            opacity: root.onSpecial ? 1 : 0

            sourceComponent: HorizontalSpecialWorkspaces {
                screen: root.screen
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on opacity {
                Anim {}
            }
        }
    }

    Behavior on blur {
        Anim {
            duration: Appearance.anim.durations.small
        }
    }
}
