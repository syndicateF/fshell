pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.modules.bar as Bar
import qs.modules.overview as Overview
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            bar: bar
        }

        StyledWindow {
            id: win

            readonly property bool hasFullscreen: Hypr.monitorFor(screen)?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen === 2) ?? false
            readonly property int dragMaskPadding: {
                if (focusGrab.active || panels.popouts.isDetached)
                    return 0;

                const mon = Hypr.monitorFor(screen);
                if (mon?.lastIpcObject.specialWorkspace.name || mon?.activeWorkspace?.lastIpcObject.windows > 0)
                    return 0;

                const thresholds = [];
                for (const panel of ["dashboard", "launcher", "session", "sidebar"])
                    if (Config[panel].enabled)
                        thresholds.push(Config[panel].dragThreshold);
                return Math.max(...thresholds);
            }

            onHasFullscreenChanged: {
                visibilities.launcher = false;
                visibilities.session = false;
                visibilities.dashboard = false;
            }

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || visibilities.overview || visibilities.spiralOverview ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            // Switch to Overlay layer when spiral is active (above all Hyprland windows)
            WlrLayershell.layer: visibilities.spiralOverview ? WlrLayer.Overlay : WlrLayer.Top

            // Disable mask when spiral is active (fullscreen overlay)
            mask: visibilities.spiralOverview ? null : normalMask

            Region {
                id: normalMask
                x: bar.implicitWidth + win.dragMaskPadding
                y: Config.border.thickness + win.dragMaskPadding
                width: win.width - bar.implicitWidth - Config.border.thickness - win.dragMaskPadding * 2
                height: win.height - Config.border.thickness * 2 - win.dragMaskPadding * 2
                intersection: Intersection.Xor

                regions: regions.instances
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    x: modelData.x + bar.implicitWidth
                    y: modelData.y + Config.border.thickness
                    width: modelData.width
                    height: modelData.height
                    intersection: Intersection.Subtract
                }
            }

            HyprlandFocusGrab {
                id: focusGrab

                active: (visibilities.launcher && Config.launcher.enabled) || (visibilities.session && Config.session.enabled) || (visibilities.sidebar && Config.sidebar.enabled) || (!Config.dashboard.showOnHover && visibilities.dashboard && Config.dashboard.enabled) || (visibilities.overview && Config.overview.enabled) || visibilities.spiralOverview || (panels.popouts.currentName.startsWith("traymenu") && panels.popouts.current?.depth > 1)
                windows: [win]
                onCleared: {
                    visibilities.launcher = false;
                    visibilities.launcherShortcutActive = false;
                    visibilities.session = false;
                    visibilities.sidebar = false;
                    visibilities.dashboard = false;
                    visibilities.overview = false;
                    visibilities.spiralOverview = false;
                    panels.popouts.hasCurrent = false;
                    bar.closeTray();
                }
            }

            // Timer-based detection for special workspace app ready (less overhead than event-based)
            Timer {
                id: loadingCheckTimer
                interval: 200
                repeat: true
                running: panels.popouts.detachedMode === "loading"
                onTriggered: {
                    const wsName = panels.popouts.loadingWsName;
                    if (!wsName) return;
                    
                    const specialWs = Hypr.workspaces.values.find(ws => ws.name === `special:${wsName}`);
                    if (specialWs?.lastIpcObject?.windows > 0) {
                        panels.popouts.closeLoading();
                    }
                }
            }

            StyledRect {
                anchors.fill: parent
                opacity: visibilities.session && Config.session.enabled ? 0.5 : 0
                color: Colours.palette.m3scrim

                Behavior on opacity {
                    Anim {}
                }
            }

            Item {
                anchors.fill: parent
                opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 15
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
                }

                Border {
                    bar: bar
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    Bar.Background {
                        bar: bar
                    }
                }

                Backgrounds {
                    panels: panels
                    bar: bar
                }
            }

            PersistentProperties {
                id: visibilities

                property bool bar
                property bool osd
                property bool session
                property bool launcher
                property bool dashboard
                property bool utilities
                property bool sidebar
                property bool overview
                property bool spiralOverview
                property bool topworkspaces
                property bool launcherShortcutActive
                property bool overviewClickPending: false

                // Timer untuk reset overviewClickPending setelah cursor warp selesai
                property Timer _overviewClickTimer: Timer {
                    interval: 500
                    onTriggered: visibilities.overviewClickPending = false
                }

                function setOverviewClickPending(): void {
                    overviewClickPending = true
                    _overviewClickTimer.restart()
                }

                Component.onCompleted: Visibilities.load(scope.modelData, this)
            }

            Interactions {
                screen: scope.modelData
                popouts: panels.popouts
                visibilities: visibilities
                panels: panels
                bar: bar

                Panels {
                    id: panels

                    screen: scope.modelData
                    visibilities: visibilities
                    bar: bar
                }

                Bar.BarWrapper {
                    id: bar

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: Config.border.thickness

                    screen: scope.modelData
                    visibilities: visibilities
                    popouts: panels.popouts

                    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                }
            }

            // Spiral Overview - TRUE fullscreen overlay (outside Panels to ignore margins)
            // Manages its own loading state to allow exit animations
            Item {
                id: spiralOverviewContainer
                anchors.fill: parent
                
                property bool shouldShow: visibilities.spiralOverview
                property bool isLoaded: false
                property bool isAnimatingOut: false
                
                // Load when requested, or close with animation if already open
                onShouldShowChanged: {
                    if (shouldShow) {
                        if (!isLoaded) {
                            // Open: load the component
                            isLoaded = true
                            isAnimatingOut = false
                        } else if (isAnimatingOut) {
                            // Was closing, cancel close - already loaded
                            isAnimatingOut = false
                        }
                    } else {
                        // Close requested via toggle - trigger animation
                        if (isLoaded && !isAnimatingOut && spiralOverviewLoader.item) {
                            isAnimatingOut = true
                            spiralOverviewLoader.item.closeWithAnimation()
                        }
                    }
                }
                
                Loader {
                    id: spiralOverviewLoader
                    anchors.fill: parent
                    active: spiralOverviewContainer.isLoaded
                    visible: active
                    
                    sourceComponent: Overview.SpiralOverview {
                        screen: scope.modelData
                        visibilities: visibilities
                        
                        // Called by exitAnimTimer when animation done
                        onExitAnimationDone: {
                            spiralOverviewContainer.isLoaded = false
                            spiralOverviewContainer.isAnimatingOut = false
                            visibilities.spiralOverview = false
                        }
                    }
                }
            }
        }
    }
}
