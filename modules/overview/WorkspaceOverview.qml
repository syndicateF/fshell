pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import qs.utils
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

FocusScope {
    id: root

    required property PersistentProperties visibilities
    required property ShellScreen screen
    required property var popouts

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property int workspacesShown: overviewRows * overviewColumns
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / workspacesShown)
    
    property int overviewRows: 2
    property int overviewColumns: 5
    property real scale: Config.overview.sizes.scale
    
    property var monitorData: {
        const mon = Hypr.monitors.values.find(m => m.id === monitor?.id);
        return mon?.lastIpcObject ?? null;
    }
    
    property color activeBorderColor: Colours.palette.m3primary
    property int uniformRadius: Config.border.rounding
    
    // Reserved areas from bar: [left, top, right, bottom]
    property var reserved: monitorData?.reserved ?? [0, 0, 0, 0]
    
    // Workspace size = monitor size MINUS reserved areas (bar space)
    property real wsWidth: (monitor.width / monitor.scale - reserved[0] - reserved[2]) * scale
    property real wsHeight: (monitor.height / monitor.scale - reserved[1] - reserved[3]) * scale
    
    property real workspaceSpacing: 5
    property real elevationMargin: 24
    property real windowPadding: 4  // Gap between windows in same workspace
    
    // Special workspaces config
    property var specialWorkspaces: ["sysmon", "music", "communication", "todo"]
    
    // App info for each special workspace: { icon, command }
    function getSpecialAppInfo(wsName) {
        const apps = Config.overview.specialWorkspaceApps
        return apps[wsName] ?? { icon: "application-x-executable", command: "" }
    }
    
    // Drag state
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    
    // Track recently moved windows to prevent jump on re-creation
    property var recentlyMoved: ({})  // {address: timestamp}
    
    function markAsMoved(addr) {
        recentlyMoved[addr] = Date.now()
        recentlyMoved = recentlyMoved  // Trigger update
    }
    
    function wasRecentlyMoved(addr) {
        const ts = recentlyMoved[addr]
        if (!ts) return false
        // Consider "recent" if within 500ms
        return (Date.now() - ts) < 500
    }
    
    // implicitWidth: overviewContainer.implicitWidth + elevationMargin * 2
    // implicitHeight: overviewContainer.implicitHeight + elevationMargin * 2
    implicitWidth: overviewContainer.implicitWidth
    implicitHeight: overviewContainer.implicitHeight

    // ESC to close overview
    Shortcut {
        enabled: root.visibilities.overview
        sequence: "Escape"
        onActivated: root.visibilities.overview = false
    }

    // Main container - NO background, just layout
    Item {
        id: overviewContainer
        property real padding: 20
        property real specialRowHeight: specialWsRow.visible ? specialWsRow.implicitHeight + root.workspaceSpacing + 20 : 0
        
        anchors.centerIn: parent
        
        implicitWidth: Math.max(wsGrid.implicitWidth, specialWsRow.implicitWidth) + padding * 2
        implicitHeight: wsGrid.implicitHeight + specialRowHeight + padding * 2

        // Main content column
        Column {
            id: mainColumn
            anchors.centerIn: parent
            spacing: root.workspaceSpacing + 15

            // Workspace grid with individual backgrounds
            Column {
                id: wsGrid
                spacing: root.workspaceSpacing
                
                Repeater {
                    model: root.overviewRows
                    
                    Row {
                        id: wsRow
                        required property int index
                        spacing: root.workspaceSpacing
                        
                        Repeater {
                            model: root.overviewColumns
                            
                            // Each workspace has its own background
                            Rectangle {
                                id: wsRect
                                required property int index
                                
                                property int wsNum: root.workspaceGroup * root.workspacesShown + wsRow.index * root.overviewColumns + index + 1
                                property bool dropHover: false
                                
                                width: root.wsWidth
                                height: root.wsHeight
                                radius: root.uniformRadius
                                color: Colours.palette.m3surfaceContainer
                                
                                // Workspace number
                                Text {
                                    anchors.centerIn: parent
                                    text: wsRect.wsNum
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.1)
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        // If special workspace is active, close it first then switch
                                        const specialWs = root.monitorData?.specialWorkspace?.name ?? ""
                                        if (specialWs !== "" && specialWs.startsWith("special:")) {
                                            // Close the special workspace first, then switch
                                            const specialName = specialWs.replace("special:", "")
                                            Hypr.dispatch(`togglespecialworkspace ${specialName}`)
                                        }
                                        Hypr.dispatch(`workspace ${wsRect.wsNum}`)
                                    }
                                }
                                
                                DropArea {
                                    anchors.fill: parent
                                    onEntered: {
                                        root.draggingTargetWorkspace = wsRect.wsNum
                                        if (root.draggingFromWorkspace !== wsRect.wsNum) dropHover = true
                                    }
                                    onExited: {
                                        dropHover = false
                                        if (root.draggingTargetWorkspace === wsRect.wsNum) root.draggingTargetWorkspace = -1
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Special workspaces row
            Column {
                id: specialWsRow
                visible: root.specialWorkspaces.length > 0
                spacing: 8
                
                // Label
                Text {
                    text: "Special"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.5)
                }
                
                // Special workspaces
                Row {
                    id: specialWsRowContent
                    spacing: root.workspaceSpacing
                    
                    Repeater {
                        model: root.specialWorkspaces
                        
                        Rectangle {
                            id: specialWsRect
                            required property string modelData
                            required property int index
                            
                            property string wsName: modelData
                            property bool isActive: root.monitorData?.specialWorkspace?.name === `special:${wsName}`
                            property var appInfo: root.getSpecialAppInfo(wsName)
                            property bool hasWindows: {
                                const ws = Hypr.workspaces.values.find(w => w.name === `special:${wsName}`)
                                return ws?.lastIpcObject?.windows > 0 ?? false
                            }
                            
                            width: root.wsWidth
                            height: root.wsHeight
                            radius: root.uniformRadius
                            color: isActive ? Qt.alpha(Colours.palette.m3primary, 0.15) : Colours.palette.m3surfaceContainer
                            border.width: isActive ? 2 : 0
                            border.color: Colours.palette.m3primary
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.width { NumberAnimation { duration: 150 } }
                            
                            // Content when no windows - icon + info
                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                visible: !specialWsRect.hasWindows
                                z: 0
                                
                                // App icon (colored, clean)
                                CachingIconImage {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: Icons.getAppIcon(specialWsRect.appInfo.icon ?? "", "application-x-executable")
                                    implicitSize: Math.min(specialWsRect.width, specialWsRect.height) * 0.28
                                }
                                
                                // Workspace name
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: specialWsRect.wsName
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.capitalization: Font.Capitalize
                                    color: Colours.palette.m3onSurface
                                }
                                
                                // Shortcut hint
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: `Super + ${specialWsRect.index + 1}`
                                    font.pixelSize: 8
                                    font.family: Appearance.font.family.mono
                                    color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.6)
                                }
                                
                                // Status indicator
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4
                                    
                                    Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: specialWsRect.isActive ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.4)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Text {
                                        text: specialWsRect.isActive ? "active" : "click to launch"
                                        font.pixelSize: 7
                                        color: specialWsRect.isActive ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.5)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                            
                            // Window previews for this special workspace
                            Item {
                                anchors.fill: parent
                                z: 1
                                
                                Repeater {
                                    model: ScriptModel {
                                        values: {
                                            let arr = [];
                                            for (const ws of Hypr.workspaces.values) {
                                                if (ws.name === `special:${specialWsRect.wsName}`) {
                                                    for (const tl of ws.toplevels.values) arr.push(tl);
                                                }
                                            }
                                            return arr.reverse();
                                        }
                                    }
                                    
                                    Item {
                                        id: specialWinItem
                                        required property var modelData
                                        
                                        property var ipc: modelData.lastIpcObject
                                        
                                        // Window position scaled
                                        property real localX: Math.max((ipc?.at?.[0] ?? 0) - root.reserved[0], 0) * root.scale
                                        property real localY: Math.max((ipc?.at?.[1] ?? 0) - root.reserved[1], 0) * root.scale
                                        property real targetW: Math.max((ipc?.size?.[0] ?? 100) * root.scale - root.windowPadding, 10)
                                        property real targetH: Math.max((ipc?.size?.[1] ?? 100) * root.scale - root.windowPadding, 10)
                                        
                                        x: localX + root.windowPadding / 2
                                        y: localY + root.windowPadding / 2
                                        width: targetW
                                        height: targetH
                                        
                                        ClippingRectangle {
                                            anchors.fill: parent
                                            radius: root.uniformRadius
                                            color: "transparent"
                                            
                                            ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: root.visibilities.overview ? specialWinItem.modelData.wayland : null
                                                live: true
                                            }
                                            
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: root.uniformRadius
                                                color: "transparent"
                                                border.width: 1
                                                border.color: Qt.rgba(1, 1, 1, 0.1)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                z: 2
                                onClicked: {
                                    // Check if special workspace has windows
                                    const specialWsData = Hypr.workspaces.values.find(ws => ws.name === `special:${specialWsRect.wsName}`)
                                    const hasWindows = specialWsData?.lastIpcObject?.windows > 0 ?? false
                                    
                                    // Always toggle the workspace first
                                    Hypr.dispatch(`togglespecialworkspace ${specialWsRect.wsName}`)
                                    
                                    if (!hasWindows) {
                                        // No windows - trigger loading animation and launch app
                                        const appInfo = root.getSpecialAppInfo(specialWsRect.wsName)
                                        root.popouts.loadingWsName = specialWsRect.wsName
                                        root.popouts.loadingAppInfo = appInfo
                                        root.popouts.detach("loading")
                                        
                                        // Launch the app
                                        if (appInfo.command) {
                                            Hypr.dispatch(`exec [workspace special:${specialWsRect.wsName} silent] ${appInfo.command}`)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Windows layer - positioned relative to wsGrid
        // This layer should NOT intercept mouse events on empty areas
        Item {
            id: windowsLayer
            x: mainColumn.x + (mainColumn.width - wsGrid.implicitWidth) / 2
            y: mainColumn.y
            width: wsGrid.implicitWidth
            height: wsGrid.implicitHeight
            z: 1
            
            Repeater {
                model: ScriptModel {
                    values: {
                        // Use ws.toplevels - standard Hyprland workspace data
                        let arr = [];
                        for (const ws of Hypr.workspaces.values) {
                            const wsId = ws.id;
                            if (root.workspaceGroup * root.workspacesShown < wsId && wsId <= (root.workspaceGroup + 1) * root.workspacesShown) {
                                for (const tl of ws.toplevels.values) arr.push(tl);
                            }
                        }
                        return arr.reverse();
                    }
                }
                
                Item {
                    id: winItem
                    required property var modelData
                    
                    // Use Hyprland ws.toplevels data
                    property var ipc: modelData.lastIpcObject
                    property string addr: `0x${modelData.address}`
                    
                    // Get workspace from modelData
                    property var htWorkspace: modelData.workspace
                    property int wsId: htWorkspace ? htWorkspace.id : 1
                    
                    // Position within grid (wsId is 1-based, so subtract 1)
                    property int wsIdInGroup: wsId - root.workspaceGroup * root.workspacesShown
                    property int col: (wsIdInGroup - 1) % root.overviewColumns
                    property int row: Math.floor((wsIdInGroup - 1) / root.overviewColumns)
                    
                    // Offset to workspace cell
                    property real cellX: col * (root.wsWidth + root.workspaceSpacing)
                    property real cellY: row * (root.wsHeight + root.workspaceSpacing)
                    
                    // Window position WITHIN the cell (scaled)
                    // SUBTRACT reserved to get position relative to workspace area (not monitor)
                    property real localX: Math.max((ipc?.at?.[0] ?? 0) - root.reserved[0], 0) * root.scale
                    property real localY: Math.max((ipc?.at?.[1] ?? 0) - root.reserved[1], 0) * root.scale
                    // Reduce size slightly for gap between windows, add half to position to center
                    property real targetW: Math.max((ipc?.size?.[0] ?? 100) * root.scale - root.windowPadding, 10)
                    property real targetH: Math.max((ipc?.size?.[1] ?? 100) * root.scale - root.windowPadding, 10)
                    
                    // Target position (add half padding to center the reduced-size window)
                    property real targetX: cellX + localX + root.windowPadding / 2
                    property real targetY: cellY + localY + root.windowPadding / 2
                    
                    // Simple bindings for position and size
                    x: targetX
                    y: targetY
                    width: targetW
                    height: targetH
                    
                    z: dragArea.drag.active ? 9999 : (ipc?.floating ? 2 : 1)
                    
                    property bool hov: false
                    property bool prs: false
                    property bool dragging: false
                    
                    // Property to track if we're animating to a new workspace
                    property bool animatingToNewWs: false
                    property int pendingTargetWs: -1
                    
                    Timer {
                        id: clearAnimatingTimer
                        interval: 250  // Match animation duration + buffer
                        onTriggered: winItem.animatingToNewWs = false
                    }
                    
                    Behavior on x {
                        enabled: !winItem.dragging
                        NumberAnimation {
                            id: xAnim
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on y {
                        enabled: !winItem.dragging
                        NumberAnimation {
                            id: yAnim
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: 0  // Fast resize
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: 0  // Fast resize
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Drag.active: dragArea.drag.active
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    
                    ClippingRectangle {
                        anchors.fill: parent
                        radius: root.uniformRadius
                        color: "transparent"
                        
                        // GPU layer for better performance
                        layer.enabled: true
                        layer.smooth: false
                        layer.mipmap: false
                        
                        ScreencopyView {
                            id: screenCopy
                            anchors.fill: parent
                            captureSource: root.visibilities.overview ? winItem.modelData.wayland : null
                            live: true
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: root.uniformRadius
                            color: winItem.prs ? Qt.rgba(1,1,1,0.2) : winItem.hov ? Qt.rgba(1,1,1,0.1) : "transparent"
                            border.width: 0
                        }
                    }
                    
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent
                        
                        onEntered: winItem.hov = true
                        onExited: winItem.hov = false
                        onPressed: {
                            root.draggingFromWorkspace = winItem.wsId
                            winItem.prs = true
                            winItem.dragging = true
                        }
                        onReleased: {
                            winItem.prs = false
                            winItem.dragging = false
                            const target = root.draggingTargetWorkspace
                            
                            if (target !== -1 && target !== winItem.wsId) {
                                // DIFFERENT workspace: animate first, dispatch later
                                const targetWsIdInGroup = target - root.workspaceGroup * root.workspacesShown
                                const targetCol = (targetWsIdInGroup - 1) % root.overviewColumns
                                const targetRow = Math.floor((targetWsIdInGroup - 1) / root.overviewColumns)
                                const targetCellX = targetCol * (root.wsWidth + root.workspaceSpacing)
                                const targetCellY = targetRow * (root.wsHeight + root.workspaceSpacing)
                                
                                // Window position within target workspace (same local position)
                                const finalX = targetCellX + winItem.localX
                                const finalY = targetCellY + winItem.localY
                                
                                // Mark as animating to prevent target updates
                                winItem.animatingToNewWs = true
                                winItem.pendingTargetWs = target
                                
                                // Animate to new position
                                winItem.x = finalX
                                winItem.y = finalY
                                
                                // Dispatch AFTER animation completes
                                dispatchTimer.targetWs = target
                                dispatchTimer.addr = winItem.addr
                                dispatchTimer.start()
                                
                                // Mark this window as recently moved
                                root.markAsMoved(winItem.addr)
                                
                                // Clear animating flag
                                clearAnimatingTimer.start()
                            } else {
                                // Same workspace or no target: snap back to original position
                                winItem.x = winItem.targetX
                                winItem.y = winItem.targetY
                                // Reset drag state immediately for same workspace
                                root.draggingFromWorkspace = -1
                            }
                        }
                        
                        Timer {
                            id: dispatchTimer
                            property int targetWs: -1
                            property string addr: ""
                            interval: 100
                            onTriggered: {
                                Hypr.dispatch(`movetoworkspacesilent ${targetWs}, address:${addr}`)
                                resetDragTimer.start()
                            }
                        }
                        
                        Timer {
                            id: resetDragTimer
                            interval: 200
                            onTriggered: root.draggingFromWorkspace = -1
                        }
                        onClicked: (e) => {
                            if (e.button === Qt.LeftButton) {
                                root.visibilities.setOverviewClickPending()
                                Hypr.dispatch(`focuswindow address:${winItem.addr}`)
                            } else if (e.button === Qt.MiddleButton) {
                                Hypr.dispatch(`closewindow address:${winItem.addr}`)
                            }
                        }
                    }
                }
            }
        }

        // Active border & drop indicator layer (z: 10) - always on top
        Item {
            id: bordersLayer
            x: mainColumn.x + (mainColumn.width - wsGrid.implicitWidth) / 2
            y: mainColumn.y
            width: Math.max(wsGrid.implicitWidth, specialWsRowContent.implicitWidth)
            height: mainColumn.implicitHeight
            z: 10

            // Drop target indicator
            Rectangle {
                id: dropIndicator
                visible: root.draggingTargetWorkspace !== -1 && root.draggingFromWorkspace !== root.draggingTargetWorkspace
                
                property int targetInGroup: root.draggingTargetWorkspace - root.workspaceGroup * root.workspacesShown
                property int c: (targetInGroup - 1) % root.overviewColumns
                property int r: Math.floor((targetInGroup - 1) / root.overviewColumns)
                
                x: c * (root.wsWidth + root.workspaceSpacing)
                y: r * (root.wsHeight + root.workspaceSpacing)
                width: root.wsWidth
                height: root.wsHeight
                color: "transparent"
                radius: root.uniformRadius
                border.width: 2
                border.color: Colours.palette.m3tertiary
            }

            // Active workspace border - supports both normal and special workspaces
            Rectangle {
                id: activeBorder
                
                // Check if special workspace is active on this monitor
                // specialWorkspace.name will be empty string "" when no special workspace is active
                property var specialWsObj: root.monitorData?.specialWorkspace ?? null
                property string activeSpecialName: specialWsObj?.name ?? ""
                property bool isSpecialActive: activeSpecialName !== "" && activeSpecialName.startsWith("special:")
                property string specialName: isSpecialActive ? activeSpecialName.replace("special:", "") : ""
                property int specialIndex: isSpecialActive ? root.specialWorkspaces.indexOf(specialName) : -1
                
                // Normal workspace calculation - always calculate this regardless of special state
                property int aws: root.monitor.activeWorkspace?.id ?? 1
                property int awsInGroup: aws - root.workspaceGroup * root.workspacesShown
                property bool awsInRange: awsInGroup >= 1 && awsInGroup <= root.workspacesShown
                property int normalCol: awsInRange ? (awsInGroup - 1) % root.overviewColumns : 0
                property int normalRow: awsInRange ? Math.floor((awsInGroup - 1) / root.overviewColumns) : 0
                
                // Position for normal workspace
                property real normalX: normalCol * (root.wsWidth + root.workspaceSpacing)
                property real normalY: normalRow * (root.wsHeight + root.workspaceSpacing)
                
                // Position for special workspace
                // specialWsRow Y = wsGrid height + mainColumn.spacing (workspaceSpacing + 15)
                // Then inside specialWsRow: label (height ~16) + spacing (8) + content
                property real specialRowLabelHeight: 16 + 8  // "Special" label + spacing
                property real specialRowTopY: wsGrid.implicitHeight + root.workspaceSpacing + 15  // mainColumn spacing
                property real specialX: specialIndex >= 0 ? specialIndex * (root.wsWidth + root.workspaceSpacing) : 0
                property real specialY: specialIndex >= 0 ? specialRowTopY + specialRowLabelHeight : 0
                
                // Determine which position to use
                // Use special position ONLY if special is active AND the special ws is in our list
                property bool useSpecialPosition: isSpecialActive && specialIndex >= 0
                
                // Final position
                x: useSpecialPosition ? specialX : normalX
                y: useSpecialPosition ? specialY : normalY
                width: root.wsWidth
                height: root.wsHeight
                color: "transparent"
                radius: root.uniformRadius
                border.width: 2
                border.color: root.activeBorderColor
                
                // Always visible for normal workspaces in range
                // For special: only visible if it's in our specialWorkspaces list
                visible: useSpecialPosition || (!isSpecialActive && awsInRange)
                
                Behavior on x {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
