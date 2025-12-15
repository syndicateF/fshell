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
import "./layouts"

FocusScope {
    id: root

    required property PersistentProperties visibilities
    required property ShellScreen screen

    // Signal emitted when exit animation completes
    signal exitAnimationDone()

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool isActive: visibilities.spiralOverview || isClosing
    
    property int uniformRadius: Config.border.rounding
    
    // Animation state
    property bool enterAnimation: false
    property bool exitAnimation: false
    property bool isClosing: false

    implicitWidth: screen.width
    implicitHeight: screen.height

    // Function to close with animation
    function closeWithAnimation() {
        if (isClosing) return
        isClosing = true
        exitAnimation = true
        exitAnimTimer.start()
    }

    // ESC to close
    Shortcut {
        enabled: root.isActive && !root.isClosing
        sequence: "Escape"
        onActivated: root.closeWithAnimation()
    }

    // Reset state when opening/closing
    onIsActiveChanged: {
        if (isActive) {
            exposeArea.currentIndex = -1
            enterAnimation = true
            exitAnimation = false
            isClosing = false
            Hyprland.refreshToplevels()
            refreshThumbs()
            // Start enter animation after a frame
            enterAnimTimer.start()
        } else {
            enterAnimation = false
            exitAnimation = false
            isClosing = false
        }
    }

    // Timer to trigger enter animation
    Timer {
        id: enterAnimTimer
        interval: 50
        onTriggered: root.enterAnimation = false
    }

    // Timer to delay actual close after exit animation
    Timer {
        id: exitAnimTimer
        interval: 400
        onTriggered: root.exitAnimationDone()
    }

    // Update thumbs periodically
    Timer {
        id: screencopyTimer
        interval: 125
        repeat: true
        running: root.isActive
        onTriggered: root.refreshThumbs()
    }

    function refreshThumbs() {
        if (!root.isActive) return
        for (var i = 0; i < winRepeater.count; ++i) {
            var it = winRepeater.itemAt(i)
            if (it && it.visible && it.refreshThumb) {
                it.refreshThumb()
            }
        }
    }

    // Wallpaper background - covers Hyprland windows with same wallpaper
    Image {
        anchors.fill: parent
        source: Wallpapers.current
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        
        // Fade in/out animation
        opacity: (root.enterAnimation || root.exitAnimation) ? 0 : 1
        
        Behavior on opacity {
            NumberAnimation { 
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }

    // Click background to close
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeWithAnimation()
    }
    
    // Close All button (bottom center) - only show if more than 1 window
    Rectangle {
        id: closeAllBtn
        width: closeAllContent.implicitWidth + 32
        height: 44
        radius: 22
        z: 1000
        
        // Hide if only 1 or 0 windows
        visible: winRepeater.count > 1
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        
        color: closeAllArea.containsMouse ? Colours.palette.m3errorContainer : Colours.palette.m3surfaceContainerHigh
        
        // Enter/exit animation
        opacity: (root.enterAnimation || root.exitAnimation) ? 0 : 1
        transform: Translate { y: (root.enterAnimation || root.exitAnimation) ? 50 : 0 }
        
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: 100 }
        }
        
        Row {
            id: closeAllContent
            anchors.centerIn: parent
            spacing: 8
            
            Text {
                text: "✕"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: closeAllArea.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurface
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: "Close All"
                font.pixelSize: Appearance.font.size.normal
                font.weight: Font.Medium
                font.family: Appearance.font.family.sans
                color: closeAllArea.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        MouseArea {
            id: closeAllArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // Simple approach: close all and exit
                var addresses = []
                for (var i = 0; i < winRepeater.count; i++) {
                    var item = winRepeater.itemAt(i)
                    if (item && item.hWin && item.hWin.address) {
                        addresses.push(item.hWin.address)
                    }
                }
                // Close all at once
                for (var j = 0; j < addresses.length; j++) {
                    Hypr.dispatch("closewindow address:0x" + addresses[j])
                }
                // Close overview after short delay
                closeAllTimer.start()
            }
        }
        
        Timer {
            id: closeAllTimer
            interval: 500
            onTriggered: root.closeWithAnimation()
        }
    }

    // Main expose area
    Item {
        id: exposeArea
        anchors.fill: parent
        anchors.margins: 32
        
        property int currentIndex: -1

        ScriptModel {
            id: windowLayoutModel

            property int areaW: exposeArea.width
            property int areaH: exposeArea.height
            property var rawToplevels: Hyprland.toplevels.values

            values: {
                if (areaW <= 0 || areaH <= 0) return []
                if (!rawToplevels) return []

                var windowList = []
                var idx = 0

                for (var it of rawToplevels) {
                    var w = it
                    var clientInfo = w && w.lastIpcObject ? w.lastIpcObject : {}
                    var workspace = clientInfo && clientInfo.workspace ? clientInfo.workspace : null
                    var workspaceId = workspace && workspace.id !== undefined ? workspace.id : undefined

                    // Filter invalid workspace or offscreen windows
                    if (workspaceId === undefined || workspaceId === null) continue
                    // Skip special workspaces (negative IDs)
                    if (workspaceId < 0) continue
                    
                    var size = clientInfo && clientInfo.size ? clientInfo.size : [0, 0]
                    var at = clientInfo && clientInfo.at ? clientInfo.at : [-1000, -1000]
                    if (at[1] + size[1] <= 0) continue

                    windowList.push({
                        win: w,
                        clientInfo: clientInfo,
                        workspaceId: workspaceId,
                        width: size[0],
                        height: size[1],
                        originalIndex: idx++,
                        lastIpcObject: w.lastIpcObject
                    })
                }

                // Sort by workspaceId, then originalIndex
                windowList.sort(function(a, b) {
                    if (a.workspaceId < b.workspaceId) return -1
                    if (a.workspaceId > b.workspaceId) return 1
                    if (a.originalIndex < b.originalIndex) return -1
                    if (a.originalIndex > b.originalIndex) return 1
                    return 0
                })

                return SpiralLayout.doLayout(windowList, areaW, areaH)
            }
        }

        Repeater {
            id: winRepeater
            model: windowLayoutModel

            delegate: Item {
                id: thumbContainer
                required property var modelData
                required property int index

                property var hWin: modelData.win
                property var wHandle: hWin?.wayland ?? null
                property string winKey: String(hWin?.address ?? "")

                property real thumbW: modelData.width
                property real thumbH: modelData.height

                property real targetX: modelData.x
                property real targetY: modelData.y

                property bool hovered: visible && (exposeArea.currentIndex === index)

                width: thumbW
                height: thumbH
                x: targetX
                y: targetY
                z: hovered ? 1000 : 0

                visible: !!wHandle

                // Determine if this item is on the left or right side
                readonly property bool isOnLeftSide: (targetX + thumbW / 2) < (exposeArea.width / 2)
                
                // Enter/Exit animation offset
                readonly property real animOffset: {
                    if (root.enterAnimation) return isOnLeftSide ? -150 : 150
                    if (root.exitAnimation) return isOnLeftSide ? -150 : 150
                    return 0
                }
                
                // Apply transform for enter animation
                transform: Translate {
                    x: thumbContainer.animOffset
                    
                    Behavior on x {
                        NumberAnimation { 
                            duration: 350
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                
                // Fade animation
                opacity: (root.enterAnimation || root.exitAnimation) ? 0 : 1
                
                Behavior on opacity {
                    NumberAnimation { 
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                function activateWindow() {
                    // Store values first (safe copies)
                    var win = hWin
                    if (!win) return
                    
                    var addr = win.address ?? null
                    if (!addr) return
                    
                    // Check if target is in special workspace
                    var targetIsSpecial = (win.workspace ?? 0) < 0 || 
                                          (win.workspace?.name ?? "").startsWith("special")

                    // Close special workspace if needed
                    var monitorData = root.monitor?.lastIpcObject ?? null
                    var specialWs = monitorData?.specialWorkspace?.name ?? ""
                    if (specialWs !== "" && specialWs.startsWith("special:") && !targetIsSpecial) {
                        var specialName = specialWs.replace("special:", "")
                        Hypr.dispatch(`togglespecialworkspace ${specialName}`)
                    }

                    if (win.workspace) {
                        win.workspace.activate()
                    }

                    Hypr.dispatch("focuswindow address:0x" + addr)
                    Hypr.dispatch("alterzorder top")
                    root.closeWithAnimation()
                }

                function closeWindow() {
                    // Store address first (safe string copy)
                    var addr = hWin?.address ?? null
                    if (!addr) return
                    Hypr.dispatch("closewindow address:0x" + addr)
                }

                function refreshThumb() {
                    if (screenCopy) {
                        screenCopy.captureFrame()
                    }
                }

                // Card visual
                Item {
                    id: card
                    anchors.fill: parent

                    scale: thumbContainer.hovered ? 1.05 : 0.95
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }

                    // Shadow
                    Elevation {
                        anchors.fill: parent
                        radius: root.uniformRadius
                        level: thumbContainer.hovered ? 4 : 2
                    }

                    // Window preview
                    ClippingRectangle {
                        id: previewClip
                        anchors.fill: parent
                        radius: root.uniformRadius
                        color: Colours.palette.m3surfaceContainer

                        ScreencopyView {
                            id: screenCopy
                            anchors.fill: parent
                            captureSource: root.isActive ? thumbContainer.wHandle : null
                            live: false
                            paintCursor: false
                        }

                        // Subtle border (no hover color)
                        Rectangle {
                            anchors.fill: parent
                            radius: root.uniformRadius
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1,1,1,0.1)
                        }
                        
                        // Main click area for window activation
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                            onEntered: exposeArea.currentIndex = thumbContainer.index
                            onExited: {
                                // Only reset if not hovering close button
                                if (!closeBtnArea.containsMouse && exposeArea.currentIndex === thumbContainer.index)
                                    exposeArea.currentIndex = -1
                            }
                            onClicked: event => {
                                if (event.button === Qt.LeftButton) {
                                    thumbContainer.activateWindow()
                                } else if (event.button === Qt.MiddleButton) {
                                    thumbContainer.closeWindow()
                                }
                            }
                        }
                    }
                    
                    // Blinking focus outline
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: root.uniformRadius + 2
                        color: "transparent"
                        border.width: 3
                        border.color: Colours.palette.m3primary
                        visible: thumbContainer.hovered
                        
                        // Blink animation
                        SequentialAnimation on opacity {
                            running: thumbContainer.hovered
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.3; duration: 400; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.3; to: 1; duration: 400; easing.type: Easing.InOutQuad }
                        }
                        opacity: thumbContainer.hovered ? 1 : 0
                    }
                    
                    // Close button per window (top right) - OUTSIDE clip area
                    Rectangle {
                        id: closeBtn
                        width: 28
                        height: 28
                        radius: 14
                        z: 200
                        color: closeBtnArea.containsMouse ? Colours.palette.m3errorContainer : Colours.palette.m3surfaceContainerHighest
                        
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        
                        visible: thumbContainer.hovered
                        opacity: thumbContainer.hovered ? 1 : 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }
                        
                        // X icon
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: closeBtnArea.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurface
                        }
                        
                        MouseArea {
                            id: closeBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // Keep window hovered when on close button
                            onContainsMouseChanged: {
                                if (containsMouse) {
                                    exposeArea.currentIndex = thumbContainer.index
                                }
                            }
                            onClicked: {
                                // Just close window, don't close overview
                                thumbContainer.closeWindow()
                            }
                        }
                    }

                    // Title badge
                    Rectangle {
                        id: badge
                        z: 100
                        width: Math.min(titleText.implicitWidth + 24, thumbContainer.thumbW * 0.75)
                        height: titleText.implicitHeight + 12

                        x: (card.width - width) / 2
                        y: card.height - height - (card.height * 0.08)

                        radius: root.uniformRadius
                        color: thumbContainer.hovered ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainer
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant

                        Behavior on color {
                            ColorAnimation { duration: Appearance.anim.durations.small }
                        }

                        StyledText {
                            id: titleText
                            anchors.centerIn: parent
                            width: parent.width - 16
                            text: thumbContainer.hWin?.title ?? ""
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.smaller
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    // Keyboard navigation
    Keys.onPressed: event => {
        if (!root.isActive) return

        if (event.key === Qt.Key_Escape) {
            root.visibilities.spiralOverview = false
            event.accepted = true
            return
        }

        const total = winRepeater.count
        if (total <= 0) return

        function moveSelectionHorizontal(delta) {
            var start = exposeArea.currentIndex
            if (start < 0) start = 0
            for (var step = 1; step <= total; ++step) {
                var candidate = (start + delta * step + total) % total
                var it = winRepeater.itemAt(candidate)
                if (it && it.visible) {
                    exposeArea.currentIndex = candidate
                    return
                }
            }
        }

        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            moveSelectionHorizontal(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
            moveSelectionHorizontal(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            var item = winRepeater.itemAt(exposeArea.currentIndex)
            if (item && item.activateWindow) {
                item.activateWindow()
                event.accepted = true
            }
        }
    }
}
