pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.config
import XShell
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

/**
 * AlbumArtCard - Album art display with color extraction
 * 
 * Usage:
 *   AlbumArtCard {
 *       artUrl: Players.active?.trackArtUrl ?? ""
 *       onColorExtracted: MediaPalette.dominantColor = color
 *       onClicked: lyricsMode = true
 *   }
 */
Item {
    id: root
    
    // ========== Properties ==========
    property url artUrl: ""
    property color surfaceColor: Colours.tPalette.m3surfaceContainerHigh
    property color iconColor: Colours.palette.m3onSurfaceVariant
    property real artSize: 180
    
    // ========== Signals ==========
    signal colorExtracted(color extractedColor)
    signal clicked()
    
    implicitWidth: artSize
    implicitHeight: artSize
    
    StyledClippingRect {
        id: albumCover
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: root.surfaceColor

        // Placeholder icon
        MaterialIcon {
            anchors.centerIn: parent
            visible: albumImage.status !== Image.Ready
            text: "album"
            color: root.iconColor
            font.pointSize: 48
        }

        Image {
            id: albumImage
            anchors.fill: parent
            source: root.artUrl
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            
            onStatusChanged: {
                if (status === Image.Ready)
                    albumAnalyser.requestUpdate();
            }
        }
        
        // Color analyser for dominant color
        ImageAnalyser {
            id: albumAnalyser
            sourceItem: albumImage
            
            // Emit signal when color extracted
            onDominantColourChanged: {
                if (dominantColour.a > 0) {
                    root.colorExtracted(dominantColour);
                }
            }
        }

        // Subtle shadow
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha("#000000", 0.3)
            shadowBlur: 1.0
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }
        
        // Click handler
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
        
        // Lyrics hint icon
        MaterialIcon {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Appearance.padding.small
            text: "lyrics"
            color: Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.normal
            opacity: 0.7
        }
    }
}
