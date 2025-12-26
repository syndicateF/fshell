pragma ComponentBehavior: Bound

import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Effects

StyledRect {
    id: innerBorderRoot
    
    property alias innerRadius: maskInner.radius
    property alias thickness: maskInner.anchors.margins
    property alias leftThickness: maskInner.anchors.leftMargin
    property alias topThickness: maskInner.anchors.topMargin
    property alias rightThickness: maskInner.anchors.rightMargin
    property alias bottomThickness: maskInner.anchors.bottomMargin

    anchors.fill: parent
    color: Colours.tPalette.m3surfaceContainer

    // Check if mask has valid dimensions - this prevents ShaderEffect 'source' warning
    readonly property bool maskReady: mask.width > 0 && mask.height > 0

    layer.enabled: maskReady
    layer.effect: MultiEffect {
        maskSource: innerBorderRoot.maskReady ? mask : null
        maskEnabled: innerBorderRoot.maskReady
        maskInverted: true
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: innerBorderRoot.maskReady
        visible: false

        Rectangle {
            id: maskInner

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            radius: Appearance.rounding.small
        }
    }
}
