import Quickshell
import QtQuick
import QtQuick.Effects

MultiEffect {
    property Item mask

    maskEnabled: true
    maskSource: mask
    maskThresholdMin: 0.5
    maskSpreadAtMin: 0.0
}
