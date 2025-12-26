pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Chat message bubble with proper sizing
Item {
    id: root
    
    required property bool isUser
    required property string content
    property string explanation: ""
    property string thinking: ""
    
    Component.onCompleted: {
        if (!isUser) console.log("MessageBubble: thinking='" + thinking.substring(0,30) + "...' len=" + thinking.length)
    }
    
    // Proper height calculation
    implicitHeight: bubble.height
    implicitWidth: parent ? parent.width : 300
    
    StyledRect {
        id: bubble
        
        // Position based on user/assistant
        anchors.left: root.isUser ? undefined : parent.left
        anchors.right: root.isUser ? parent.right : undefined
        
        // Width constrained to 85% of parent, but flexible
        width: Math.min(contentCol.implicitWidth + Appearance.padding.normal * 2, parent.width * 0.85)
        
        // Height must be explicit from content
        height: contentCol.implicitHeight + Appearance.padding.normal * 2
        
        radius: Appearance.rounding.normal
        color: root.isUser ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
        
        ColumnLayout {
            id: contentCol
            
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.padding.normal
            
            spacing: Appearance.spacing.small
            
            // Main content
            StyledText {
                Layout.fillWidth: true
                text: root.content
                wrapMode: Text.Wrap
                color: root.isUser ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
            }
            
            // Thinking section - simple version
            Rectangle {
                id: thinkingSection
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.smaller
                visible: root.thinking !== "" && !root.isUser
                
                property bool expanded: false
                
                // Height includes padding on both sides
                implicitHeight: expanded 
                    ? thinkingCol.implicitHeight + Appearance.padding.small * 2
                    : thinkingHeader.implicitHeight + Appearance.padding.small * 2
                
                color: expanded ? Colours.palette.m3surfaceContainerLowest : Colours.palette.m3surfaceContainerHighest
                radius: Appearance.rounding.small
                
                Behavior on implicitHeight { Anim { duration: Appearance.anim.durations.normal } }
                Behavior on color { Anim {} }
                
                ColumnLayout {
                    id: thinkingCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.padding.small
                    spacing: Appearance.spacing.small
                    
                    // Header row
                    RowLayout {
                        id: thinkingHeader
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small
                        
                        StyledText {
                            text: thinkingSection.expanded ? "▼ Thinking" : "▶ Thinking"
                            color: Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.small
                            font.weight: Font.Medium
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                    
                    // Content (only when expanded)
                    StyledText {
                        Layout.fillWidth: true
                        visible: thinkingSection.expanded
                        text: root.thinking
                        wrapMode: Text.Wrap
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                        font.family: Appearance.font.family.mono || "monospace"
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: thinkingSection.expanded = !thinkingSection.expanded
                }
            }
            
            // Explanation (if present)
            StyledText {
                Layout.fillWidth: true
                visible: root.explanation !== ""
                text: root.explanation
                wrapMode: Text.Wrap
                color: root.isUser ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
                font.italic: true
                opacity: 0.8
            }
        }
    }
}
