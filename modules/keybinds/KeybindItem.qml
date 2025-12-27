pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var bind

    readonly property string modifiers: bind?.modifiers ?? ""
    readonly property string key: bind?.key ?? ""
    readonly property string description: bind?.description ?? ""

    implicitWidth: Math.min(280, contentRow.implicitWidth + Appearance.spacing.normal * 2)
    implicitHeight: contentRow.implicitHeight + Appearance.spacing.small * 2

    radius: Appearance.rounding.small
    color: hovered ? Qt.alpha(Colours.palette.m3primary, 0.08) : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.5)
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3outline, 0.1)

    property bool hovered: hoverHandler.hovered

    HoverHandler { id: hoverHandler }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.margins: Appearance.spacing.small
        spacing: Appearance.spacing.small

        // Key combination
        Row {
            spacing: 4

            Repeater {
                model: root.modifiers ? root.modifiers.split(" + ").concat([root.key]) : [root.key]

                Rectangle {
                    required property string modelData
                    required property int index

                    visible: modelData !== ""
                    width: keyText.implicitWidth + 12
                    height: 24
                    radius: 4
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3outline, 0.3)

                    Text {
                        id: keyText
                        anchors.centerIn: parent
                        text: formatKey(modelData)
                        font.pointSize: Appearance.font.size.smaller
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.mono
                        color: Colours.palette.m3onSurface
                    }

                    function formatKey(k: string): string {
                        // Format common keys for better display
                        const keyMap = {
                            "Super": "⌘",
                            "Ctrl": "Ctrl",
                            "Alt": "Alt",
                            "Shift": "⇧",
                            "Return": "↵",
                            "Space": "␣",
                            "Tab": "⇥",
                            "Escape": "Esc",
                            "BackSpace": "⌫",
                            "Delete": "Del",
                            "Up": "↑",
                            "Down": "↓",
                            "Left": "←",
                            "Right": "→",
                            "Home": "Home",
                            "End": "End",
                            "Page_Up": "PgUp",
                            "Page_Down": "PgDn",
                            "Print": "PrtSc",
                            "XF86AudioRaiseVolume": "🔊+",
                            "XF86AudioLowerVolume": "🔊-",
                            "XF86AudioMute": "🔇",
                            "XF86AudioPlay": "⏯",
                            "XF86AudioPause": "⏸",
                            "XF86AudioNext": "⏭",
                            "XF86AudioPrev": "⏮",
                            "XF86MonBrightnessUp": "🔆+",
                            "XF86MonBrightnessDown": "🔆-"
                        };
                        return keyMap[k] ?? k;
                    }
                }
            }
        }

        // Spacer
        Item { Layout.preferredWidth: 4 }

        // Description
        Text {
            Layout.fillWidth: true
            text: root.description
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.sans
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
