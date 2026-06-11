pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

// Premium Media Playback Status Widget
// Renders a circular button that pulses when media is playing
StyledRect {
    id: root

    required property Item bar
    required property var popouts

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: Config.bar.sizes.innerWidth
    radius: Config.border.rounding
    color: Colours.tPalette.m3surfaceContainer
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3outline, 0.08)
    clip: true

    MaterialIcon {
        id: icon
        anchors.centerIn: parent
        text: "music_note"
        color: Colours.palette.m3primary
        font.pointSize: Config.bar.sizes.font.materialIcon

        // Premium breathing (scale pulsing) micro-animation when music is playing
        SequentialAnimation on scale {
            running: Players.active?.isPlaying ?? false
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation {
                from: 1.0
                to: 1.15
                duration: 1200
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: 1.15
                to: 1.0
                duration: 1200
                easing.type: Easing.InOutSine
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            popouts.currentName = "media"
            popouts.currentCenter = root.mapToItem(bar, 0, root.height / 2).y
            popouts.hasCurrent = !popouts.hasCurrent
        }
    }
}
