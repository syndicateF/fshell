pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
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
    
    // ========== Vibrant Color Extraction with Saturation Boost ==========
    // Raw color from ImageAnalyser
    readonly property color rawDominant: albumAnalyser.dominantColour.a > 0 ? albumAnalyser.dominantColour : Colours.palette.m3primary
    
    // Vibrant color boost - if dominant color has low saturation (likely background),
    // boost it to create a more appealing accent. This fixes the "picks wrong color" issue.
    readonly property color sourceColor: {
        const raw = rawDominant;
        let h = raw.hslHue;
        let s = raw.hslSaturation;
        let l = raw.hslLightness;
        
        // If saturation is too low (gray/white/black background detected)
        // Boost saturation significantly for a more vibrant result
        if (s < 0.25) {
            s = 0.35 + s;  // Minimum saturation floor
        } else if (s < 0.4) {
            s = s * 1.5;   // Moderate boost for slightly desaturated
        }
        
        // If lightness is extreme (very dark or very bright background)
        // Adjust to mid-range for better accent color
        if (l < 0.15) {
            l = 0.35;  // Boost very dark colors
        } else if (l > 0.85) {
            l = 0.55;  // Tone down very bright colors
        }
        
        // Cap saturation at 1.0
        s = Math.min(1.0, s);
        
        return Qt.hsla(h, s, l, 1.0);
    }
    
    // Material You tone generator (generates palette from source color)
    function toneColor(baseColor: color, targetLightness: real): color {
        return Qt.hsla(baseColor.hslHue, baseColor.hslSaturation, targetLightness, 1.0);
    }
    
    function adjustSaturation(baseColor: color, factor: real): color {
        const newS = Math.min(1.0, Math.max(0, baseColor.hslSaturation * factor));
        return Qt.hsla(baseColor.hslHue, newS, baseColor.hslLightness, 1.0);
    }
    
    // Check if dark mode (based on system)
    readonly property bool isDark: !Colours.light
    
    // ========== Generated Album Palette ==========
    // Primary - main accent (tone 70 dark, 40 light)
    readonly property color albumPrimary: toneColor(sourceColor, isDark ? 0.70 : 0.40)
    // OnPrimary - text/icon on primary (high contrast)
    readonly property color albumOnPrimary: isDark ? "#1a1a1a" : "#ffffff"
    // PrimaryContainer - lighter container
    readonly property color albumPrimaryContainer: toneColor(sourceColor, isDark ? 0.25 : 0.85)
    // OnPrimaryContainer - text on container
    readonly property color albumOnPrimaryContainer: toneColor(sourceColor, isDark ? 0.85 : 0.15)
    
    // Secondary - desaturated variant
    readonly property color albumSecondary: adjustSaturation(toneColor(sourceColor, isDark ? 0.70 : 0.40), 0.6)
    readonly property color albumOnSecondary: isDark ? "#1a1a1a" : "#ffffff"
    
    // Surface colors - use source color tint for harmony
    readonly property color albumSurface: isDark ? "#121212" : "#fafafa"
    readonly property color albumOnSurface: isDark ? toneColor(sourceColor, 0.85) : toneColor(sourceColor, 0.15)
    readonly property color albumOnSurfaceVariant: isDark ? toneColor(sourceColor, 0.65) : toneColor(sourceColor, 0.35)
    
    // Main accent color (final softened version)
    readonly property color accentColor: {
        const newL = isDark 
            ? Math.min(0.65, sourceColor.hslLightness + 0.20)
            : Math.max(0.35, sourceColor.hslLightness - 0.10);
        return Qt.hsla(sourceColor.hslHue, sourceColor.hslSaturation, newL, 1.0);
    }

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }
    
    // Toggle between normal mode and lyrics mode
    property bool lyricsMode: false
    
    // Vertical spacing between content items
    property real contentSpacing: 0
    property real contentPadding: Appearance.spacing.normal * 2

    
    function lengthStr(length: int): string {
        if (length < 0) return "--:--";
        const mins = Math.floor(length / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");
        return `${mins}:${secs}`;
    }
    // Note: Color palette is now generated natively from ImageAnalyser
    // No external process needed - colors update automatically when dominant color changes

    implicitWidth: container.implicitWidth - Config.border.thickness
    implicitHeight: container.implicitHeight

    Behavior on playerProgress {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }

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
    
    // Update Lyrics service with current track and position
    Connections {
        target: Players.active
        
        function onTrackTitleChanged() {
            Lyrics.currentArtist = Players.active?.trackArtist ?? "";
            Lyrics.currentTitle = Players.active?.trackTitle ?? "";
        }
        
        function onTrackArtistChanged() {
            Lyrics.currentArtist = Players.active?.trackArtist ?? "";
            Lyrics.currentTitle = Players.active?.trackTitle ?? "";
        }
    }
    
    // Initial lyrics load when component loads or player changes
    Component.onCompleted: {
        if (Players.active) {
            Lyrics.currentArtist = Players.active.trackArtist ?? "";
            Lyrics.currentTitle = Players.active.trackTitle ?? "";
        }
    }
    
    // Keep position synced when in lyrics mode
    Timer {
        running: root.lyricsMode && Players.active?.isPlaying
        interval: 100
        repeat: true
        onTriggered: {
            Lyrics.currentPosition = Players.active?.position ?? 0;
        }
    }

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
            Item {
                id: waveformSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                Layout.leftMargin: root.contentPadding
                Layout.rightMargin: root.contentPadding

                
                readonly property int barCount: 80
                readonly property real barWidth: (width - (barCount - 1) * 1.5) / barCount
                readonly property real progressPosition: root.playerProgress
                
                // Waveform bars
                Row {
                    id: waveformRow
                    anchors.centerIn: parent
                    height: parent.height - 16
                    spacing: 1.5
                    
                    Repeater {
                        model: waveformSlider.barCount
                        
                        Rectangle {
                            id: bar
                            required property int index
                            
                            readonly property real cavaIndex: index % (Audio.cava.values?.length || 1)
                            readonly property real cavaValue: Audio.cava.values?.[cavaIndex] ?? 0.3
                            readonly property bool isPassed: (index / waveformSlider.barCount) <= waveformSlider.progressPosition
                            
                            width: waveformSlider.barWidth
                            height: Math.max(4, waveformRow.height * (0.2 + cavaValue * 0.8))
                            anchors.verticalCenter: parent.verticalCenter
                            radius: width / 2
                            
                            color: isPassed ? root.accentColor : Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.3)
                            
                            Behavior on height { NumberAnimation { duration: 50 } }
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                }
                
                // Time labels
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    
                    StyledText {
                        text: root.lengthStr(Players.active?.position ?? -1)
                        color: root.accentColor
                        font.pointSize: Appearance.font.size.smaller
                        font.weight: 500
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    StyledText {
                        text: root.lengthStr(Players.active?.length ?? -1)
                        color: root.albumOnSurfaceVariant
                        font.pointSize: Appearance.font.size.smaller
                    }
                }
                
                // Interaction layer
                MouseArea {
                    id: waveformMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onPressed: event => {
                        const active = Players.active;
                        if (!active?.canSeek) return;
                        const progress = Math.max(0, Math.min(1, event.x / width));
                        active.position = progress * active.length;
                    }
                    
                    onPositionChanged: event => {
                        if (!pressed) return;
                        const active = Players.active;
                        if (!active?.canSeek) return;
                        const progress = Math.max(0, Math.min(1, event.x / width));
                        active.position = progress * active.length;
                    }
                }
                
                // Hover indicator
                Rectangle {
                    visible: waveformMouseArea.containsMouse && !waveformMouseArea.pressed
                    x: Math.max(0, Math.min(waveformMouseArea.mouseX - 1, parent.width - 2))
                    anchors.top: waveformRow.top
                    anchors.bottom: waveformRow.bottom
                    width: 2
                    radius: 1
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
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

            // Per-app Volume Slider (thumbless pill style)
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
                readonly property real appVolume: appStream?.audio?.volume ?? 0
                readonly property bool hasStream: appStream !== null
                
                visible: hasStream
                opacity: hasStream ? 1 : 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }
                
                // Volume low icon (left)
                MaterialIcon {
                    id: volLowIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "volume_down"
                    font.pointSize: Appearance.font.size.normal
                    color: root.albumOnSurfaceVariant
                    opacity: 0.6
                }
                
                // Thumbless slider (pill style)
                Item {
                    id: volumeSlider
                    anchors.left: volLowIcon.right
                    anchors.leftMargin: Appearance.spacing.small
                    anchors.right: volHighIcon.left
                    anchors.rightMargin: Appearance.spacing.small
                    anchors.verticalCenter: parent.verticalCenter
                    height: 8
                    
                    // Background track
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.2)
                    }
                    
                    // Fill (animated)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.min(1, Math.max(0, parent.parent.appVolume))
                        radius: height / 2
                        color: root.accentColor
                        
                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                    }
                    
                    // Drag area
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8  // Larger hit area
                        
                        onPressed: event => updateVolume(event)
                        onPositionChanged: event => { if (pressed) updateVolume(event); }
                        
                        function updateVolume(event) {
                            const stream = parent.parent.appStream;
                            if (stream?.audio) {
                                const ratio = Math.max(0, Math.min(1, (event.x + 8) / volumeSlider.width));
                                stream.audio.volume = ratio;
                            }
                        }
                        
                        cursorShape: Qt.PointingHandCursor
                    }
                }
                
                // Volume high icon (right)
                MaterialIcon {
                    id: volHighIcon
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "volume_up"
                    font.pointSize: Appearance.font.size.normal
                    color: root.albumOnSurfaceVariant
                    opacity: 0.6
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
        Item {
            id: lyricsContent
            Layout.preferredWidth: slideContainer.width
            Layout.preferredHeight: slideContainer.height
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                // spacing: Appearance.spacing.small
                
                // Header with close button
                    
                    IconButton {
                        type: IconButton.Text
                        icon: "close"
                        onClicked: root.lyricsMode = false
                    }
                
                
                // Scrollable lyrics list with smooth animations
                ListView {
                    id: lyricsListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    visible: !Lyrics.loading && Lyrics.available
                    model: Lyrics.lines
                    currentIndex: Lyrics.currentLineIndex
                    spacing: 12  // Add spacing between lyrics
                    
                    // Ultra-smooth scroll animation
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 500
                    highlightMoveVelocity: -1
                    
                    // Keep current line centered
                    preferredHighlightBegin: height / 2 - 40
                    preferredHighlightEnd: height / 2 + 40
                    highlightRangeMode: ListView.ApplyRange
                    
                    // Performance optimization
                    cacheBuffer: 300
                    displayMarginBeginning: 50
                    displayMarginEnd: 50
                    
                    delegate: Item {
                        required property var modelData
                        required property int index
                        
                        width: lyricsListView.width
                        height: lyricText.implicitHeight + 16
                        
                        // Calculate distance from current line for effects
                        readonly property int distanceFromCurrent: Math.abs(index - Lyrics.currentLineIndex)
                        readonly property bool isCurrent: index === Lyrics.currentLineIndex
                        
                        StyledText {
                            id: lyricText
                            anchors.centerIn: parent
                            width: parent.width - 32
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.text
                            wrapMode: Text.WordWrap
                            
                            // Dynamic styling based on position
                            color: isCurrent ? root.accentColor : root.albumOnSurfaceVariant
                            font.pointSize: isCurrent ? Appearance.font.size.normal + 3 : Appearance.font.size.normal
                            font.weight: isCurrent ? 700 : 400
                            
                            // Distance-based opacity (smooth fade)
                            opacity: isCurrent ? 1.0 : Math.max(0.25, 1.0 - distanceFromCurrent * 0.18)
                            
                            // Subtle scale effect for current line
                            scale: isCurrent ? 1.03 : 1.0
                            transformOrigin: Item.Center
                            
                            // Smooth transitions with expressive easing
                            Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                            Behavior on font.pointSize { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
                
                // State: Loading
                ColumnLayout {
                    Layout.fillHeight: true
                    visible: Lyrics.loading
                    spacing: Appearance.spacing.normal
                    
                    Item { Layout.fillHeight: true }
                    
                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        text: "hourglass_empty"
                        font.pointSize: 32
                        color: Colours.palette.m3onSurfaceVariant
                        
                        // Pulse animation
                        SequentialAnimation on opacity {
                            running: Lyrics.loading
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                        }
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        text: qsTr("Loading lyrics...")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.normal
                    }
                    
                    Item { Layout.fillHeight: true }
                }
                
                // State: Error (with refresh button)
                ColumnLayout {
                    Layout.fillHeight: true
                    visible: Lyrics.error !== "" && !Lyrics.loading
                    spacing: Appearance.spacing.normal
                    
                    Item { Layout.fillHeight: true }
                    
                    MaterialIcon {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        text: "wifi_off"
                        font.pointSize: 32
                        color: Colours.palette.m3error
                    }
                    
                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        text: Lyrics.error
                        color: Colours.palette.m3error
                        font.pointSize: Appearance.font.size.normal
                    }
                    
                    IconButton {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        type: IconButton.Tonal
                        icon: "refresh"
                        onClicked: Lyrics.retry()
                    }
                    
                    Item { Layout.fillHeight: true }
                }
                
                // State: No lyrics available
                ColumnLayout {
                    Layout.fillHeight: true
                    visible: !Lyrics.available && !Lyrics.loading && Lyrics.error === ""
                    spacing: Appearance.spacing.normal
                    
                    Item { Layout.fillHeight: true }
                    
                    MaterialIcon {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        text: "music_off"
                        font.pointSize: 32
                        color: Colours.palette.m3onSurfaceVariant
                        opacity: 0.6
                    }
                    
                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No lyrics available")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.normal
                    }
                    
                    Item { Layout.fillHeight: true }
                }
            }
        }
        } // Close slideRow
        } // Close slideContainer
    } // Close container
} // Close root
