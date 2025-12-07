import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper
    required property var panels

    readonly property real rounding: Config.border.rounding
    
    // Flatten logic seperti Dashboard - ketika sidebar width mengecil, rounding juga mengecil
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding

    readonly property real notifsWidthDiff: panels.notifications.width - wrapper.width
    // Gunakan roundingX yang sudah di-flatten, bukan rounding langsung
    readonly property real notifsRoundingX: panels.notifications.height > 0 && notifsWidthDiff < roundingX * 2 ? notifsWidthDiff / 2 : roundingX

    readonly property real utilsWidthDiff: panels.utilities.width - wrapper.width
    readonly property real utilsRoundingX: utilsWidthDiff < roundingX * 2 ? utilsWidthDiff / 2 : roundingX

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    PathLine {
        relativeX: -root.wrapper.width - root.notifsRoundingX
        relativeY: 0
    }
    PathArc {
        relativeX: root.notifsRoundingX
        relativeY: root.rounding
        radiusX: root.notifsRoundingX
        radiusY: root.rounding
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.rounding * 2
    }
    PathArc {
        relativeX: -root.utilsRoundingX
        relativeY: root.rounding
        radiusX: root.utilsRoundingX
        radiusY: root.rounding
    }
    PathLine {
        relativeX: root.wrapper.width + root.utilsRoundingX
        relativeY: 0
    }

    Behavior on fillColor {
        CAnim {}
    }
}
