pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

/**
 * VolumeSlider - Thumbless pill-style volume slider
 * 
 * Usage:
 *   VolumeSlider {
 *       value: 0.5        // 0-1
 *       accentColor: MediaPalette.accent
 *       onValueChanged: stream.audio.volume = value
 *   }
 */
Item {
    id: root
    
    // ========== Properties ==========
    property real value: 0          // 0-1 range
    property color accentColor: Colours.palette.m3primary
    property color iconColor: Colours.palette.m3onSurfaceVariant
    property bool showIcons: true
    property real sliderHeight: 8
    
    // Note: Use onValueChanged binding from the consumer
    
    implicitHeight: 24
    
    // Volume low icon (left)
    MaterialIcon {
        id: volLowIcon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showIcons
        text: root.value < 0.01 ? "volume_off" : "volume_down"
        font.pointSize: Appearance.font.size.normal
        color: root.iconColor
        opacity: 0.6
    }
    
    // Slider track
    Item {
        id: sliderTrack
        anchors.left: root.showIcons ? volLowIcon.right : parent.left
        anchors.leftMargin: root.showIcons ? Appearance.spacing.small : 0
        anchors.right: root.showIcons ? volHighIcon.left : parent.right
        anchors.rightMargin: root.showIcons ? Appearance.spacing.small : 0
        anchors.verticalCenter: parent.verticalCenter
        height: root.sliderHeight
        
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
            width: parent.width * Math.min(1, Math.max(0, root.value))
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
            cursorShape: Qt.PointingHandCursor
            
            onPressed: event => updateValue(event)
            onPositionChanged: event => { if (pressed) updateValue(event); }
            
            function updateValue(event) {
                const ratio = Math.max(0, Math.min(1, (event.x + 8) / sliderTrack.width));
                root.value = ratio;
                // Note: setting root.value triggers onValueChanged automatically
            }
        }
    }
    
    // Volume high icon (right)
    MaterialIcon {
        id: volHighIcon
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showIcons
        text: "volume_up"
        font.pointSize: Appearance.font.size.normal
        color: root.iconColor
        opacity: 0.6
    }
}
