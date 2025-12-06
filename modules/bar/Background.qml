import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Item bar
    readonly property real rounding: Config.border.rounding
    readonly property real floatingSpacing: Config.border.thickness
    readonly property real barHeight: bar.height - Config.border.thickness * 2
    readonly property real barWidth: bar.implicitWidth

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    // Start at top-left after floating spacing and after top-left arc
    startX: floatingSpacing + rounding + 0.2
    startY: Config.border.thickness

    // Top edge
    PathLine {
        relativeX: barWidth - floatingSpacing - rounding * 2
        relativeY: 0
    }

    // Top-right rounded corner
    PathArc {
        relativeX: rounding
        relativeY: rounding
        radiusX: rounding
        radiusY: rounding
        direction: PathArc.Clockwise
    }

    // Right edge
    PathLine {
        relativeX: 0
        relativeY: barHeight - rounding * 2
    }

    // Bottom-right rounded corner
    PathArc {
        relativeX: -rounding
        relativeY: rounding
        radiusX: rounding
        radiusY: rounding
        direction: PathArc.Clockwise
    }

    // Bottom edge
    PathLine {
        relativeX: -(barWidth - floatingSpacing - rounding * 2)
        relativeY: 0
    }

    // Bottom-left rounded corner
    PathArc {
        relativeX: -rounding
        relativeY: -rounding
        radiusX: rounding
        radiusY: rounding
        direction: PathArc.Clockwise
    }

    // Left edge
    PathLine {
        relativeX: 0
        relativeY: -(barHeight - rounding * 2)
    }

    // Top-left rounded corner (close path)
    PathArc {
        relativeX: rounding
        relativeY: -rounding
        radiusX: rounding
        radiusY: rounding
        direction: PathArc.Clockwise
    }

    Behavior on fillColor {
        CAnim {}
    }
}
