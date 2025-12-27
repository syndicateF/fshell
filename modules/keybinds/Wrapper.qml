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

    // Main content container with its own MouseArea to BLOCK clicks
    Rectangle {
        id: contentContainer
        anchors.centerIn: parent
        
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight
        
        color: "transparent"
        
        // THIS is the key: MouseArea that blocks ALL clicks from reaching scrim
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            // Don't do anything, just block propagation
            onClicked: event => event.accepted = true
            onPressed: event => event.accepted = true
            onReleased: event => event.accepted = true
            onDoubleClicked: event => event.accepted = true
        }
        
        Content {
            id: content
            visibilities: root.visibilities
        }
    }
}
