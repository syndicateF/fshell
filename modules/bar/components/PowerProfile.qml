pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

// Power Profile quick indicator for bar
StyledRect {
    id: root

    required property var bar
    required property var popouts

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding
    
    readonly property color profileColor: {
        if (Power.safeModeActive) return Colours.palette.m3error;
        if (Power._busy) return Colours.palette.m3outline;
        switch (Power.platformProfile) {
            case "performance": return Colours.palette.m3error;
            case "low-power": return Colours.palette.m3tertiary;
            case "custom": return Colours.palette.m3secondary;
            default: return Colours.palette.m3primary;
        }
    }

    readonly property string profileIcon: {
        switch (Power.platformProfile) {
            case "performance": return "bolt";
            case "low-power": return "eco";
            case "custom": return "tune";
            default: return "speed";
        }
    }

    readonly property string profileName: {
        switch (Power.platformProfile) {
            case "performance": return qsTr("Performance");
            case "low-power": return qsTr("Low Power");
            case "balanced": return qsTr("Balanced");
            case "custom": return qsTr("Custom");
            default: return Power.platformProfile;
        }
    }

    readonly property real maxTitleLength: 120

    clip: true
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: iconItem.implicitHeight + titleContainer.height + Appearance.spacing.smaller + Config.bar.sizes.itemPadding * 2
    
    visible: Power.available
    opacity: Power._busy ? 0.6 : 1.0

    Behavior on opacity { Anim {} }

    MaterialIcon {
        id: iconItem
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Config.bar.sizes.itemPadding

        text: root.profileIcon
        color: root.profileColor
        font.pointSize: Config.bar.sizes.font.materialIcon
        
        SequentialAnimation on opacity {
            running: Power._busy
            loops: Animation.Infinite
            alwaysRunToEnd: true
            Anim { from: 1; to: 0.4; duration: 400 }
            Anim { from: 0.4; to: 1; duration: 400 }
        }

        Behavior on color { ColorAnimation { duration: 200 } }
    }

    TextMetrics {
        id: titleMetrics
        text: root.profileName
        font.pointSize: Config.bar.sizes.font.windowTitle
        font.family: Appearance.font.family.sans
        elide: Qt.ElideRight
        elideWidth: root.maxTitleLength
    }

    Item {
        id: titleContainer
        
        anchors.horizontalCenter: iconItem.horizontalCenter
        anchors.top: iconItem.bottom
        anchors.topMargin: Appearance.spacing.smaller
        
        width: titleText.implicitHeight
        height: Math.min(titleText.implicitWidth, root.maxTitleLength)
        
        Text {
            id: titleText
            text: titleMetrics.elidedText
            font.pointSize: Config.bar.sizes.font.windowTitle
            font.family: Appearance.font.family.sans
            font.hintingPreference: Font.PreferDefaultHinting
            font.variableAxes: ({ "wght": Config.bar.sizes.textWeight, "wdth": Config.bar.sizes.textWidth })
            color: root.profileColor
            renderType: Text.NativeRendering
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        
        transform: [
            Rotation {
                angle: 90
                origin.x: titleText.implicitHeight / 2
                origin.y: titleText.implicitHeight / 2
            }
        ]
    }

    MaterialIcon {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        
        visible: Power.safeModeActive
        text: "warning"
        color: Colours.palette.m3error
        font.pointSize: Appearance.font.size.small
    }
}
