pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import QtQuick
import QtQuick.Layouts

/**
 * PlaybackControls - Previous/Play-Pause/Next buttons
 * 
 * Usage:
 *   PlaybackControls {
 *       isPlaying: Players.active?.isPlaying ?? false
 *       canPrevious: Players.active?.canGoPrevious ?? false
 *       canNext: Players.active?.canGoNext ?? false
 *       accentColor: MediaPalette.accent
 *       onPrevious: Players.active?.previous()
 *       onTogglePlay: Players.active?.togglePlaying()
 *       onNext: Players.active?.next()
 *   }
 */
RowLayout {
    id: root
    
    // ========== Properties ==========
    property bool isPlaying: false
    property bool canPrevious: false
    property bool canNext: false
    property color accentColor: Colours.palette.m3primary
    property color onAccentColor: Colours.palette.m3onPrimary
    
    // ========== Signals ==========
    signal previous()
    signal togglePlay()
    signal next()
    
    Layout.alignment: Qt.AlignHCenter
    spacing: Appearance.spacing.large

    // Previous
    IconButton {
        type: IconButton.Text
        icon: "skip_previous"
        font.pointSize: Appearance.font.size.extraLarge
        disabled: !root.canPrevious
        onClicked: root.previous()
    }

    // Play/Pause - larger, accent color
    StyledRect {
        implicitWidth: 56
        implicitHeight: 56
        radius: 28
        color: root.accentColor

        StateLayer {
            radius: parent.radius
            color: root.onAccentColor

            function onClicked(): void {
                root.togglePlay();
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.isPlaying ? "pause" : "play_arrow"
            color: root.onAccentColor
            font.pointSize: Appearance.font.size.extraLarge * 1.2
            fill: 1
            animate: true
        }
    }

    // Next
    IconButton {
        type: IconButton.Text
        icon: "skip_next"
        font.pointSize: Appearance.font.size.extraLarge
        disabled: !root.canNext
        onClicked: root.next()
    }
}
