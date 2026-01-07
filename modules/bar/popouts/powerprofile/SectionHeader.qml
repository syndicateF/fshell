pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string text: ""

    Layout.fillWidth: true
    implicitHeight: label.implicitHeight + Appearance.spacing.small

    StyledText {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.small
        text: root.text
        font.pointSize: Appearance.font.size.smaller
        font.weight: Font.Medium
        color: Colours.palette.m3outline
        opacity: 0.8
    }
}
