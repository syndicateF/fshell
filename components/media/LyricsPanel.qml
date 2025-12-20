pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

/**
 * LyricsPanel - Scrollable synced lyrics display with states
 * 
 * Usage:
 *   LyricsPanel {
 *       accentColor: MediaPalette.accent
 *       onClose: lyricsMode = false
 *   }
 */
Item {
    id: root
    
    // ========== Properties ==========
    property color accentColor: Colours.palette.m3primary
    property color textColor: Colours.palette.m3onSurfaceVariant
    
    // ========== Signals ==========
    signal close()
    
    // ========== Skeleton Loader Component ==========
    component SkeletonLine: Rectangle {
        id: skeleton
        property real targetWidth: 0.8
        
        height: 16
        width: parent.width * targetWidth
        radius: height / 2
        color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.15)
        
        // Shimmer animation
        SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
        }
    }
    
    // ========== Main Content ==========
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: Appearance.spacing.normal
        
        // Header with close button
        RowLayout {
            Layout.fillWidth: true
            
            StyledText {
                text: qsTr("Lyrics")
                font.pointSize: Appearance.font.size.large
                font.weight: 600
                color: root.accentColor
            }
            
            Item { Layout.fillWidth: true }
            
            // Cancel button (during loading)
            IconButton {
                visible: Lyrics.loading
                type: IconButton.Text
                icon: "close"
                font.pointSize: Appearance.font.size.small
                onClicked: {
                    Lyrics.cancel();
                    root.close();
                }
            }
            
            // Close button (when not loading)
            IconButton {
                visible: !Lyrics.loading
                type: IconButton.Text
                icon: "close"
                font.pointSize: Appearance.font.size.small
                onClicked: root.close()
            }
        }
        
        // Content area
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // State: Loading (Skeleton)
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: Appearance.spacing.large
                visible: Lyrics.loading
                spacing: 24
                
                // Skeleton lines with shimmer effect
                Repeater {
                    model: 7
                    
                    Rectangle {
                        required property int index
                        
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: contentArea.width * (index === 3 ? 0.85 : (index % 2 === 0 ? 0.65 : 0.45))
                        Layout.preferredHeight: 14
                        
                        radius: height / 2
                        color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.12)
                        opacity: 1.0 - (index * 0.1)
                        
                        // Shimmer animation
                        SequentialAnimation on opacity {
                            running: Lyrics.loading
                            loops: Animation.Infinite
                            NumberAnimation { 
                                to: 0.3
                                duration: 700 + index * 50
                                easing.type: Easing.InOutSine 
                            }
                            NumberAnimation { 
                                to: 1.0 - (index * 0.1)
                                duration: 700 + index * 50
                                easing.type: Easing.InOutSine 
                            }
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
            
            // State: Success (Lyrics)
            ListView {
                id: lyricsView
                anchors.fill: parent
                visible: Lyrics.available
                clip: true
                spacing: 0  // Spacing handled by delegate padding
                
                model: Lyrics.lines
                
                // Auto-scroll to current line
                onContentHeightChanged: scrollToCurrentLine()
                
                Connections {
                    target: Lyrics
                    function onCurrentLineIndexChanged() {
                        lyricsView.scrollToCurrentLine();
                    }
                }
                
                function scrollToCurrentLine() {
                    if (Lyrics.currentLineIndex >= 0) {
                        positionViewAtIndex(Lyrics.currentLineIndex, ListView.Center);
                    }
                }
                
                delegate: Item {
                    id: lineDelegate
                    required property int index
                    required property var modelData
                    
                    width: lyricsView.width
                    
                    // Dynamic height: current line gets more vertical padding
                    readonly property bool isCurrent: index === Lyrics.currentLineIndex
                    readonly property bool isAdjacent: Math.abs(index - Lyrics.currentLineIndex) === 1
                    readonly property int distance: Math.abs(index - Lyrics.currentLineIndex)
                    
                    // Dynamic spacing: tighter overall, current gets slightly more room
                    readonly property real verticalPadding: isCurrent ? 12 : (isAdjacent ? 6 : 4)
                    height: lyricText.implicitHeight + verticalPadding
                    
                    Behavior on height { 
                        NumberAnimation { 
                            duration: 450
                            easing.type: Easing.OutQuart 
                        } 
                    }
                    
                    StyledText {
                        id: lyricText
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.text
                        wrapMode: Text.WordWrap
                        
                        // UNIFORM font size to prevent wrap changes
                        font.pointSize: Appearance.font.size.normal
                        
                        // Dynamic styling (no size change = consistent wrapping)
                        color: lineDelegate.isCurrent ? root.accentColor : root.textColor
                        font.weight: lineDelegate.isCurrent ? 700 : 400
                        
                        // Smooth opacity fade based on distance
                        opacity: lineDelegate.isCurrent ? 1.0 : 
                                 lineDelegate.isAdjacent ? 0.6 : 
                                 Math.max(0.25, 0.5 - lineDelegate.distance * 0.08)
                        
                        // Scale for emphasis (current slightly larger visually)
                        scale: lineDelegate.isCurrent ? 1.0 : 1.0
                        transformOrigin: Item.Center
                        
                        // Smooth animations
                        Behavior on color { 
                            ColorAnimation { 
                                duration: 400
                                easing.type: Easing.OutQuart 
                            } 
                        }
                        Behavior on opacity { 
                            NumberAnimation { 
                                duration: 350
                                easing.type: Easing.OutQuart 
                            } 
                        }
                        Behavior on scale { 
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutBack
                            } 
                        }
                        Behavior on font.pointSize { 
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutQuart 
                            } 
                        }
                    }
                }
            }
            
            // State: Error
            ColumnLayout {
                anchors.centerIn: parent
                visible: Lyrics.status === Lyrics.Status.Error
                spacing: Appearance.spacing.normal
                
                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "wifi_off"
                    font.pointSize: 40
                    color: Colours.palette.m3error
                    opacity: 0.8
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Lyrics.errorMessage || qsTr("Connection failed")
                    color: Colours.palette.m3error
                    font.pointSize: Appearance.font.size.normal
                }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Appearance.spacing.small
                    
                    IconButton {
                        type: IconButton.Tonal
                        icon: "refresh"
                        onClicked: Lyrics.retry()
                    }
                    
                    IconButton {
                        type: IconButton.Text
                        icon: "close"
                        onClicked: root.close()
                    }
                }
            }
            
            // State: No Lyrics
            ColumnLayout {
                anchors.centerIn: parent
                visible: Lyrics.status === Lyrics.Status.NoLyrics
                spacing: Appearance.spacing.normal
                
                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "lyrics"
                    font.pointSize: 40
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.5
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No synced lyrics available")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Players.active?.trackTitle ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                    opacity: 0.6
                }
                
                IconButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Appearance.spacing.small
                    type: IconButton.Text
                    icon: "arrow_back"
                    onClicked: root.close()
                }
            }
            
            // State: Idle (no track)
            ColumnLayout {
                anchors.centerIn: parent
                visible: Lyrics.status === Lyrics.Status.Idle && !Lyrics.loading
                spacing: Appearance.spacing.normal
                
                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "music_note"
                    font.pointSize: 40
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.4
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Play a track to see lyrics")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal
                }
            }
        }
    }
}
