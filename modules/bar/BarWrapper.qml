pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import "popouts" as BarPopouts
import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    // readonly property int padding: Config.border.thickness
    readonly property int floatingSpacing: Config.border.thickness
    readonly property int contentWidth: Config.bar.sizes.innerWidth + floatingSpacing + 8
    readonly property int exclusiveZone: Config.bar.persistent || visibilities.bar ? contentWidth : Config.border.thickness
    readonly property bool shouldBeVisible: Config.bar.persistent || visibilities.bar || isHovered
    property bool isHovered

    function closeTray(): void {
        content.item?.closeTray();
    }

    function checkPopout(y: real): void {
        content.item?.checkPopout(y);
    }

    function handleWheel(y: real, angleDelta: point): void {
        content.item?.handleWheel(y, angleDelta);
    }

    visible: width > Config.border.thickness
    implicitWidth: Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.contentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 0

        active: root.shouldBeVisible || root.visible

        sourceComponent: Bar {
            width: root.contentWidth - root.floatingSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }
}
