import qs.components.controls
import qs.config
import qs.modules.bar.popouts as BarPopouts
import Quickshell
import QtQuick

CustomMouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property PersistentProperties visibilities
    required property Panels panels
    required property Item bar

    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive
    property bool utilitiesShortcutActive
    property bool overviewShortcutActive
    property bool topworkspacesShortcutActive

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        if (!panel) return false;
        const panelY = Config.border.thickness + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        if (!panel) return false;
        const panelX = bar.implicitWidth + panel.x;
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inLeftPanel(panel: Item, x: real, y: real): bool {
        if (!panel) return false;
        return x < bar.implicitWidth + panel.x + panel.width && withinPanelHeight(panel, x, y);
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        if (!panel) return false;
        const triggerWidth = Math.max(panel.width, Config.border.thickness);
        return x > width - triggerWidth - Config.border.rounding && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, x: real, y: real): bool {
        if (!panel) return false;
        const triggerHeight = Math.max(panel.height, Config.border.thickness);
        return y < Config.border.thickness + panel.y + triggerHeight && withinPanelWidth(panel, x, y);
    }

    function inBottomPanel(panel: Item, x: real, y: real): bool {
        if (!panel) return false;
        const triggerHeight = Math.max(panel.height, Config.border.thickness);
        return y > height - triggerHeight - Config.border.rounding && withinPanelWidth(panel, x, y);
    }

    function onWheel(event: WheelEvent): void {
        if (event.x < bar.implicitWidth) {
            bar.handleWheel(event.y, event.angleDelta);
        }
    }

    anchors.fill: parent
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                visibilities.osd = false;
                root.panels.osd.hovered = false;
            }

            if (!dashboardShortcutActive)
                visibilities.dashboard = false;

            if (!utilitiesShortcutActive)
                visibilities.utilities = false;

            if (!visibilities.launcherShortcutActive && Config.launcher.showOnHover)
                visibilities.launcher = false;

            if (!overviewShortcutActive && !visibilities.overviewClickPending)
                visibilities.overview = false;

            // Hide topworkspaces on mouse leave (jika bukan dari shortcut/workspace change)
            if (!topworkspacesShortcutActive)
                visibilities.topworkspaces = false;

            if (!popouts.currentName.startsWith("traymenu") || (popouts.current?.depth ?? 0) <= 1) {
                popouts.hasCurrent = false;
                bar.closeTray();
            }

            if (Config.bar.showOnHover)
                bar.isHovered = false;
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached)
            return;

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        // Show bar in non-exclusive mode on hover
        if (!visibilities.bar && Config.bar.showOnHover && x < bar.implicitWidth)
            bar.isHovered = true;

        // Show/hide bar on drag
        if (pressed && dragStart.x < bar.implicitWidth) {
            if (dragX > Config.bar.dragThreshold)
                visibilities.bar = true;
            else if (dragX < -Config.bar.dragThreshold)
                visibilities.bar = false;
        }

        if (panels.sidebar.width === 0) {
            // Show osd on hover
            const showOsd = inRightPanel(panels.osd, x, y);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                visibilities.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            // Check if drag started near right edge (within dragThreshold of screen edge)
            const showSidebar = pressed && dragStart.x > root.width - Config.sidebar.dragThreshold;

            // Fullscreen session is keybind-only, no drag gesture
            // Just handle sidebar drag
            if (showSidebar && dragX < -Config.sidebar.dragThreshold) {
                visibilities.sidebar = true;
            }
        } else {
            const outOfSidebar = x < width - panels.sidebar.width;
            // Show osd on hover
            const showOsd = outOfSidebar && inRightPanel(panels.osd, x, y);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                visibilities.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            // Fullscreen session is keybind-only, no drag gesture

            // Hide sidebar on drag
            if (pressed && inRightPanel(panels.sidebar, dragStart.x, 0) && dragX > Config.sidebar.dragThreshold)
                visibilities.sidebar = false;
        }

        // Show launcher on hover, or show/hide on drag if hover is disabled
        if (Config.launcher.showOnHover) {
            const showLauncher = inBottomPanel(panels.launcher, x, y);
            if (!visibilities.launcherShortcutActive) {
                visibilities.launcher = showLauncher;
            } else if (showLauncher) {
                // If hovering over launcher area while in shortcut mode, transition to hover control
                visibilities.launcherShortcutActive = false;
            }
        } else if (pressed && inBottomPanel(panels.launcher, dragStart.x, dragStart.y) && withinPanelWidth(panels.launcher, x, y)) {
            if (dragY < -Config.launcher.dragThreshold)
                visibilities.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                visibilities.launcher = false;
        }

        // Show dashboard on hover
        const showDashboard = Config.dashboard.showOnHover && inTopPanel(panels.dashboard, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!dashboardShortcutActive) {
            visibilities.dashboard = showDashboard;
        } else if (showDashboard) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control
            dashboardShortcutActive = false;
        }

        // Show/hide dashboard on drag (for touchscreen devices)
        if (pressed && inTopPanel(panels.dashboard, dragStart.x, dragStart.y) && withinPanelWidth(panels.dashboard, x, y)) {
            if (dragY > Config.dashboard.dragThreshold)
                visibilities.dashboard = true;
            else if (dragY < -Config.dashboard.dragThreshold)
                visibilities.dashboard = false;
        }

        // Show topworkspaces on hover (ganti dari overview) - HANYA saat overview TIDAK aktif
        if (Config.overview.showOnHover && Config.overview.enabled && !visibilities.overview) {
            const showTopWorkspaces = inTopPanel(panels.topworkspaces, x, y);
            if (!topworkspacesShortcutActive) {
                visibilities.topworkspaces = showTopWorkspaces;
            } else if (showTopWorkspaces) {
                topworkspacesShortcutActive = false;
            }
        }

        // Show/hide overview on drag dari area topworkspaces (termasuk content)
        // Click tetap bisa pindah workspace karena dragThreshold
        if (pressed && !visibilities.overview) {
            // Gunakan posisi actual dari topworkspaces panel
            const twX = bar.implicitWidth + panels.topworkspaces.x;
            const twWidth = Math.max(panels.topworkspaces.width, 200);  // Minimum width untuk edge trigger
            const inTwHorizontal = dragStart.x >= twX - Config.border.rounding && 
                                   dragStart.x <= twX + twWidth + Config.border.rounding;
            
            // Area dari top edge (0) sampai bawah topworkspaces content
            const twHeight = Math.max(panels.topworkspaces.height, Config.border.thickness);
            const twBottomY = Config.border.thickness + panels.topworkspaces.y + twHeight + Config.border.rounding;
            const inTwVertical = dragStart.y >= 0 && dragStart.y <= twBottomY;
            
            if (inTwHorizontal && inTwVertical) {
                // Hanya trigger kalau benar-benar DRAG (bukan click)
                if (dragY > Config.overview.dragThreshold)
                    visibilities.overview = true;
            }
        }

        // Saat overview AKTIF: drag untuk show/hide topworkspaces
        // Bisa dari area bawah overview ATAU dari area topworkspaces sendiri
        if (pressed && visibilities.overview) {
            const ovX = bar.implicitWidth + panels.overview.x;
            const ovWidth = panels.overview.width;
            const inOvHorizontal = dragStart.x >= ovX - Config.border.rounding && 
                                   dragStart.x <= ovX + ovWidth + Config.border.rounding;
            
            // Area bawah overview
            const ovBottomY = Config.border.thickness + panels.overview.y + panels.overview.height;
            const inOvBottom = dragStart.y >= ovBottomY - Config.border.rounding * 2 && 
                               dragStart.y <= ovBottomY + Config.border.rounding * 2;
            
            // Area topworkspaces (untuk drag tutup)
            const twX = bar.implicitWidth + panels.topworkspaces.x;
            const twY = Config.border.thickness + panels.topworkspaces.y + panels.overview.height;
            const twHeight = panels.topworkspaces.height;
            const inTwHorizontal = dragStart.x >= twX - Config.border.rounding && 
                                   dragStart.x <= twX + panels.topworkspaces.width + Config.border.rounding;
            const inTwVertical = dragStart.y >= twY - Config.border.rounding && 
                                 dragStart.y <= twY + twHeight + Config.border.rounding;
            const inTopWorkspaces = inTwHorizontal && inTwVertical;
            
            // Drag dari area bawah overview untuk OPEN topworkspaces
            if (inOvHorizontal && inOvBottom) {
                if (dragY > Config.overview.dragThreshold)
                    visibilities.topworkspaces = true;
            }
            
            // Drag dari area topworkspaces atau bawah overview untuk CLOSE topworkspaces
            if (inTopWorkspaces || (inOvHorizontal && inOvBottom)) {
                if (dragY < -Config.overview.dragThreshold)
                    visibilities.topworkspaces = false;
            }
        }

        // Show utilities on hover
        const showUtilities = inBottomPanel(panels.utilities, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!utilitiesShortcutActive) {
            visibilities.utilities = showUtilities;
        } else if (showUtilities) {
            // If hovering over utilities area while in shortcut mode, transition to hover control
            utilitiesShortcutActive = false;
        }

        // Show popouts on hover
        if (x < bar.implicitWidth) {
            bar.checkPopout(y);
        } else if ((!popouts.currentName.startsWith("traymenu") || (popouts.current?.depth ?? 0) <= 1) && !inLeftPanel(panels.popouts, x, y)) {
            popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    // Monitor individual visibility changes
    Connections {
        target: root.visibilities

        function onLauncherChanged() {
            // If launcher is hidden, clear shortcut flags for dashboard and OSD
            if (!root.visibilities.launcher) {
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;
                root.utilitiesShortcutActive = false;

                // Also hide dashboard and OSD if they're not being hovered
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                const inOsdArea = root.inRightPanel(root.panels.osd, root.mouseX, root.mouseY);

                if (!inDashboardArea) {
                    root.visibilities.dashboard = false;
                }
                if (!inOsdArea) {
                    root.visibilities.osd = false;
                    root.panels.osd.hovered = false;
                }
            }
        }

        function onDashboardChanged() {
            if (root.visibilities.dashboard) {
                // Dashboard became visible, immediately check if this should be shortcut mode
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                if (!inDashboardArea) {
                    root.dashboardShortcutActive = true;
                }
            } else {
                // Dashboard hidden, clear shortcut flag
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.visibilities.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inRightPanel(root.panels.osd, root.mouseX, root.mouseY);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        function onUtilitiesChanged() {
            if (root.visibilities.utilities) {
                // Utilities became visible, immediately check if this should be shortcut mode
                const inUtilitiesArea = root.inBottomPanel(root.panels.utilities, root.mouseX, root.mouseY);
                if (!inUtilitiesArea) {
                    root.utilitiesShortcutActive = true;
                }
            } else {
                // Utilities hidden, clear shortcut flag
                root.utilitiesShortcutActive = false;
            }
        }

        function onOverviewChanged() {
            if (root.visibilities.overview) {
                // Overview became visible, immediately check if this should be shortcut mode
                const inOverviewArea = root.inTopPanel(root.panels.overview, root.mouseX, root.mouseY);
                if (!inOverviewArea) {
                    root.overviewShortcutActive = true;
                }
            } else {
                // Overview hidden, clear shortcut flag
                root.overviewShortcutActive = false;
            }
        }

        function onTopworkspacesChanged() {
            if (root.visibilities.topworkspaces) {
                // Topworkspaces became visible, check if this should be shortcut mode
                const inTopWorkspacesArea = root.inTopPanel(root.panels.topworkspaces, root.mouseX, root.mouseY);
                if (!inTopWorkspacesArea) {
                    root.topworkspacesShortcutActive = true;
                }
            } else {
                // Topworkspaces hidden, clear shortcut flag
                root.topworkspacesShortcutActive = false;
            }
        }
    }
}
