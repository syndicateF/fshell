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

    readonly property bool isFullscreen: content.item ? content.item.showAll : false

    // Transition animations are DISABLED during initial load.
    // They are enabled ONLY after the show animation completes,
    // preventing the "slide from left" bug on launcher open.
    property bool _transitionsEnabled: false

    anchors.fill: parent
    visible: opacity > 0
    opacity: 0
    scale: 0.95

    function closeWithAnimation(): void {
        root._transitionsEnabled = false;
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

        // Enable mode-switch transitions only after the launcher is fully visible
        ScriptAction {
            script: root._transitionsEnabled = true
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

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.isFullscreen ? 0.75 : 0.45)

        Behavior on color { ColorAnimation { duration: 300 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.visibilities.launcher = false
        }
    }

    Loader {
        id: content

        // Always horizontally centered — works for both modes:
        //   compact:    centered with implicitWidth (640px)
        //   fullscreen: centered with root.width (full screen → x=0)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.isFullscreen ? 0 : parent.height * 0.2

        width:  root.isFullscreen ? root.width  : implicitWidth
        height: root.isFullscreen ? root.height : implicitHeight

        active: root.visible

        sourceComponent: Content {
            visibilities: root.visibilities
            screen: root.screen
        }

        // Smooth transitions — only enabled after show animation finishes
        Behavior on anchors.topMargin {
            enabled: root._transitionsEnabled
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            enabled: root._transitionsEnabled
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            enabled: root._transitionsEnabled
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
    }
}
