pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property var popouts

    readonly property real nonAnimWidth: overview.implicitWidth
    readonly property real nonAnimHeight: overview.implicitHeight

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    WorkspaceOverview {
        id: overview

        anchors.fill: parent

        screen: root.screen
        visibilities: root.visibilities
        popouts: root.popouts
    }
}
