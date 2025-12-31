pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Vertical grid item: keys on top (centered), badges below, description at bottom
Rectangle {
    id: root

    required property var bind
    property int animationDelay: 0

    readonly property string modifiers: bind?.modifiers ?? ""
    readonly property string key: bind?.key ?? ""
    readonly property string description: bind?.description ?? ""

    // All sizes dynamic based on Appearance (DPI-aware)
    readonly property real badgeHeight: Appearance.font.size.smaller * 2
    readonly property real modeBadgeSize: Appearance.font.size.smaller * 1.2
    readonly property real descLineHeight: Appearance.font.size.smaller * 1.4
    
    // Dynamic height based on content
    implicitHeight: badgeHeight + modeBadgeSize + (descLineHeight * 2) + Appearance.spacing.small * 5

    radius: Appearance.rounding.small
    color: hovered ? Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.5) : Colours.tPalette.m3surfaceContainer

    property bool hovered: hoverHandler.hovered

    // Hover scale effect
    scale: hovered ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    HoverHandler { id: hoverHandler }

    // Vertical layout: keys top, badges middle, description bottom
    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Appearance.spacing.small
        spacing: Appearance.spacing.small
        
        // ROW 1: Key combination (centered)
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small * 0.5

            Repeater {
                model: root.modifiers ? root.modifiers.split(" + ").concat([root.key]) : [root.key]

                Rectangle {
                    id: keyBadge
                    required property string modelData
                    required property int index

                    visible: modelData !== ""
                    width: keyContent.implicitWidth + Appearance.spacing.normal
                    height: root.badgeHeight
                    radius: Appearance.rounding.small * 0.5
                    color: badgeHover.hovered ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainerHigh
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3outline, 0.3)

                    readonly property bool useIcon: getIconForKey(modelData) !== ""
                    readonly property string iconName: getIconForKey(modelData)
                    readonly property string keyText: formatKey(modelData)
                    readonly property string keyLabel: getKeyLabel(modelData)

                    HoverHandler { id: badgeHover }

                    ToolTip {
                        visible: badgeHover.hovered && keyBadge.keyLabel !== ""
                        text: keyBadge.keyLabel
                        delay: 500
                        timeout: 3000
                        y: keyBadge.height + Appearance.spacing.small * 0.5
                        
                        contentItem: Text {
                            text: keyBadge.keyLabel
                            font.pointSize: Appearance.font.size.smaller
                            font.family: Appearance.font.family.sans
                            color: Colours.palette.m3onSurface
                        }
                        
                        background: Rectangle {
                            color: Colours.palette.m3surfaceContainer
                            radius: Appearance.rounding.small * 0.5
                            border.width: 1
                            border.color: Qt.alpha(Colours.palette.m3outline, 0.3)
                        }
                    }

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
                        const iconMap = {
                            "Super": "keyboard_command_key",
                            "Shift": "shift",
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
                            "Up": "keyboard_arrow_up",
                            "Down": "keyboard_arrow_down",
                            "Left": "keyboard_arrow_left",
                            "Right": "keyboard_arrow_right",
                            "up": "keyboard_arrow_up",
                            "down": "keyboard_arrow_down",
                            "left": "keyboard_arrow_left",
                            "right": "keyboard_arrow_right",
                            "Home": "first_page",
                            "End": "last_page",
                            "Page_Up": "keyboard_double_arrow_up",
                            "Page_Down": "keyboard_double_arrow_down",
                            "PgUp": "keyboard_double_arrow_up",
                            "PgDn": "keyboard_double_arrow_down",
                            "Print": "screenshot",
                            "Caps_Lock": "keyboard_capslock",
                            "Num_Lock": "pin",
                            "Scroll_Lock": "lock",
                            "Super_L": "keyboard_command_key",
                            "Super_R": "keyboard_command_key",
                            "Insert": "content_paste",
                            "mouse_up": "expand_less",
                            "mouse_down": "expand_more",
                            "mouse:272": "mouse",
                            "mouse:273": "ads_click",
                            "mouse:274": "radio_button_checked",
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
                        const keyMap = {
                            "Ctrl": "⌃",
                            "Alt": "⌥",
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
                        const labelMap = {
                            "Super": "Super/Win Key",
                            "Ctrl": "Control",
                            "Alt": "Alt/Option",
                            "Shift": "Shift",
                            "Return": "Enter",
                            "Tab": "Tab",
                            "Space": "Space",
                            "Escape": "Escape",
                            "BackSpace": "Backspace",
                            "Delete": "Delete",
                            "Up": "Arrow Up",
                            "Down": "Arrow Down",
                            "Left": "Arrow Left",
                            "Right": "Arrow Right",
                            "up": "Arrow Up",
                            "down": "Arrow Down",
                            "left": "Arrow Left",
                            "right": "Arrow Right",
                            "Home": "Home",
                            "End": "End",
                            "Page_Up": "Page Up",
                            "Page_Down": "Page Down",
                            "PgUp": "Page Up",
                            "PgDn": "Page Down",
                            "Print": "Print Screen",
                            "mouse_up": "Scroll Up",
                            "mouse_down": "Scroll Down",
                            "mouse:272": "Left Click",
                            "mouse:273": "Right Click",
                            "mouse:274": "Middle Click",
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

        // ROW 2: Mode badges (centered)
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small * 0.25

            Rectangle {
                width: root.modeBadgeSize
                height: root.modeBadgeSize
                radius: Appearance.rounding.small * 0.4
                color: Qt.alpha(Colours.palette.m3primary, 0.15)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "lock_open"
                    font.pointSize: Appearance.font.size.smaller - 3
                    color: Colours.palette.m3primary
                }
            }

            Rectangle {
                visible: root.bind?.flags?.locked ?? false
                width: root.modeBadgeSize
                height: root.modeBadgeSize
                radius: Appearance.rounding.small * 0.4
                color: Qt.alpha(Colours.palette.m3tertiary, 0.15)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "lock"
                    font.pointSize: Appearance.font.size.smaller - 3
                    color: Colours.palette.m3tertiary
                }
            }

            Rectangle {
                visible: (root.bind?.flags?.repeat ?? false) || (root.bind?.flags?.release ?? false)
                width: 1
                height: root.modeBadgeSize * 0.75
                color: Qt.alpha(Colours.palette.m3outline, 0.3)
            }

            Rectangle {
                visible: root.bind?.flags?.repeat ?? false
                width: root.modeBadgeSize
                height: root.modeBadgeSize
                radius: Appearance.rounding.small * 0.4
                color: Qt.alpha(Colours.palette.m3secondary, 0.15)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "repeat"
                    font.pointSize: Appearance.font.size.smaller - 3
                    color: Colours.palette.m3secondary
                }
            }

            Rectangle {
                visible: root.bind?.flags?.release ?? false
                width: root.modeBadgeSize
                height: root.modeBadgeSize
                radius: Appearance.rounding.small * 0.4
                color: Qt.alpha(Colours.palette.m3outline, 0.15)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "keyboard_arrow_up"
                    font.pointSize: Appearance.font.size.smaller - 3
                    color: Colours.palette.m3outline
                }
            }
        }

        // ROW 3: Description (centered, wraps)
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
