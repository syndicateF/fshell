pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    required property var bind
    property int animationDelay: 0

    readonly property string modifiers: bind?.modifiers ?? ""
    readonly property string key: bind?.key ?? ""
    readonly property string description: bind?.description ?? ""

    // Fixed height for consistent grid layout (DPI-aware)
    readonly property real badgeHeight: Appearance.font.size.smaller * 2
    readonly property real descLineHeight: Appearance.font.size.smaller * 1.4 // deskkripsi
    implicitHeight: badgeHeight + (descLineHeight * 2) + Appearance.spacing.small * 4

    radius: Appearance.rounding.small
    color: hovered ? Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.5) : Colours.tPalette.m3surfaceContainer

    property bool hovered: hoverHandler.hovered

    // Staggered fade-in animation
    // opacity: 1
    // Component.onCompleted: itemFadeIn.start()
    
    // SequentialAnimation {
    //     id: itemFadeIn
    //     PauseAnimation { duration: root.animationDelay }
    //     NumberAnimation {
    //         target: root
    //         property: "opacity"
    //         from: 0
    //         to: 1
    //         duration: 150
    //         easing.type: Easing.OutCubic
    //     }
    // }

    // Hover scale effect
    scale: hovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    // Behavior on color { ColorAnimation { duration: 150 } }
    // Behavior on border.color { ColorAnimation { duration: 150 } }

    HoverHandler { id: hoverHandler }

    // Vertical layout: keys on top, description below
    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Appearance.spacing.small
        spacing: Appearance.spacing.small
        
        // Key combination (centered)
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Repeater {
                model: root.modifiers ? root.modifiers.split(" + ").concat([root.key]) : [root.key]
                

                Rectangle {
                    id: keyBadge
                    required property string modelData
                    required property int index

                    visible: modelData !== ""
                    width: keyContent.implicitWidth + Appearance.spacing.normal
                    height: root.badgeHeight
                    radius: 4
                    color: badgeHover.hovered ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainerHigh
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3outline, 0.3)

                    // Check if this key should use icon
                    readonly property bool useIcon: getIconForKey(modelData) !== ""
                    readonly property string iconName: getIconForKey(modelData)
                    readonly property string keyText: formatKey(modelData)
                    readonly property string keyLabel: getKeyLabel(modelData)

                    HoverHandler { id: badgeHover }

                    // Tooltip on hover
                    ToolTip {
                        visible: badgeHover.hovered && keyBadge.keyLabel !== ""
                        text: keyBadge.keyLabel
                        delay: 500
                        timeout: 3000
                        y: keyBadge.height + 4
                        
                        contentItem: Text {
                            text: keyBadge.keyLabel
                            font.pointSize: Appearance.font.size.smaller
                            font.family: Appearance.font.family.sans
                            color: Colours.palette.m3onSurface
                        }
                        
                        background: Rectangle {
                            color: Colours.palette.m3surfaceContainer
                            radius: 4
                            border.width: 1
                            border.color: Qt.alpha(Colours.palette.m3outline, 0.3)
                        }
                    }

                    // Icon or Text display
                    Loader {
                        id: keyContent
                        anchors.centerIn: parent
                        sourceComponent: keyBadge.useIcon ? iconComponent : textComponent
                    }

                    Component {
                        id: textComponent
                        Text {
                            text: keyText
                            font.pointSize: Appearance.font.size.smaller
                            font.weight: Font.Medium
                            font.family: Appearance.font.family.mono
                            color: Colours.palette.m3onSurface
                        }
                    }

                    Component {
                        id: iconComponent
                        MaterialIcon {
                            text: iconName
                            font.pointSize: Appearance.font.size.smaller + 2
                            color: Colours.palette.m3onSurface
                        }
                    }

                    function getIconForKey(k: string): string {
                        // Keys that should use MaterialIcon
                        const iconMap = {
                            // Modifiers (Ctrl/Alt use text symbols instead)
                            "Super": "keyboard_command_key",
                            "Shift": "shift",
                            // Navigation keys
                            "Return": "keyboard_return",
                            "RETURN": "keyboard_return",
                            "Tab": "keyboard_tab",
                            "TAB": "keyboard_tab",
                            "Space": "space_bar",
                            "SPACE": "space_bar",
                            "Escape": "close",
                            "ESCAPE": "close",
                            "BackSpace": "backspace",
                            "Delete": "delete",
                            // Arrow keys
                            "Up": "keyboard_arrow_up",
                            "Down": "keyboard_arrow_down",
                            "Left": "keyboard_arrow_left",
                            "Right": "keyboard_arrow_right",
                            "up": "keyboard_arrow_up",
                            "down": "keyboard_arrow_down",
                            "left": "keyboard_arrow_left",
                            "right": "keyboard_arrow_right",
                            // Page keys
                            "Home": "first_page",
                            "End": "last_page",
                            "Page_Up": "keyboard_double_arrow_up",
                            "Page_Down": "keyboard_double_arrow_down",
                            "PgUp": "keyboard_double_arrow_up",
                            "PgDn": "keyboard_double_arrow_down",
                            "Print": "screenshot",
                            // Lock keys
                            "Caps_Lock": "keyboard_capslock",
                            "Num_Lock": "pin",
                            "Scroll_Lock": "lock",
                            // Super variants
                            "Super_L": "keyboard_command_key",
                            "Super_R": "keyboard_command_key",
                            // Insert
                            "Insert": "content_paste",
                            // Mouse
                            "mouse_up": "expand_less",
                            "mouse_down": "expand_more",
                            "mouse:272": "mouse",
                            "mouse:273": "ads_click",
                            "mouse:274": "radio_button_checked",
                            // Media keys
                            "XF86AudioRaiseVolume": "volume_up",
                            "XF86AudioLowerVolume": "volume_down",
                            "XF86AudioMute": "volume_off",
                            "XF86AudioMicMute": "mic_off",
                            "XF86AudioPlay": "play_arrow",
                            "XF86AudioPause": "pause",
                            "XF86AudioPlayPause": "play_pause",
                            "XF86AudioStop": "stop",
                            "XF86AudioNext": "skip_next",
                            "XF86AudioPrev": "skip_previous",
                            "XF86MonBrightnessUp": "brightness_high",
                            "XF86MonBrightnessDown": "brightness_low"
                        };
                        return iconMap[k] ?? "";
                    }

                    function formatKey(k: string): string {
                        // Fallback text for keys without Material Icons
                        const keyMap = {
                            // Modifiers - Unicode symbols
                            "Ctrl": "⌃",
                            "Alt": "⌥",
                            // Punctuation - no Material Icons available
                            "Comma": ",",
                            "comma": ",",
                            "Minus": "−",
                            "minus": "−",
                            "Equal": "=",
                            "equal": "=",
                            "Backslash": "\\",
                            "backslash": "\\",
                            "Slash": "/",
                            "slash": "/",
                            "Period": ".",
                            "period": ".",
                            "Semicolon": ";",
                            "semicolon": ";",
                            "Apostrophe": "'",
                            "apostrophe": "'",
                            "Grave": "`",
                            "grave": "`",
                            "BracketLeft": "[",
                            "bracketleft": "[",
                            "BracketRight": "]",
                        };
                        return keyMap[k] ?? k;
                    }

                    function getKeyLabel(k: string): string {
                        // Human-readable labels for tooltips
                        const labelMap = {
                            // Modifiers
                            "Super": "Super/Win Key",
                            "Ctrl": "Control",
                            "Alt": "Alt/Option",
                            "Shift": "Shift",
                            // Navigation
                            "Return": "Enter",
                            "Tab": "Tab",
                            "Space": "Space",
                            "Escape": "Escape",
                            "BackSpace": "Backspace",
                            "Delete": "Delete",
                            // Arrows
                            "Up": "Arrow Up",
                            "Down": "Arrow Down",
                            "Left": "Arrow Left",
                            "Right": "Arrow Right",
                            "up": "Arrow Up",
                            "down": "Arrow Down",
                            "left": "Arrow Left",
                            "right": "Arrow Right",
                            // Page keys
                            "Home": "Home",
                            "End": "End",
                            "Page_Up": "Page Up",
                            "Page_Down": "Page Down",
                            "PgUp": "Page Up",
                            "PgDn": "Page Down",
                            "Print": "Print Screen",
                            // Mouse
                            "mouse_up": "Scroll Up",
                            "mouse_down": "Scroll Down",
                            "mouse:272": "Left Click",
                            "mouse:273": "Right Click",
                            "mouse:274": "Middle Click",
                            // Media
                            "XF86AudioRaiseVolume": "Volume Up",
                            "XF86AudioLowerVolume": "Volume Down",
                            "XF86AudioMute": "Mute",
                            "XF86AudioPlay": "Play",
                            "XF86AudioPause": "Pause",
                            "XF86AudioNext": "Next Track",
                            "XF86AudioPrev": "Previous Track",
                            "XF86MonBrightnessUp": "Brightness Up",
                            "XF86MonBrightnessDown": "Brightness Down"
                        };
                        return labelMap[k] ?? "";
                    }
                }
            }
        }

        // Description (centered, can wrap)
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            text: root.description
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.sans
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
