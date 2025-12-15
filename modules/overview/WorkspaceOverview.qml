pragma ComponentBehavior: Bound

import qs.components.images
import qs.services
import qs.config
import qs.utils
import QtQuick
import Quickshell
import Quickshell.Hyprland

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
    
    property var monitorData: monitor?.lastIpcObject ?? null
    
    property color activeBorderColor: Colours.palette.m3primary
    property int uniformRadius: Config.border.rounding
    
    property var reserved: monitorData?.reserved ?? [0, 0, 0, 0]
    
    property real wsWidth: (monitor.width / monitor.scale - reserved[0] - reserved[2]) * scale
    property real wsHeight: (monitor.height / monitor.scale - reserved[1] - reserved[3]) * scale
    
    property real workspaceSpacing: 5
    property real windowPadding: 4
    
    property var specialWorkspaces: ["sysmon", "music", "communication", "todo"]
    
    function getSpecialAppInfo(wsName) {
        const apps = Config.overview.specialWorkspaceApps
        return apps[wsName] ?? { icon: "application-x-executable", command: "" }
    }
    
    // Drag state
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    
    implicitWidth: overviewContainer.implicitWidth
    implicitHeight: overviewContainer.implicitHeight

    Shortcut {
        enabled: root.visibilities.overview
        sequence: "Escape"
        onActivated: root.visibilities.overview = false
    }

    Item {
        id: overviewContainer
        property real padding: 20
        property real specialRowHeight: specialWsRow.visible ? specialWsRow.implicitHeight + root.workspaceSpacing + 20 : 0
        
        anchors.centerIn: parent
        
        implicitWidth: Math.max(wsGrid.implicitWidth, specialWsRow.implicitWidth) + padding * 2
        implicitHeight: wsGrid.implicitHeight + specialRowHeight + padding * 2

        Column {
            id: mainColumn
            anchors.centerIn: parent
            spacing: 0

            // Workspace grid
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
                            
                            Rectangle {
                                id: wsRect
                                required property int index
                                
                                property int wsNum: root.workspaceGroup * root.workspacesShown + wsRow.index * root.overviewColumns + index + 1
                                
                                width: root.wsWidth
                                height: root.wsHeight
                                radius: root.uniformRadius
                                color: Colours.palette.m3surfaceContainer
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: wsRect.wsNum
                                    font.pointSize: Config.overview.sizes.workspaceNumberWatermark
                                    font.weight: Font.Bold
                                    color: Qt.rgba(1, 1, 1, 0.1)
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        const specialWs = root.monitorData?.specialWorkspace?.name ?? ""
                                        if (specialWs !== "" && specialWs.startsWith("special:")) {
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
                                    }
                                    onExited: {
                                        if (root.draggingTargetWorkspace === wsRect.wsNum) 
                                            root.draggingTargetWorkspace = -1
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
                topPadding: 8
                
                Rectangle {
                    width: wsGrid.implicitWidth
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.1)
                    opacity: 0.5
                }
                
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
                            property var specialWsObj: Hypr.workspaces.values.find(w => w.name === `special:${wsName}`)
                            property bool hasWindows: (specialWsObj?.lastIpcObject?.windows ?? 0) > 0
                            
                            width: root.wsWidth
                            height: root.wsHeight
                            radius: root.uniformRadius
                            color: isActive ? Qt.alpha(Colours.palette.m3primary, 0.12) : Colours.palette.m3surfaceContainer
                            
                            Behavior on color { ColorAnimation { duration: Appearance.anim.durations.small } }
                            
                            // Icon + info when no windows
                            Column {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.small
                                visible: !specialWsRect.hasWindows
                                
                                CachingIconImage {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: Icons.getAppIcon(specialWsRect.appInfo.icon ?? "", "application-x-executable")
                                    implicitSize: Math.min(specialWsRect.width, specialWsRect.height) * 0.25
                                }
                                
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: specialWsRect.appInfo.app ?? specialWsRect.wsName
                                    font.pointSize: Appearance.font.size.smaller
                                    font.weight: Font.DemiBold
                                    font.family: Appearance.font.family.sans
                                    color: specialWsRect.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                }
                                
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: specialWsRect.wsName
                                    font.pointSize: Appearance.font.size.small
                                    font.weight: Font.Normal
                                    font.family: Appearance.font.family.sans
                                    font.capitalization: Font.AllUppercase
                                    color: Colours.palette.m3onSurfaceVariant
                                    opacity: 0.7
                                }
                            }
                            
                            // Simple window placeholders (no screencopy!)
                            Item {
                                anchors.fill: parent
                                visible: specialWsRect.hasWindows
                                
                                Repeater {
                                    model: ScriptModel {
                                        values: {
                                            const ws = specialWsRect.specialWsObj
                                            if (!ws) return []
                                            let arr = []
                                            for (const tl of ws.toplevels.values) arr.push(tl)
                                            return arr.reverse()
                                        }
                                    }
                                    
                                    Rectangle {
                                        id: specialWinRect
                                        required property var modelData
                                        
                                        property var ipc: modelData.lastIpcObject
                                        property real localX: Math.max((ipc?.at?.[0] ?? 0) - root.reserved[0], 0) * root.scale
                                        property real localY: Math.max((ipc?.at?.[1] ?? 0) - root.reserved[1], 0) * root.scale
                                        
                                        x: localX + root.windowPadding / 2
                                        y: localY + root.windowPadding / 2
                                        width: Math.max((ipc?.size?.[0] ?? 100) * root.scale - root.windowPadding, 10)
                                        height: Math.max((ipc?.size?.[1] ?? 100) * root.scale - root.windowPadding, 10)
                                        radius: root.uniformRadius
                                        color: Colours.palette.m3surfaceContainerHighest
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.1)
                                        
                                        // App icon
                                        CachingIconImage {
                                            anchors.centerIn: parent
                                            source: Icons.getAppIcon(specialWinRect.ipc?.class ?? specialWinRect.ipc?.initialClass ?? "", "application-x-executable")
                                            implicitSize: Math.min(parent.width, parent.height) * 0.25
                                            opacity: 0.85
                                        }
                                    }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                z: 2
                                onClicked: {
                                    const specialWsData = Hypr.workspaces.values.find(ws => ws.name === `special:${specialWsRect.wsName}`)
                                    const hasWindows = specialWsData?.lastIpcObject?.windows > 0 ?? false
                                    
                                    Hypr.dispatch(`togglespecialworkspace ${specialWsRect.wsName}`)
                                    
                                    if (!hasWindows) {
                                        const appInfo = root.getSpecialAppInfo(specialWsRect.wsName)
                                        root.popouts.loadingWsName = specialWsRect.wsName
                                        root.popouts.loadingAppInfo = appInfo
                                        root.popouts.detach("loading")
                                        
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

        // Windows layer - simple colored rectangles, NO screencopy
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
                        const minWs = root.workspaceGroup * root.workspacesShown
                        const maxWs = minWs + root.workspacesShown
                        const arr = []
                        
                        for (const ws of Hypr.workspaces.values) {
                            const wsId = ws.id
                            if (wsId <= minWs || wsId > maxWs) continue
                            for (const tl of ws.toplevels.values) arr.push(tl)
                        }
                        return arr.reverse()
                    }
                }
                
                Rectangle {
                    id: winItem
                    required property var modelData
                    
                    property var ipc: modelData.lastIpcObject
                    property string addr: `0x${modelData.address}`
                    property var htWorkspace: modelData.workspace
                    property int wsId: htWorkspace ? htWorkspace.id : 1
                    
                    property int wsIdInGroup: wsId - root.workspaceGroup * root.workspacesShown
                    property int col: (wsIdInGroup - 1) % root.overviewColumns
                    property int row: Math.floor((wsIdInGroup - 1) / root.overviewColumns)
                    
                    property real cellX: col * (root.wsWidth + root.workspaceSpacing)
                    property real cellY: row * (root.wsHeight + root.workspaceSpacing)
                    property real localX: Math.max((ipc?.at?.[0] ?? 0) - root.reserved[0], 0) * root.scale
                    property real localY: Math.max((ipc?.at?.[1] ?? 0) - root.reserved[1], 0) * root.scale
                    property real targetW: Math.max((ipc?.size?.[0] ?? 100) * root.scale - root.windowPadding, 10)
                    property real targetH: Math.max((ipc?.size?.[1] ?? 100) * root.scale - root.windowPadding, 10)
                    property real targetX: cellX + localX + root.windowPadding / 2
                    property real targetY: cellY + localY + root.windowPadding / 2
                    
                    x: targetX
                    y: targetY
                    width: targetW
                    height: targetH
                    
                    z: dragArea.drag.active ? 9999 : (ipc?.floating ? 2 : 1)
                    radius: root.uniformRadius
                    color: hov ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainerHighest
                    border.width: 1
                    border.color: hov ? Colours.palette.m3primary : Qt.rgba(1, 1, 1, 0.15)
                    
                    // App icon centered in window
                    CachingIconImage {
                        anchors.centerIn: parent
                        source: Icons.getAppIcon(winItem.ipc?.class ?? winItem.ipc?.initialClass ?? "", "application-x-executable")
                        implicitSize: Math.min(parent.width, parent.height) * 0.25
                        opacity: 0.85
                    }
                    
                    property bool hov: false
                    property bool dragging: false
                    
                    Behavior on x {
                        enabled: root.visibilities.overview && !winItem.dragging
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                        enabled: root.visibilities.overview && !winItem.dragging
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                    
                    Drag.active: dragArea.drag.active
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    
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
                            winItem.dragging = true
                        }
                        onReleased: {
                            winItem.dragging = false
                            const target = root.draggingTargetWorkspace
                            
                            if (target !== -1 && target !== winItem.wsId) {
                                const targetWsIdInGroup = target - root.workspaceGroup * root.workspacesShown
                                const targetCol = (targetWsIdInGroup - 1) % root.overviewColumns
                                const targetRow = Math.floor((targetWsIdInGroup - 1) / root.overviewColumns)
                                const targetCellX = targetCol * (root.wsWidth + root.workspaceSpacing)
                                const targetCellY = targetRow * (root.wsHeight + root.workspaceSpacing)
                                
                                winItem.x = targetCellX + winItem.localX
                                winItem.y = targetCellY + winItem.localY
                                
                                dispatchTimer.targetWs = target
                                dispatchTimer.addr = winItem.addr
                                dispatchTimer.start()
                            } else {
                                winItem.x = winItem.targetX
                                winItem.y = winItem.targetY
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
                                root.draggingFromWorkspace = -1
                            }
                        }
                        
                        onClicked: (e) => {
                            if (e.button === Qt.LeftButton) {
                                const specialWs = root.monitorData?.specialWorkspace?.name ?? ""
                                if (specialWs !== "" && specialWs.startsWith("special:")) {
                                    const specialName = specialWs.replace("special:", "")
                                    Hypr.dispatch(`togglespecialworkspace ${specialName}`)
                                }
                                Hypr.dispatch(`workspace ${winItem.wsId}`)
                            } else if (e.button === Qt.MiddleButton) {
                                Hypr.dispatch(`closewindow address:${winItem.addr}`)
                            }
                        }
                    }
                }
            }
        }

        // Active border & drop indicator
        Item {
            id: bordersLayer
            x: mainColumn.x + (mainColumn.width - wsGrid.implicitWidth) / 2
            y: mainColumn.y
            width: Math.max(wsGrid.implicitWidth, specialWsRowContent.implicitWidth)
            height: mainColumn.implicitHeight
            z: 10

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

            Rectangle {
                id: activeBorder
                
                property var specialWsObj: root.monitorData?.specialWorkspace ?? null
                property string activeSpecialName: specialWsObj?.name ?? ""
                property bool isSpecialActive: activeSpecialName !== "" && activeSpecialName.startsWith("special:")
                property string specialName: isSpecialActive ? activeSpecialName.replace("special:", "") : ""
                property int specialIndex: isSpecialActive ? root.specialWorkspaces.indexOf(specialName) : -1
                
                property int aws: root.monitor.activeWorkspace?.id ?? 1
                property int awsInGroup: aws - root.workspaceGroup * root.workspacesShown
                property bool awsInRange: awsInGroup >= 1 && awsInGroup <= root.workspacesShown
                property int normalCol: awsInRange ? (awsInGroup - 1) % root.overviewColumns : 0
                property int normalRow: awsInRange ? Math.floor((awsInGroup - 1) / root.overviewColumns) : 0
                
                property real normalX: normalCol * (root.wsWidth + root.workspaceSpacing)
                property real normalY: normalRow * (root.wsHeight + root.workspaceSpacing)
                
                property real specialRowTopY: wsGrid.implicitHeight + specialWsRow.topPadding + 1 + specialWsRow.spacing
                property real specialX: specialIndex >= 0 ? specialIndex * (root.wsWidth + root.workspaceSpacing) : 0
                property real specialY: specialIndex >= 0 ? specialRowTopY : 0
                
                property bool useSpecialPosition: isSpecialActive && specialIndex >= 0
                
                x: useSpecialPosition ? specialX : normalX
                y: useSpecialPosition ? specialY : normalY
                width: root.wsWidth
                height: root.wsHeight
                color: "transparent"
                radius: root.uniformRadius
                border.width: 2
                border.color: root.activeBorderColor
                
                visible: useSpecialPosition || (!isSpecialActive && awsInRange)
                
                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }
    }
}
