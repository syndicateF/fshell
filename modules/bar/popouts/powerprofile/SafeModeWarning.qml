pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * SafeModeWarning - Alert banner shown when safe mode is active
 * 
 * Usage:
 *   SafeModeWarning {
 *       active: Power.safeModeActive
 *   }
 */
StyledRect {
    id: root

    property bool active: false

    visible: opacity > 0
    Layout.fillWidth: true
    implicitHeight: safeRow.implicitHeight + Appearance.padding.small * 2
    radius: Appearance.rounding.small
    color: Colours.palette.m3errorContainer

    opacity: active ? 1 : 0
    scale: active ? 1 : 0.9

    Behavior on opacity { Anim {} }
    Behavior on scale { Anim {} }

    RowLayout {
        id: safeRow
        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        MaterialIcon {
            text: "warning"
            color: Colours.palette.m3onErrorContainer
            font.pointSize: Appearance.font.size.small
        }

        StyledText {
            text: qsTr("Safe mode active")
            color: Colours.palette.m3onErrorContainer
            font.pointSize: Appearance.font.size.small
        }
    }
}
