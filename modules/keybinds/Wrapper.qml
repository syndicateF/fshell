pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    // Visibility only depends on the toggle, not on having binds loaded
    readonly property bool shouldShow: visibilities.keybinds

    visible: opacity > 0
    opacity: shouldShow ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.OutCubic
        }
    }

    // Fetch binds when overlay becomes visible
    onShouldShowChanged: {
        if (shouldShow) {
            Keybinds.refreshIfDirty();
        }
    }

    // Also trigger initial fetch if not done yet
    Component.onCompleted: {
        if (Keybinds.binds.length === 0) {
            Keybinds.refresh();
        }
    }

    // Close on Escape
    Shortcut {
        enabled: root.shouldShow
        sequence: "Escape"
        onActivated: root.visibilities.keybinds = false
    }

    // Background scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.6)
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.visibilities.keybinds = false
        }
    }

    // Main content
    Content {
        anchors.centerIn: parent
        visibilities: root.visibilities
    }
}

