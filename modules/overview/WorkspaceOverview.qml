pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

FocusScope {
    id: root

    required property PersistentProperties visibilities
    required property ShellScreen screen

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
    property real wsBorderWidth: 2  // Workspace border width for padding
    
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
    
    implicitWidth: overviewBackground.implicitWidth + elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + elevationMargin * 2

    // Invisible focusable item to receive keyboard events
    TextInput {
        id: keyHandler
        width: 0
        height: 0
        opacity: 0
        focus: true
        Keys.onEscapePressed: root.visibilities.overview = false
    }

    onVisibleChanged: if (visible) keyHandler.forceActiveFocus()

    Rectangle {
        id: overviewBackground
        property real padding: 10
        
        anchors.fill: parent
        anchors.margins: root.elevationMargin
        
        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 3
        }
        
        implicitWidth: wsGrid.implicitWidth + padding * 2
        implicitHeight: wsGrid.implicitHeight + padding * 2
        radius: root.uniformRadius
        color: Colours.palette.m3surfaceContainer

        // Workspace grid
        Column {
            id: wsGrid
            anchors.centerIn: parent
            spacing: root.workspaceSpacing
            
            Repeater {
                model: root.overviewRows
                
                Row {
                    id: wsRow
                    required property int index
                    spacing: root.workspaceSpacing
                    
                    Repeater {
                        model: root.overviewColumns
                        
                        Rectangle {
                            id: wsRect
                            required property int index
                            
                            property int wsNum: root.workspaceGroup * root.workspacesShown + wsRow.index * root.overviewColumns + index + 1
                            property bool dropHover: false
                            
                            width: root.wsWidth
                            height: root.wsHeight
                            radius: root.uniformRadius
                            color: dropHover ? Qt.lighter(Colours.palette.m3surfaceContainer, 1.15) : Qt.lighter(Colours.palette.m3surfaceContainer, 1.05)
                            border.width: 2
                            border.color: dropHover ? Colours.palette.m3tertiary : "transparent"
                            
                            // Workspace number
                            Text {
                                anchors.centerIn: parent
                                text: wsRect.wsNum
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                color: Qt.rgba(1, 1, 1, 0.15)
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
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

        // Windows layer
        Item {
            id: windowsLayer
            anchors.centerIn: parent
            width: wsGrid.implicitWidth
            height: wsGrid.implicitHeight
            
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
                    
                    // Offset to workspace cell (include border padding)
                    property real cellX: col * (root.wsWidth + root.workspaceSpacing) + root.wsBorderWidth
                    property real cellY: row * (root.wsHeight + root.workspaceSpacing) + root.wsBorderWidth
                    
                    // Usable area inside workspace (minus border on both sides)
                    property real usableWsWidth: root.wsWidth - root.wsBorderWidth * 2
                    property real usableWsHeight: root.wsHeight - root.wsBorderWidth * 2
                    
                    // Scale factor to fit windows within usable area
                    property real innerScale: usableWsWidth / root.wsWidth
                    
                    // Window position WITHIN the cell (scaled to fit inside border)
                    // SUBTRACT reserved to get position relative to workspace area (not monitor)
                    property real localX: Math.max((ipc?.at?.[0] ?? 0) - root.reserved[0], 0) * root.scale * innerScale
                    property real localY: Math.max((ipc?.at?.[1] ?? 0) - root.reserved[1], 0) * root.scale * innerScale
                    property real targetW: (ipc?.size?.[0] ?? 100) * root.scale * innerScale
                    property real targetH: (ipc?.size?.[1] ?? 100) * root.scale * innerScale
                    
                    // Target position
                    property real targetX: cellX + localX
                    property real targetY: cellY + localY
                    
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
                            duration: 100  // Fast resize
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: 100  // Fast resize
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
                        
                        ScreencopyView {
                            anchors.fill: parent
                            captureSource: root.visibilities.overview ? winItem.modelData.wayland : null
                            live: true
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: root.uniformRadius
                            color: winItem.prs ? Qt.rgba(1,1,1,0.2) : winItem.hov ? Qt.rgba(1,1,1,0.1) : "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1,1,1,0.1)
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
                            root.draggingFromWorkspace = -1
                            
                            if (target !== -1 && target !== winItem.wsId) {
                                // DIFFERENT workspace: animate first, dispatch later
                                const targetWsIdInGroup = target - root.workspaceGroup * root.workspacesShown
                                const targetCol = (targetWsIdInGroup - 1) % root.overviewColumns
                                const targetRow = Math.floor((targetWsIdInGroup - 1) / root.overviewColumns)
                                const targetCellX = targetCol * (root.wsWidth + root.workspaceSpacing) + root.wsBorderWidth
                                const targetCellY = targetRow * (root.wsHeight + root.workspaceSpacing) + root.wsBorderWidth
                                
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
                            }
                        }
                        
                        Timer {
                            id: dispatchTimer
                            property int targetWs: -1
                            property string addr: ""
                            interval: 50  // Dispatch quickly - don't wait for animation
                            onTriggered: {
                                Hypr.dispatch(`movetoworkspacesilent ${targetWs}, address:${addr}`)
                            }
                        }
                        onClicked: (e) => {
                            if (e.button === Qt.LeftButton) {
                                Hypr.dispatch(`focuswindow address:${winItem.addr}`)
                            } else if (e.button === Qt.MiddleButton) {
                                Hypr.dispatch(`closewindow address:${winItem.addr}`)
                            }
                        }
                    }
                }
            }

            // Active workspace border
            Rectangle {
                id: activeBorder
                property int aws: root.monitor.activeWorkspace?.id ?? 1
                property int awsInGroup: aws - root.workspaceGroup * root.workspacesShown
                property int c: (awsInGroup - 1) % root.overviewColumns
                property int r: Math.floor((awsInGroup - 1) / root.overviewColumns)
                
                x: c * (root.wsWidth + root.workspaceSpacing)
                y: r * (root.wsHeight + root.workspaceSpacing)
                width: root.wsWidth
                height: root.wsHeight
                color: "transparent"
                radius: root.uniformRadius
                border.width: 2
                border.color: root.activeBorderColor
                
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
