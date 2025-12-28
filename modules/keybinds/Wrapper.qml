pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

// FocusScope to receive keyboard events
FocusScope {
    id: root

    required property PersistentProperties visibilities

    // Signal emitted when exit animation completes
    signal exitAnimationDone()

    // Internal animation state
    property bool animState: false
    property bool isClosing: false

    visible: true
    focus: true

    // Function to close with animation
    function closeWithAnimation() {
        if (isClosing) return
        isClosing = true
        animState = false
        exitAnimTimer.start()
    }

    // Timer to wait for close animation
    Timer {
        id: exitAnimTimer
        interval: 200  // Match close duration
        onTriggered: {
            root.isClosing = false
            root.exitAnimationDone()
        }
    }

    // Start open animation on first frame
    Timer {
        id: openAnimTimer
        interval: 16
        running: true
        onTriggered: {
            root.animState = true
            Keybinds.refreshIfDirty();
            root.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        if (Keybinds.binds.length === 0) {
            Keybinds.refresh();
        }
    }

    Keys.onEscapePressed: root.visibilities.keybinds = false

    // Click anywhere outside to close (no scrim)
    MouseArea {
        anchors.fill: parent
        onClicked: root.visibilities.keybinds = false
    }

    // Content with popin 80% animation (like fuzzel)
    Content {
        id: content
        anchors.centerIn: parent
        visibilities: root.visibilities
        
        // Fuzzel popin 80% = scale from 0.8 to 1.0
        scale: root.animState ? 1.0 : 0.8
        opacity: root.animState ? 1 : 0
        transformOrigin: Item.Center
        
        Behavior on scale {
            NumberAnimation {
                duration: root.animState ? 300 : 200
                easing.type: root.animState ? Easing.OutCubic : Easing.InCubic
            }
        }
        
        Behavior on opacity {
            NumberAnimation {
                duration: root.animState ? 200 : 150
                easing.type: Easing.OutCubic
            }
        }
    }
}
