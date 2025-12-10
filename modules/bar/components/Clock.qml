pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root

    property color colour: Colours.palette.m3tertiary

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: content.implicitHeight + Config.bar.sizes.itemPadding * 2
    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding

    Column {
        id: content
        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Loader {
            anchors.horizontalCenter: parent.horizontalCenter

            active: Config.bar.clock.showIcon
            visible: active
            asynchronous: true

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
                font.pointSize: Config.bar.sizes.materialIconSize
            }
        }

        StyledText {
            id: text

            anchors.horizontalCenter: parent.horizontalCenter

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format(Config.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: root.colour
        }
    }
}
