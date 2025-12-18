import qs.config
import qs.modules.osd as Osd
import qs.modules.notifications as Notifications
import qs.modules.launcher as Launcher
import qs.modules.overview as Overview
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities as Utilities
import qs.modules.utilities.toasts as Toasts
import qs.modules.sidebar as Sidebar
import qs.modules.topworkspaces as TopWorkspaces
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property Item bar

    readonly property alias osd: osd
    readonly property alias notifications: notifications
    readonly property alias launcher: launcher
    readonly property alias overview: overview
    readonly property alias popouts: popouts
    readonly property alias utilities: utilities
    readonly property alias toasts: toasts
    readonly property alias sidebar: sidebar
    readonly property alias topworkspaces: topworkspaces

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.leftMargin: bar.implicitWidth

    Osd.Wrapper {
        id: osd

        clip: sidebar.width > 0
        screen: root.screen
        visibilities: root.visibilities

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sidebar.width - Config.border.thickness
    }

    Notifications.Wrapper {
        id: notifications

        visibilities: root.visibilities
        panels: root

        anchors.top: parent.top
        anchors.topMargin: -Config.border.thickness
        anchors.right: parent.right
        anchors.rightMargin: -Config.border.thickness
    }

    // Session is now handled as fullscreen overlay in Drawers.qml

    Launcher.Wrapper {
        id: launcher

        screen: root.screen
        visibilities: root.visibilities
        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -Config.border.thickness
    }

    Overview.Wrapper {
        id: overview

        screen: root.screen
        visibilities: root.visibilities
        popouts: popouts

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: -Config.border.thickness
    }

    TopWorkspaces.Wrapper {
        id: topworkspaces

        // Clip saat overview aktif (seperti OSD clip saat session aktif)
        clip: overview.height > 0

        screen: root.screen
        visibilities: root.visibilities

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // Nempel di bawah overview saat overview aktif - overlap 1px untuk fix anti-aliasing gap
        anchors.topMargin: overview.height > 0 ? overview.height - Config.border.thickness - 0.4 : -Config.border.thickness
    }

    BarPopouts.Wrapper {
        id: popouts

        screen: root.screen

        x: isDetached ? (root.width - nonAnimWidth) / 2 : 0
        y: {
            if (isDetached)
                return (root.height - nonAnimHeight) / 2;

            const off = currentCenter - Config.border.thickness - nonAnimHeight / 2;
            // Limit bottom position - leave space for cutout radius (rounding + spacing)
            const maxTop = Config.border.rounding + Config.border.thickness;
            const bottomLimit = root.height - Config.border.rounding - Config.border.thickness;
            const maxBot = bottomLimit - nonAnimHeight;
            return Math.max(Math.min(off, maxBot), maxTop);
        }
    }

    Utilities.Wrapper {
        id: utilities

        visibilities: root.visibilities
        sidebar: sidebar

        anchors.bottom: parent.bottom
        anchors.bottomMargin: -Config.border.thickness
        anchors.right: parent.right
        anchors.rightMargin: -Config.border.thickness
    }

    Toasts.Toasts {
        id: toasts

        anchors.bottom: sidebar.visible ? parent.bottom : utilities.top
        anchors.right: sidebar.left
        anchors.margins: Appearance.padding.normal
    }

    Sidebar.Wrapper {
        id: sidebar

        visibilities: root.visibilities
        panels: root

        anchors.top: notifications.bottom
        anchors.bottom: utilities.top
        anchors.right: parent.right
        anchors.rightMargin: -Config.border.thickness
    }
}
