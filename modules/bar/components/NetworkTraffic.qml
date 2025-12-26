pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

// Network Traffic Indicator - Minimalist vertical with smooth transitions
// Shows pulsing dot when no network connected
StyledRect {
    id: root

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: mainLayout.implicitHeight + Config.bar.sizes.itemPadding
    
    radius: Appearance.rounding.small
    color: Colours.palette.m3surfaceContainerHigh

    // Check if network is connected
    readonly property bool isConnected: Network.active !== null

    // Subscribe to traffic monitoring when this component is active
    Component.onCompleted: Network.trafficRefCount++
    Component.onDestruction: Network.trafficRefCount--

    // Original format with decimals
    function formatSpeedShort(bytesPerSec: real): string {
        if (bytesPerSec >= 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + "M"
        } else if (bytesPerSec >= 1024) {
            return (bytesPerSec / 1024).toFixed(0) + "K"
        } else {
            return bytesPerSec.toFixed(0) + "B"
        }
    }

    // Pulsing dot when disconnected
    Rectangle {
        id: pulsingDot
        anchors.centerIn: parent
        width: 10
        height: 10
        radius: 5
        color: Colours.palette.m3error
        opacity: root.isConnected ? 0 : 1
        scale: root.isConnected ? 0.5 : 1
        visible: opacity > 0
        
        Behavior on opacity { 
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } 
        }
        Behavior on scale { 
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } 
        }
        
        SequentialAnimation on opacity {
            running: !root.isConnected && pulsingDot.opacity > 0.9
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
        }
    }

    // Normal traffic display when connected
    Column {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 3
        opacity: root.isConnected ? 1 : 0
        scale: root.isConnected ? 1 : 0.8
        visible: opacity > 0
        
        Behavior on opacity { 
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } 
        }
        Behavior on scale { 
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } 
        }

        // Upload section - vertical
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1
            
            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "arrow_upward"
                color: Colours.palette.m3primary
                font.pointSize: Config.bar.sizes.font.materialIcon
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.formatSpeedShort(Network.uploadSpeed)
                font.pixelSize: 11
                font.family: Appearance.font.family.sans
                font.weight: Font.Medium
                color: Colours.palette.m3primary
                
                // Scale based on text length: 2 chars=1.0, 3 chars=0.8, 4+ chars=0.6
                readonly property int textLen: text.length
                scale: textLen <= 2 ? 1.0 : (textLen === 3 ? 0.9 : 0.7)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
        }

        // Divider
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Config.bar.sizes.innerWidth - Appearance.padding.normal * 2
            height: 1
            color: Colours.palette.m3primary
            opacity: 0.4
        }

        // Download section - vertical
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.formatSpeedShort(Network.downloadSpeed)
                font.pixelSize: 11
                font.family: Appearance.font.family.sans
                font.weight: Font.Medium
                color: Colours.palette.m3primary
                
                // Scale based on text length: 2 chars=1.0, 3 chars=0.8, 4+ chars=0.6
                readonly property int textLen: text.length
                scale: textLen <= 2 ? 1.0 : (textLen === 3 ? 0.9 : 0.7)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
            
            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "arrow_downward"
                color: Colours.palette.m3primary
                font.pointSize: Config.bar.sizes.font.materialIcon
            }
        }
    }
}
