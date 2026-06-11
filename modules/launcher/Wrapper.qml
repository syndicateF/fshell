pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import QtQuick

/**
 * Launcher Wrapper — compact search overlay only.
 * App grid is now a separate module (appgrid).
 */
Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    signal exitAnimationDone()

    anchors.fill: parent
    visible: opacity > 0
    opacity: 0
    scale: 0.95

    function closeWithAnimation(): void {
        showAnim.stop();
        hideAnim.start();
    }

    Component.onCompleted: {
        hideAnim.stop();
        showAnim.start();
    }

    SequentialAnimation {
        id: showAnim

        ParallelAnimation {
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
    }

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

    // ── Backdrop ──────────────────────────────────────────────────────
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.visibilities.launcher = false
        }
    }

    // ── Content ───────────────────────────────────────────────────────
    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.2

        active: root.visible

        sourceComponent: Content {
            visibilities: root.visibilities
            screen: root.screen
        }
    }
}
