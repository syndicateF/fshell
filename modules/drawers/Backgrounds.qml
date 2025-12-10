import qs.services
import qs.config
import qs.modules.osd as Osd
import qs.modules.notifications as Notifications
import qs.modules.session as Session
import qs.modules.launcher as Launcher
import qs.modules.overview as Overview
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities as Utilities
import qs.modules.sidebar as Sidebar
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property Panels panels
    required property Item bar

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.leftMargin: bar.implicitWidth
    preferredRendererType: Shape.CurveRenderer

    Osd.Background {
        wrapper: root.panels.osd

        startX: root.width - root.panels.session.width - root.panels.sidebar.width + Config.border.thickness
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Notifications.Background {
        wrapper: root.panels.notifications
        sidebar: sidebar

        startX: root.width + Config.border.thickness
        startY: -Config.border.thickness
    }

    Session.Background {
        wrapper: root.panels.session

        startX: root.width - root.panels.sidebar.width + Config.border.thickness
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Launcher.Background {
        wrapper: root.panels.launcher

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height + Config.border.thickness
    }

    Overview.Background {
        wrapper: root.panels.overview

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: -Config.border.thickness
    }

    BarPopouts.Background {
        wrapper: root.panels.popouts
        // Cek apakah popout menyentuh/dekat bottom bar (dengan floating margin)
        invertBottomRounding: wrapper.y + wrapper.height + rounding >= root.height - Config.border.thickness

        // startX & startY: adjust berdasarkan cutout mode atau detached mode
        // Cutout: arc top-left turun (+rounding), jadi startY = wrapper.y - rounding
        // Detached: arc top-left naik (-rounding), jadi startY = wrapper.y + rounding
        startX: wrapper.isDetached ? wrapper.x : wrapper.x + Config.border.thickness // - 0.4  // -1 fix subpixel gap
        startY: wrapper.isDetached ? wrapper.y + rounding : wrapper.y - rounding
    }

    Utilities.Background {
        wrapper: root.panels.utilities
        sidebar: sidebar

        startX: root.width + Config.border.thickness
        startY: root.height + Config.border.thickness
    }

    Sidebar.Background {
        id: sidebar

        wrapper: root.panels.sidebar
        panels: root.panels

        startX: root.width + Config.border.thickness
        startY: root.panels.notifications.height - Config.border.thickness
    }
}
