pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Tool execution result bubble with proper sizing
Item {
    id: root
    
    required property string toolName
    required property string status
    property string output: ""
    property string error: ""
    
    // Proper height calculation
    implicitHeight: bubble.height
    implicitWidth: parent ? parent.width : 300
    
    StyledRect {
        id: bubble
        
        anchors.left: parent.left
        anchors.right: parent.right
        
        // Height from content
        height: contentCol.implicitHeight + Appearance.padding.small * 2
        
        radius: Appearance.rounding.small
        color: root.status === "executed" ? Colours.palette.m3tertiaryContainer 
             : root.status === "rejected" ? Colours.palette.m3errorContainer
             : Colours.palette.m3surfaceContainerHighest
        
        ColumnLayout {
            id: contentCol
            
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.padding.small
            
            spacing: Appearance.spacing.smaller
            
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small
                
                StyledText {
                    text: root.status === "executed" ? "✓" : root.status === "rejected" ? "✗" : "⏳"
                    font.pointSize: Appearance.font.size.small
                }
                
                StyledText {
                    text: root.toolName
                    font.pointSize: Appearance.font.size.small
                    font.weight: 600
                    font.family: Appearance.font.family.mono
                    color: Colours.palette.m3onTertiaryContainer
                }
                
                StyledText {
                    text: `[${root.status}]`
                    font.pointSize: Appearance.font.size.smaller
                    font.family: Appearance.font.family.mono
                    color: Colours.palette.m3outline
                }
            }
            
            // Output (truncated if needed)
            StyledText {
                Layout.fillWidth: true
                visible: root.output !== ""
                text: root.output.length > 500 ? root.output.substring(0, 500) + "..." : root.output
                wrapMode: Text.Wrap
                font.pointSize: Appearance.font.size.smaller
                font.family: Appearance.font.family.mono
                color: Colours.palette.m3onTertiaryContainer
                opacity: 0.9
                maximumLineCount: 10
                elide: Text.ElideRight
            }
            
            // Error
            StyledText {
                Layout.fillWidth: true
                visible: root.error !== ""
                text: "Error: " + root.error
                wrapMode: Text.Wrap
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3error
            }
        }
    }
}
