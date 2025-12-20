pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
import qs.components.media
import qs.services
import qs.config
import Caelestia
import Caelestia.Services
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// Media Player - Amberol Style
// Minimalist design with adaptive blurred album background
Item {
    id: root

    property PersistentProperties visibilities: null
    
    // ========== Colors from MediaPalette Service ==========
    // Bind directly to service - no local logic needed
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

    // Note: playerProgress is now readonly from Players.progress
    // Behavior animation not needed - Qt handles reactive updates

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
    
    // Note: Lyrics sync is now handled automatically by Lyrics service
    // No manual syncing needed - service observes Players.active directly

    // Main container with blurred album background
    StyledClippingRect {
        id: container
        implicitWidth: 300  // Fixed width
        
        // Dynamic height: larger in lyrics mode to fit scrollable lyrics
        implicitHeight: root.lyricsMode 
            ? 520  // Fixed height for lyrics mode (scrollable)
            : mainContent.implicitHeight + Appearance.padding.normal * 2 + 40
        
        // Behavior on implicitHeight {
        //     NumberAnimation { duration: 1000; easing.type: Easing.OutQuad }
        // }
        
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        // Blurred album art background (Amberol style)
        Image {
            id: bgAlbumArt
            anchors.fill: parent
            anchors.margins: -20  // Extend beyond edges for better blur
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

        // Semi-transparent overlay for readability
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3surface, 0.5)
        }

        // Horizontal sliding content container
        Item {
            id: slideContainer
            anchors.fill: parent
            // anchors.leftMargin: root.contentPadding
            // anchors.rightMargin: root.contentPadding
            clip: true
            
            RowLayout {
                id: slideRow
                spacing: 0
                height: parent.height
                
                // Slide based on lyricsMode
                x: root.lyricsMode ? -slideContainer.width : 0
                
                Behavior on x {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }

        // Panel 0: Main content (normal mode)
        ColumnLayout {
            id: mainContent
            Layout.preferredWidth: slideContainer.width
            // Height not constrained - grows with content (wrapped text)

            spacing: root.contentSpacing
            
            // Top spacer for vertical centering
            Item { Layout.fillHeight: true }

            // Album Art - Large, centered, rounded (click to show lyrics)
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 180
                Layout.preferredHeight: 180
                visible: !root.lyricsMode

                StyledClippingRect {
                    id: albumCover
                    anchors.fill: parent
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainerHigh

                    // Placeholder icon
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: albumImage.status !== Image.Ready
                        text: "album"
                        color: root.albumOnSurfaceVariant
                        font.pointSize: 48
                    }

                    Image {
                        id: albumImage
                        anchors.fill: parent
                        source: Players.active?.trackArtUrl ?? ""
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
                        
                        // Push to MediaPalette service when color extracted
                        onDominantColourChanged: {
                            if (dominantColour.a > 0) {
                                MediaPalette.dominantColor = dominantColour;
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
                    
                    // Click to show lyrics
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.lyricsMode = true
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

            // Track info - minimal
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 280
                Layout.topMargin: Appearance.spacing.normal  // Spacing from album art
                spacing: 0
                
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Players.active?.trackTitle ?? qsTr("No media playing")
                    color: Colours.palette.m3onSurface
                    font.pointSize: Appearance.font.size.normal + 2
                    font.weight: 600
                    wrapMode: Text.WordWrap
                    animate: true
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Players.active?.trackArtist ?? qsTr("Play some music!")
                    color: root.albumOnSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                    wrapMode: Text.WordWrap
                    animate: true
                }
            }

            // SoundCloud-Style Waveform Progress Slider
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

            // Controls - centered, simple (Amberol style)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacing.large
                Layout.bottomMargin: Appearance.spacing.small  // Spacing from album art

                // Previous
                IconButton {
                    type: IconButton.Text
                    icon: "skip_previous"
                    font.pointSize: Appearance.font.size.extraLarge
                    disabled: !Players.active?.canGoPrevious
                    onClicked: Players.active?.previous()
                }

                // Play/Pause - larger, accent color
                StyledRect {
                    implicitWidth: 56
                    implicitHeight: 56
                    radius: 28
                    color: root.accentColor

                    StateLayer {
                        radius: parent.radius
                        color: root.albumOnPrimary

                        function onClicked(): void {
                            Players.active?.togglePlaying();
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: Players.active?.isPlaying ? "pause" : "play_arrow"
                        color: root.albumOnPrimary
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
                    disabled: !Players.active?.canGoNext
                    onClicked: Players.active?.next()
                }
            }

            // Per-app Volume Slider
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                Layout.leftMargin: root.contentPadding
                Layout.rightMargin: root.contentPadding
                
                // Get current app's audio stream
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

            // Bottom actions - with album color background
            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                implicitWidth: bottomRow.implicitWidth + Appearance.padding.normal * 2

                implicitHeight: bottomRow.implicitHeight + Appearance.padding.small * 2
                // radius: Appearance.rounding.full
                // color: root.rawAccent
                
                RowLayout {
                    id: bottomRow
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.normal

                    IconButton {
                        type: IconButton.Text
                        icon: "open_in_new"
                        font.pointSize: Appearance.font.size.normal
                        padding: Appearance.padding.small
                        disabled: !Players.active?.canRaise
                        onClicked: {
                            Players.active?.raise();
                            if (root.visibilities)
                                root.visibilities.overview = false;
                        }
                    }

                    SplitButton {
                        id: playerSelector
                        disabled: !Players.list.length
                        active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0]
                        menu.onItemSelected: item => Players.manualActive = item.modelData
                        menuItems: playerList.instances
                        fallbackIcon: "music_off"
                        fallbackText: qsTr("No players")
                        label.Layout.maximumWidth: 80
                        label.elide: Text.ElideRight
                        label.font.pointSize: Appearance.font.size.small
                        stateLayer.disabled: false
                        menuOnTop: true
                        colour: root.accentColor  // Use album color

                        Variants {
                            id: playerList
                            model: Players.list

                            MenuItem {
                                required property MprisPlayer modelData
                                icon: modelData === Players.active ? "check" : ""
                                text: Players.getIdentity(modelData)
                                activeIcon: "play_circle"
                            }
                        }
                    }

                    IconButton {
                        type: IconButton.Text
                        icon: "close"
                        font.pointSize: Appearance.font.size.normal
                        padding: Appearance.padding.small
                        disabled: !Players.active?.canQuit
                        onClicked: Players.active?.quit()
                    }
                }
            }
            
            // Bottom spacer for vertical centering
            Item { Layout.fillHeight: true }
        }
        
        // Panel 1: Lyrics content
        LyricsPanel {
            Layout.preferredWidth: slideContainer.width
            Layout.preferredHeight: slideContainer.height
            
            accentColor: root.accentColor
            textColor: root.albumOnSurfaceVariant
            
            onClose: root.lyricsMode = false
        }
            }
        } // Close slideContainer
    } // Close container
} // Close root
