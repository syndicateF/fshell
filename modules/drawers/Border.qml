pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property Item bar

    anchors.fill: parent
    
    // Check if mask has valid dimensions - prevents ShaderEffect 'source' warning
    readonly property bool maskReady: mask.width > 0 && mask.height > 0

    StyledRect {
        anchors.fill: parent
        color: "transparent"

        layer.enabled: root.maskReady
        layer.effect: MultiEffect {
            maskSource: root.maskReady ? mask : null
            maskEnabled: root.maskReady
            maskInverted: true
            maskThresholdMin: 0.6
            maskSpreadAtMin: 1
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: root.maskReady
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Config.border.thickness
            anchors.leftMargin: root.bar.implicitWidth
            radius: Config.border.rounding
        }
    }
}

