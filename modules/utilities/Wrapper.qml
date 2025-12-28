pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property var visibilities
    required property Item sidebar

    readonly property PersistentProperties props: PersistentProperties {
        property bool recordingListExpanded: false
        property string recordingConfirmDelete
        property string recordingMode

        reloadableId: "utilities"
    }
    readonly property bool shouldBeActive: visibilities.sidebar || (visibilities.utilities && Config.utilities.enabled && !(visibilities.fullscreenSession))
    
    // contentReady flag - delays animation until content is fully loaded
    property bool contentReady: false

    visible: height > 0
    implicitHeight: 0
    implicitWidth: sidebar.visible ? sidebar.width : Config.utilities.sizes.width

    onStateChanged: {
        if (state === "visible" && timer.running) {
            timer.triggered();
            timer.stop();
        }
    }
    
    // When should become active, wait for content to be ready before animating
    onShouldBeActiveChanged: {
        if (shouldBeActive && !contentReady) {
            // Delay state change until content ready
            contentReadyTimer.start();
        }
    }

    states: State {
        name: "visible"
        // Only enter visible state when content is ready
        when: root.shouldBeActive && root.contentReady

        PropertyChanges {
            // Use LIVE binding to content.implicitHeight - follows instantly
            // Record.qml handles its own internal animation, Wrapper just follows
            root.implicitHeight: content.implicitHeight + Appearance.padding.large * 2 + Config.border.thickness
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
            
            // Reset contentReady when closing
            ScriptAction {
                script: root.contentReady = false
            }
        }
    ]
    
    // Timer to wait for content to settle before starting open animation
    Timer {
        id: contentReadyTimer
        interval: 50  // Small delay to let content.implicitHeight stabilize
        repeat: false
        onTriggered: {
            if (content.item) {
                root.contentReady = true;
            }
        }
    }

    Timer {
        id: timer

        running: true
        interval: Appearance.anim.durations.extraLarge
        onTriggered: {
            content.active = Qt.binding(() => root.shouldBeActive || root.visible);
            content.visible = true;
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Appearance.padding.large
        anchors.bottomMargin: Appearance.padding.large + Config.border.thickness
        anchors.rightMargin: Appearance.padding.large + Config.border.thickness

        visible: false
        active: true

        sourceComponent: Content {
            implicitWidth: root.implicitWidth - Appearance.padding.large * 2
            props: root.props
            visibilities: root.visibilities
        }
    }
}
