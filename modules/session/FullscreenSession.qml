pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

FocusScope {
    id: root

    required property PersistentProperties visibilities
    required property ShellScreen screen

    signal exitAnimationDone()

    readonly property bool isActive: visibilities.fullscreenSession || isClosing
    property int focusedIndex: 0
    property int confirmFocusIndex: 1  // 0 = Cancel, 1 = Confirm

    property bool enterAnimation: false
    property bool exitAnimation: false
    property bool isClosing: false

    property string pendingAction: ""
    property int countdown: Config.session.sizes.countdownSecs

    implicitWidth: screen.width
    implicitHeight: screen.height

    focus: true

    readonly property var actions: [
        { icon: "logout", action: "logout" },
        { icon: "bedtime", action: "sleep" },
        { icon: "restart_alt", action: "restart" },
        { icon: "power_settings_new", action: "shutdown" }
    ]

    function closeWithAnimation() {
        if (isClosing) return
        isClosing = true
        exitAnimation = true
        pendingAction = ""
        countdownTimer.stop()
        exitAnimTimer.start()
    }

    function requestAction(actionType: string) {
        pendingAction = actionType
        confirmFocusIndex = 1  // Default to Confirm
        countdown = Config.session.sizes.countdownSecs
        countdownTimer.start()
    }

    function cancelAction() {
        pendingAction = ""
        countdown = Config.session.sizes.countdownSecs
        countdownTimer.stop()
    }

    function executeAction() {
        countdownTimer.stop()
        const actionType = pendingAction
        pendingAction = ""
        
        let cmd = []
        if (actionType === "logout") cmd = Config.session.commands.logout
        else if (actionType === "sleep") cmd = Config.session.commands.sleep
        else if (actionType === "restart") cmd = Config.session.commands.reboot
        else if (actionType === "shutdown") cmd = Config.session.commands.shutdown
        
        if (cmd.length > 0) {
            closeWithAnimation()
            Qt.callLater(() => Quickshell.execDetached(cmd))
        }
    }

    // Keyboard navigation
    Keys.onPressed: event => {
        if (root.pendingAction !== "") {
            // In confirm dialog
            if (event.key === Qt.Key_Escape) {
                root.cancelAction()
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                root.confirmFocusIndex = 0
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                root.confirmFocusIndex = 1
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.confirmFocusIndex === 0) root.cancelAction()
                else root.executeAction()
                event.accepted = true
            }
            return
        }

        if (event.key === Qt.Key_Escape) {
            root.closeWithAnimation()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            root.focusedIndex = Math.max(0, root.focusedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            root.focusedIndex = Math.min(root.actions.length - 1, root.focusedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.requestAction(root.actions[root.focusedIndex].action)
            event.accepted = true
        }
    }

    onIsActiveChanged: {
        if (isActive) {
            enterAnimation = true
            exitAnimation = false
            isClosing = false
            pendingAction = ""
            focusedIndex = 0
            confirmFocusIndex = 1
            countdown = Config.session.sizes.countdownSecs
            enterAnimTimer.start()
            root.forceActiveFocus()
        } else {
            enterAnimation = false
            exitAnimation = false
            isClosing = false
            pendingAction = ""
        }
    }

    Timer {
        id: enterAnimTimer
        interval: 50
        onTriggered: root.enterAnimation = false
    }

    Timer {
        id: exitAnimTimer
        interval: 400
        onTriggered: root.exitAnimationDone()
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--
            if (root.countdown <= 0) root.executeAction()
        }
    }

    // ========== BLUR BG ==========
    ScreencopyView {
        anchors.fill: parent
        captureSource: root.isActive ? root.screen : null
        opacity: (root.enterAnimation || root.exitAnimation) ? 0 : 1

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
        }

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
        }
    }

    // Dark overlay
    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3surface
        opacity: (root.enterAnimation || root.exitAnimation) ? 0 : (Colours.transparency.enabled ? 0.92 : 0.98)

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
        }
    }

    // Click to close
    MouseArea {
        anchors.fill: parent
        enabled: root.pendingAction === ""
        onClicked: root.closeWithAnimation()
    }

    // ========== POWER BUTTONS ==========
    Column {
        anchors.centerIn: parent
        spacing: 32
        visible: root.pendingAction === ""
        opacity: (root.enterAnimation || root.exitAnimation) ? 0 : 1
        scale: (root.enterAnimation || root.exitAnimation) ? 0.85 : 1

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }

        // Uptime badge (above buttons)
        StyledRect {
            // anchors.horizontalCenter: parent.horizontalCenter
            // color: Colours.palette.m3secondaryContainer
            color: Colours.palette.m3secondary
            radius: Appearance.rounding.full
            implicitWidth: uptimeRow.implicitWidth + Appearance.padding.large * 2
            implicitHeight: uptimeRow.implicitHeight + Appearance.padding.normal * 2

            Row {
                id: uptimeRow
                anchors.centerIn: parent
                // spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "schedule"
                    font.pointSize: Appearance.font.size.normal
                    font.weight: Font.Medium
                    color: Colours.palette.m3surface
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    // text: "uptime: " + SysInfo.uptime
                    text: " " + SysInfo.uptime
                    font.pointSize: Appearance.font.size.small
                    // font.weight: Font.Medium
                    color: Colours.palette.m3surface
                }
            }
        }

        // Buttons row
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 54

            Repeater {
                model: root.actions

                delegate: StyledRect {
                    id: btnContainer
                    required property var modelData
                    required property int index

                    property bool isFocused: root.focusedIndex === index
                    property bool isHovered: btnMouseArea.containsMouse
                    property bool isShutdown: modelData.action === "shutdown"

                    width: 160
                    height: 160
                    // Toggle-style radius: smaller when focused/hovered, larger when inactive
                    radius: (isFocused || isHovered) ? 99 : 30
                    
                    // Toggle-style colors (like IconButton)
                    color: (isFocused || isHovered) 
                        ? (isShutdown ? Colours.palette.m3error : Colours.palette.m3primary)
                        : Colours.tPalette.m3surfaceContainer

                    scale: isHovered ? 1.08 : (isFocused ? 1.03 : 1)

                    Behavior on radius {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on color { 
                        ColorAnimation { 
                            duration: Appearance.anim.durations.expressiveFastSpatial 
                        } 
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: btnContainer.modelData.icon
                        font.pointSize: 50
                        // Toggle-style icon colors
                        color: (btnContainer.isFocused || btnContainer.isHovered) 
                            ? (btnContainer.isShutdown ? Colours.palette.m3onError : Colours.palette.m3onPrimary)
                            : Colours.palette.m3onSurfaceVariant

                        Behavior on color { 
                            ColorAnimation { 
                                duration: Appearance.anim.durations.expressiveFastSpatial 
                            } 
                        }
                    }

                    MouseArea {
                        id: btnMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.focusedIndex = btnContainer.index
                            root.requestAction(btnContainer.modelData.action)
                        }
                        onEntered: root.focusedIndex = btnContainer.index
                    }
                }
            }
        }

        // Hint
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← → Navigate • Enter Select • Esc Close"
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3outline
        }
    }

    // ========== CONFIRMATION DIALOG ==========
    Item {
        id: confirmDialogContainer
        anchors.fill: parent
        visible: opacity > 0
        opacity: root.pendingAction !== "" ? 1 : 0
        scale: root.pendingAction !== "" ? 1 : 0.85

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: root.pendingAction !== "" ? Easing.OutBack : Easing.InCubic } }

        property bool isShutdownAction: root.pendingAction === "shutdown"
        property string actionDescription: {
            if (root.pendingAction === "logout") return "You will be logged out and all unsaved work will be lost."
            if (root.pendingAction === "sleep") return "Your computer will enter sleep mode."
            if (root.pendingAction === "restart") return "Your computer will restart. Save your work before continuing."
            return "Your computer will shut down. Save your work before continuing."
        }
        property string actionIcon: {
            if (root.pendingAction === "logout") return "logout"
            if (root.pendingAction === "sleep") return "bedtime"
            if (root.pendingAction === "restart") return "restart_alt"
            return "power_settings_new"
        }
        property string actionTitle: {
            if (root.pendingAction === "logout") return "Log Out?"
            if (root.pendingAction === "sleep") return "Sleep?"
            if (root.pendingAction === "restart") return "Restart?"
            return "Shut Down?"
        }

        // Center card
        StyledRect {
            anchors.centerIn: parent
            width: 400
            height: 340
            radius: Appearance.rounding.large
            color: Colours.palette.m3surface

            Column {
                anchors.centerIn: parent
                spacing: 20

                // Icon
                StyledRect {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72
                    height: 72
                    radius: 36
                    color: confirmDialogContainer.isShutdownAction 
                        ? Colours.palette.m3errorContainer 
                        : Colours.palette.m3primaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: confirmDialogContainer.actionIcon
                        font.pointSize: 36
                        color: confirmDialogContainer.isShutdownAction 
                            ? Colours.palette.m3onErrorContainer 
                            : Colours.palette.m3onPrimaryContainer
                    }
                }

                // Title
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: confirmDialogContainer.actionTitle
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Bold
                    color: Colours.palette.m3onSurface
                }

                // Description
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 320
                    text: confirmDialogContainer.actionDescription
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                // Countdown
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Proceeding in " + root.countdown + "s"
                    font.pointSize: Appearance.font.size.normal
                    font.weight: Font.Medium
                    color: confirmDialogContainer.isShutdownAction 
                        ? Colours.palette.m3error 
                        : Colours.palette.m3primary
                }

                // Buttons
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    // Cancel
                    StyledRect {
                        id: cancelBtn
                        property bool isFocused: root.confirmFocusIndex === 0
                        property bool isHovered: cancelArea.containsMouse

                        width: 120
                        height: 48
                        radius: Appearance.rounding.full
                        color: (isFocused || isHovered)
                            ? Colours.palette.m3surfaceContainerHighest 
                            : Colours.palette.m3surfaceContainer
                        border.width: isFocused ? 2 : 0
                        border.color: Colours.palette.m3outline

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.width { NumberAnimation { duration: 100 } }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pointSize: Appearance.font.size.normal
                            font.weight: Font.Medium
                            color: Colours.palette.m3onSurface
                        }

                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cancelAction()
                            onEntered: root.confirmFocusIndex = 0
                        }
                    }

                    // Confirm
                    StyledRect {
                        id: confirmBtn
                        property bool isFocused: root.confirmFocusIndex === 1
                        property bool isHovered: confirmArea.containsMouse

                        width: 120
                        height: 48
                        radius: Appearance.rounding.full
                        color: (isFocused || isHovered)
                            ? (confirmDialogContainer.isShutdownAction ? Colours.palette.m3error : Colours.palette.m3primary)
                            : (confirmDialogContainer.isShutdownAction ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer)
                        border.width: isFocused ? 2 : 0
                        border.color: confirmDialogContainer.isShutdownAction ? Colours.palette.m3error : Colours.palette.m3primary

                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.width { NumberAnimation { duration: 100 } }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Confirm"
                            font.pointSize: Appearance.font.size.normal
                            font.weight: Font.Medium
                            color: (confirmBtn.isFocused || confirmBtn.isHovered)
                                ? (confirmDialogContainer.isShutdownAction ? Colours.palette.m3onError : Colours.palette.m3onPrimary)
                                : (confirmDialogContainer.isShutdownAction ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer)
                        }

                        MouseArea {
                            id: confirmArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.executeAction()
                            onEntered: root.confirmFocusIndex = 1
                        }
                    }
                }
            }
        }
    }
}
