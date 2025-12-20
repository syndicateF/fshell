pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

/**
 * WaveformSlider - SoundCloud-style waveform progress slider with CAVA visualization
 * 
 * Usage:
 *   WaveformSlider {
 *       progress: Players.progress  // 0-1
 *       accentColor: MediaPalette.accent
 *       onSeek: position => Players.active.position = position * Players.active.length
 *   }
 */
Item {
    id: root
    
    // ========== Properties ==========
    property real progress: 0           // 0-1 range
    property color accentColor: Colours.palette.m3primary
    property color inactiveColor: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.3)
    property color timeColor: Colours.palette.m3onSurfaceVariant
    property int barCount: 80
    property bool showTimeLabels: true
    property string positionText: "--:--"
    property string lengthText: "--:--"
    property bool canSeek: true
    
    // ========== Signals ==========
    signal seek(real position)  // 0-1 position
    
    implicitHeight: 80
    
    // ========== Computed ==========
    readonly property real barWidth: (width - (barCount - 1) * 1.5) / barCount
    
    // Waveform bars
    Row {
        id: waveformRow
        anchors.centerIn: parent
        height: parent.height - (root.showTimeLabels ? 16 : 0)
        spacing: 1.5
        
        Repeater {
            model: root.barCount
            
            Rectangle {
                id: bar
                required property int index
                
                readonly property real cavaIndex: index % (Audio.cava.values?.length || 1)
                readonly property real cavaValue: Audio.cava.values?.[cavaIndex] ?? 0.3
                readonly property bool isPassed: (index / root.barCount) <= root.progress
                
                width: root.barWidth
                height: Math.max(4, waveformRow.height * (0.2 + cavaValue * 0.8))
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                
                color: isPassed ? root.accentColor : root.inactiveColor
                
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
        visible: root.showTimeLabels
        
        StyledText {
            text: root.positionText
            color: root.accentColor
            font.pointSize: Appearance.font.size.smaller
            font.weight: 500
        }
        
        Item { Layout.fillWidth: true }
        
        StyledText {
            text: root.lengthText
            color: root.timeColor
            font.pointSize: Appearance.font.size.smaller
        }
    }
    
    // Interaction layer
    MouseArea {
        id: waveformMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
        
        onPressed: event => {
            if (!root.canSeek) return;
            const pos = Math.max(0, Math.min(1, event.x / width));
            root.seek(pos);
        }
        
        onPositionChanged: event => {
            if (!pressed || !root.canSeek) return;
            const pos = Math.max(0, Math.min(1, event.x / width));
            root.seek(pos);
        }
    }
    
    // Hover indicator
    Rectangle {
        visible: waveformMouseArea.containsMouse && !waveformMouseArea.pressed && root.canSeek
        x: Math.max(0, Math.min(waveformMouseArea.mouseX - 1, parent.width - 2))
        anchors.top: waveformRow.top
        anchors.bottom: waveformRow.bottom
        width: 2
        radius: 1
        color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
    }
}
