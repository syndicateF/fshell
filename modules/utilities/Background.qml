import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper
    required property var sidebar
    readonly property real rounding: Config.border.rounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding
    
    // Cek apakah sidebar visible - jika tidak, top-left harus rounded biasa
    readonly property bool sidebarVisible: sidebar.wrapper.width > 0
    // Top-left rounding: pakai utilsRoundingX dari sidebar jika visible, atau rounding biasa
    readonly property real topLeftRounding: sidebarVisible ? sidebar.utilsRoundingX : rounding

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    PathLine {
        relativeX: -(root.wrapper.width + root.rounding)
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
        direction: PathArc.Counterclockwise
    }
    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY * 2)
    }
    // Top-left arc:
    // - Sidebar visible: arc connect ke sidebar (Clockwise, ke kanan dengan utilsRoundingX)
    // - Standalone: arc keluar seperti Dashboard bottom-left tapi mirrored (ke atas)
    PathArc {
        relativeX: root.sidebarVisible ? root.topLeftRounding : root.rounding
        relativeY: -root.roundingY
        radiusX: root.sidebarVisible ? root.topLeftRounding : root.rounding
        radiusY: root.roundingY
        // Sidebar: Clockwise untuk connect
        // Standalone: TANPA direction (default Clockwise) - seperti Dashboard bottom-left yang Counterclockwise tapi mirrored
    }
    PathLine {
        relativeX: root.wrapper.height > 0 ? root.wrapper.width - root.rounding - (root.sidebarVisible ? root.topLeftRounding : root.rounding) : root.wrapper.width
        relativeY: 0
    }
    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
        direction: PathArc.Counterclockwise
    }

    Behavior on fillColor {
        CAnim {}
    }
}
