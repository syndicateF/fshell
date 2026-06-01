pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    signal exitAnimationDone()

    anchors.fill: parent
    visible: opacity > 0
    opacity: 0
    scale: 0.95

    // Called by Drawers.qml container to trigger close animation
    function closeWithAnimation(): void {
        showAnim.stop();
        hideAnim.start();
    }

    // Auto-show when component is loaded
    Component.onCompleted: {
        hideAnim.stop();
        showAnim.start();
    }

    // ═══════════════════════════════════════════════════════════════
    // SHOW ANIMATION: Fade in + scale up
    // ═══════════════════════════════════════════════════════════════
    ParallelAnimation {
        id: showAnim

        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }

        NumberAnimation {
            target: root
            property: "scale"
            to: 1
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // HIDE ANIMATION: Fade out + scale down
    // ═══════════════════════════════════════════════════════════════
    SequentialAnimation {
        id: hideAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }

            NumberAnimation {
                target: root
                property: "scale"
                to: 0.95
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }

        ScriptAction {
            script: root.exitAnimationDone()
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SEMI-TRANSPARENT BACKDROP
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: root.visibilities.wallpicker = false
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MAIN CONTENT
    // ═══════════════════════════════════════════════════════════════
    Loader {
        anchors.fill: parent
        active: root.visible

        sourceComponent: WallpaperPicker {
            visibilities: root.visibilities
            screen: root.screen
        }
    }
}
