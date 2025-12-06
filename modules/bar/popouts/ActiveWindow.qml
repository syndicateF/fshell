import qs.components
import qs.components.effects
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick

Item {
    id: root

    required property Item wrapper
    
    readonly property bool hasWindow: Hypr.activeToplevel !== null

    implicitWidth: hasWindow ? preview.width : fetchContent.implicitWidth
    implicitHeight: hasWindow ? preview.height : fetchContent.implicitHeight

    // Caelestiafetch-style content - empty state (using SysInfo like lockscreen)
    Column {
        id: fetchContent
        visible: !root.hasWindow
        spacing: Appearance.spacing.small
        padding: Appearance.padding.small
        
        // Header: > caelestiafetch.sh
        Row {
            spacing: Appearance.spacing.small
            
            StyledRect {
                width: promptText.implicitWidth + Appearance.padding.small * 2
                height: promptText.implicitHeight + Appearance.padding.smaller * 2
                color: Colours.palette.m3primary
                radius: Appearance.rounding.smaller
                
                StyledText {
                    id: promptText
                    anchors.centerIn: parent
                    text: ">"
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onPrimary
                }
            }
            
            StyledText {
                text: "caelestiafetch.sh"
                font.family: Appearance.font.family.mono
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        // ASCII art + info side by side
        Row {
            spacing: Appearance.spacing.normal
            
            // OS Logo
            ColouredIcon {
                source: SysInfo.osLogo
                implicitSize: 48
                colour: Colours.palette.m3primary
            }
            
            // System info
            Column {
                spacing: Appearance.spacing.smaller
                anchors.verticalCenter: parent.verticalCenter
                
                // OS
                StyledText {
                    text: `OS  : ${SysInfo.osPrettyName || SysInfo.osName}`
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurface
                }
                
                // WM
                StyledText {
                    text: `WM  : ${SysInfo.wm}`
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurface
                }
                
                // User
                StyledText {
                    text: `USER: ${SysInfo.user}`
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurface
                }
                
                // Uptime
                StyledText {
                    text: `UP  : ${SysInfo.uptime}`
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurface
                }
            }
        }
        
        // Color palette bar
        Row {
            spacing: 4
            
            Repeater {
                model: 8
                
                Rectangle {
                    required property int index
                    width: 16
                    height: 10
                    radius: 2
                    color: Colours.palette[`term${index}`]
                }
            }
        }
    }

    // Window preview - when there's an active window
    Item {
        anchors.fill: parent
        visible: root.hasWindow
        
        // Click anywhere to open WindowInfo
        StateLayer {
            anchors.fill: previewWrapper
            radius: Appearance.rounding.small

            function onClicked(): void {
                root.wrapper.detach("winfo");
            }
        }

        ClippingWrapperRectangle {
            id: previewWrapper
            color: "transparent"
            radius: Appearance.rounding.small

            ScreencopyView {
                id: preview

                captureSource: Hypr.activeToplevel?.wayland ?? null
                live: visible && root.hasWindow

                constraintSize.width: Config.bar.sizes.windowPreviewSize
                constraintSize.height: Config.bar.sizes.windowPreviewSize
            }
        }
    }
}
