pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import QtQuick

/**
 * AppGrid Wrapper — independent fullscreen overlay.
 *
 * Animations:
 *   - Enter: slide up from bottom + backdrop fade in
 *   - Exit:  slide down + backdrop fade out
 *
 * Blur: backdrop opacity 0.6 > ignorealpha 0.57 threshold → Hyprland blur active.
 */
Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    signal exitAnimationDone()

    anchors.fill: parent
    visible: true

    function closeWithAnimation(): void {
        showAnim.stop();
        hideAnim.start();
    }

    Component.onCompleted: {
        hideAnim.stop();
        showAnim.start();
    }

    // ── Enter: slide up ─────────────────────────────────────
    ParallelAnimation {
        id: showAnim

        NumberAnimation {
            target: contentContainer
            property: "y"
            from: root.height; to: 0
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    // ── Exit: slide down ───────────────────────────────────
    SequentialAnimation {
        id: hideAnim

        ParallelAnimation {
            NumberAnimation {
                target: contentContainer
                property: "y"
                to: root.height
                duration: 300
                easing.type: Easing.InCubic
            }
        }

        ScriptAction {
            script: root.exitAnimationDone()
        }
    }

    // ── Content ───────────────────────────────────────────────────────
    Item {
        id: contentContainer
        x: 0
        y: root.height   // starts off-screen (bottom), animated to 0
        width:  root.width
        height: root.height

        // ── Backdrop — blur via compositor ─────────────────────────────────
        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)

            MouseArea {
                anchors.fill: parent
                onClicked: root.visibilities.appgrid = false
            }
        }

        Content {
            anchors.fill: parent
            visibilities: root.visibilities
            screen: root.screen
        }
    }
}
