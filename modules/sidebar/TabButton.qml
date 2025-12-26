import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Tab button for sidebar
Item {
    id: root
    
    required property string text
    property string icon: ""
    property bool active: false
    property int badge: 0
    property color statusColor: "transparent"
    
    signal clicked()
    
    implicitWidth: layout.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.small * 2
    
    Layout.fillWidth: true
    
    StyledRect {
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: root.active ? Colours.palette.m3secondaryContainer : mouseArea.containsMouse ? Colours.palette.m3surfaceContainerHighest : "transparent"
        
        Behavior on color { Anim {} }
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Appearance.spacing.small
        
        // Status dot
        Rectangle {
            visible: root.statusColor !== Qt.rgba(0,0,0,0)
            width: 6
            height: 6
            radius: 3
            color: root.statusColor
        }
        
        // Icon
        StyledText {
            visible: root.icon !== ""
            text: root.icon
            font.family: "Material Symbols Outlined"
            font.pointSize: Appearance.font.size.normal
            color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
        }
        
        // Text
        StyledText {
            text: root.text
            font.pointSize: Appearance.font.size.small
            font.weight: root.active ? 600 : 400
            color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
        }
        
        // Badge
        Rectangle {
            visible: root.badge > 0
            width: Math.max(badgeText.implicitWidth + 8, height)
            height: 16
            radius: 8
            color: Colours.palette.m3primary
            
            StyledText {
                id: badgeText
                anchors.centerIn: parent
                text: root.badge > 99 ? "99+" : root.badge
                font.pointSize: Appearance.font.size.smaller
                font.weight: 600
                color: Colours.palette.m3onPrimary
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
