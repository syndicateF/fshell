pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

/**
 * TrackInfo - Track title and artist display
 * 
 * Usage:
 *   TrackInfo {
 *       title: Players.active?.trackTitle ?? "No media playing"
 *       artist: Players.active?.trackArtist ?? "Play some music!"
 *       artistColor: MediaPalette.onSurfaceVariant
 *   }
 */
ColumnLayout {
    id: root
    
    // ========== Properties ==========
    property string title: ""
    property string artist: ""
    property color titleColor: Colours.palette.m3onSurface
    property color artistColor: Colours.palette.m3onSurfaceVariant
    property int maxWidth: 280
    
    Layout.alignment: Qt.AlignHCenter
    Layout.maximumWidth: maxWidth
    spacing: 0
    
    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: root.title
        color: root.titleColor
        font.pointSize: Appearance.font.size.normal + 2
        font.weight: 600
        wrapMode: Text.WordWrap
        animate: true
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: root.artist
        color: root.artistColor
        font.pointSize: Appearance.font.size.normal
        wrapMode: Text.WordWrap
        animate: true
    }
}
