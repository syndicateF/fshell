pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// FocusScope to receive keyboard events
FocusScope {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    readonly property bool shouldShow: visibilities.keybinds

    visible: opacity > 0
    opacity: shouldShow ? 1 : 0
    focus: true

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutCubic
        }
    }

    onShouldShowChanged: {
        if (shouldShow) {
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

    // Semi-transparent scrim background
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.6)
        
        // Scrim click area - OUTSIDE content, closes overlay
        MouseArea {
            anchors.fill: parent
            onClicked: root.visibilities.keybinds = false
        }
    }

    // Main content - Content.qml has its own MouseArea to block clicks
    Content {
        id: content
        anchors.centerIn: parent
        visibilities: root.visibilities
    }
}
