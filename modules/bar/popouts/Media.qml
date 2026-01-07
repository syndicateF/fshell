pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
import qs.components.media
import qs.services
import qs.config
import XShell
import XShell.Services
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "media" as Media

/**
 * Media Player Popup - Amberol Style
 * 
 * Orchestrator component that composes:
 * - AlbumArtCard (album art + color extraction)
 * - TrackInfo (title/artist)
 * - WaveformSlider (progress + CAVA visualization)
 * - PlaybackControls (prev/play/next)
 * - VolumeSlider (per-app volume)
 * - MediaBottomActions (player selector)
 * - LyricsPanel (sliding panel)
 */
Item {
    id: root

    property PersistentProperties visibilities: null
    
    // ========== Colors from MediaPalette Service ==========
    readonly property color accentColor: MediaPalette.accent
    readonly property color albumPrimary: MediaPalette.primary
    readonly property color albumOnPrimary: MediaPalette.onPrimary
    readonly property color albumOnSurfaceVariant: MediaPalette.onSurfaceVariant
    
    // ========== Progress from Players Service ==========
    readonly property real playerProgress: Players.progress
    
    // Toggle between normal mode and lyrics mode
    property bool lyricsMode: false
    
    // Vertical spacing between content items
    property real contentSpacing: 0
    property real contentPadding: Appearance.spacing.normal * 2

    implicitWidth: container.implicitWidth - Config.border.thickness
    implicitHeight: container.implicitHeight

    // Position update timer
    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.overview.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ServiceRef {
        service: Audio.cava
    }

    // Main container with blurred album background
    StyledClippingRect {
        id: container
        implicitWidth: 300
        
        implicitHeight: root.lyricsMode 
            ? 520
            : mainContent.implicitHeight + Appearance.padding.normal * 2 + 40
        
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        // Blurred album art background
        Image {
            id: bgAlbumArt
            anchors.fill: parent
            anchors.margins: -20
            source: Players.active?.trackArtUrl ?? ""
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: bgAlbumArt
            blurEnabled: true
            blurMax: 100
            blur: 1.0
            saturation: 0.3
            brightness: -0.2
            opacity: bgAlbumArt.status === Image.Ready ? 0.7 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }
        }

        // Semi-transparent overlay
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3surface, 0.5)
        }

        // Horizontal sliding content container
        Item {
            id: slideContainer
            anchors.fill: parent
            clip: true
            
            RowLayout {
                id: slideRow
                spacing: 0
                height: parent.height
                
                x: root.lyricsMode ? -slideContainer.width : 0
                
                Behavior on x {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }

                // Panel 0: Main content
                ColumnLayout {
                    id: mainContent
                    Layout.preferredWidth: slideContainer.width
                    spacing: root.contentSpacing
                    
                    Item { Layout.fillHeight: true }

                    // Album Art (extracted component)
                    Media.AlbumArtCard {
                        Layout.alignment: Qt.AlignHCenter
                        visible: !root.lyricsMode
                        
                        artUrl: Players.active?.trackArtUrl ?? ""
                        iconColor: root.albumOnSurfaceVariant
                        
                        onColorExtracted: color => MediaPalette.dominantColor = color
                        onClicked: root.lyricsMode = true
                    }

                    // Track Info (extracted component)
                    Media.TrackInfo {
                        Layout.topMargin: Appearance.spacing.normal
                        
                        title: Players.active?.trackTitle ?? qsTr("No media playing")
                        artist: Players.active?.trackArtist ?? qsTr("Play some music!")
                        artistColor: root.albumOnSurfaceVariant
                    }

                    // Waveform Progress Slider (existing component)
                    WaveformSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        Layout.leftMargin: root.contentPadding
                        Layout.rightMargin: root.contentPadding
                        
                        progress: root.playerProgress
                        accentColor: root.accentColor
                        timeColor: root.albumOnSurfaceVariant
                        positionText: Players.positionStr
                        lengthText: Players.lengthStr
                        canSeek: Players.active?.canSeek ?? false
                        
                        onSeek: position => {
                            const active = Players.active;
                            if (active?.canSeek) {
                                active.position = position * active.length;
                            }
                        }
                    }

                    // Playback Controls (extracted component)
                    Media.PlaybackControls {
                        Layout.bottomMargin: Appearance.spacing.small
                        
                        isPlaying: Players.active?.isPlaying ?? false
                        canPrevious: Players.active?.canGoPrevious ?? false
                        canNext: Players.active?.canGoNext ?? false
                        accentColor: root.accentColor
                        onAccentColor: root.albumOnPrimary
                        
                        onPrevious: Players.active?.previous()
                        onTogglePlay: Players.active?.togglePlaying()
                        onNext: Players.active?.next()
                    }

                    // Per-app Volume Slider
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        Layout.leftMargin: root.contentPadding
                        Layout.rightMargin: root.contentPadding
                        
                        readonly property var appStream: {
                            const identity = Players.active?.identity ?? "";
                            return Audio.getStreamByName(identity);
                        }
                        readonly property bool hasStream: appStream !== null
                        
                        visible: hasStream
                        opacity: hasStream ? 1 : 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                        
                        VolumeSlider {
                            anchors.fill: parent
                            value: parent.appStream?.audio?.volume ?? 0
                            accentColor: root.accentColor
                            iconColor: root.albumOnSurfaceVariant
                            
                            onValueChanged: {
                                const stream = parent.appStream;
                                if (stream?.audio && typeof value === 'number') {
                                    stream.audio.volume = value;
                                }
                            }
                        }
                    }

                    // Bottom Actions (extracted component)
                    Media.MediaBottomActions {
                        Layout.topMargin: Appearance.spacing.small
                        
                        player: Players.active
                        playerList: Players.list
                        accentColor: root.accentColor
                        
                        onPlayerSelected: player => Players.manualActive = player
                        onRaiseRequested: {
                            if (root.visibilities)
                                root.visibilities.overview = false;
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }
                
                // Panel 1: Lyrics content (existing component)
                LyricsPanel {
                    Layout.preferredWidth: slideContainer.width
                    Layout.preferredHeight: slideContainer.height
                    
                    accentColor: root.accentColor
                    textColor: root.albumOnSurfaceVariant
                    
                    onClose: root.lyricsMode = false
                }
            }
        }
    }
}
