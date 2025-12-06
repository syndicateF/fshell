import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper
    required property bool invertBottomRounding
    readonly property real rounding: wrapper.isDetached ? Appearance.rounding.normal : Config.border.rounding
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding

    // Cutout style: sisi kiri punya inverted radius (keluar, bukan ke dalam)
    property bool cutoutLeft: !wrapper.isDetached

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    // Top-Left corner - CUTOUT style (seperti dashboard)
    PathArc {
        relativeX: root.roundingX
        relativeY: root.cutoutLeft ? root.rounding : -root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: root.cutoutLeft ? PathArc.Counterclockwise : PathArc.Clockwise
    }
    PathLine {
        relativeX: root.wrapper.width - root.roundingX * 2
        relativeY: 0
    }
    // Top-Right corner - normal rounded
    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
    }
    PathLine {
        relativeX: 0
        // Height adjustment: kalau cutoutLeft, top & bottom arc turun, jadi kurangi 2*rounding
        // Kalau tidak cutoutLeft (detached), top & bottom arc naik, jadi height tetap wrapper.height - 2*rounding
        relativeY: root.cutoutLeft ? root.wrapper.height - root.rounding * 2 : root.wrapper.height - root.rounding * 2
    }
    // Bottom-Right corner - normal rounded
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Clockwise
    }
    PathLine {
        relativeX: -(root.wrapper.width - root.roundingX * 2)
        relativeY: 0
    }
    // Bottom-Left corner - CUTOUT style (selalu cutout karena popout di-limit tidak mentok bottom)
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.cutoutLeft ? root.rounding : -root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: root.cutoutLeft ? PathArc.Counterclockwise : PathArc.Clockwise
    }

    Behavior on fillColor {
        CAnim {}
    }
}
