import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Lockscreen Widget - ABSOLUTE POSITIONING (based on eww source)
// Run: quickshell -p prototypes/lockscreen-widget

Scope {
    id: root

    property color bgCard: "#3D4455"
    property color bgCardDark: "#343946"
    
    property color accentPink: "#E8729A"
    property color accentCyan: "#5BCEFA"
    property color accentGreen: "#5DDE85"
    property color accentYellow: "#E5C07B"
    property color accentRed: "#E55B5B"
    property color accentPurple: "#9D79D1"
    
    property color textWhite: "#FFFFFF"
    property color textGray: "#8B919D"
    property color textMuted: "#5C6370"

    // Grid dimensions (scaled from eww 1920x1080 to fit)
    property real scale: 0.45
    property int gap: Math.round(15 * scale)

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: previewWindow
            
            required property var modelData
            screen: modelData
            
            anchors { top: true; left: true; right: true; bottom: true }
            visible: true
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "lockscreen-prototype"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1E2128" }
                    GradientStop { position: 0.4; color: "#2A2F3A" }
                    GradientStop { position: 1.0; color: "#3A4050" }
                }
            }

            // Container centered on screen
            Item {
                id: container
                anchors.centerIn: parent
                
                // Total dimensions from eww: x range 150-1770, y range 150-930
                width: Math.round(1620 * root.scale)
                height: Math.round(780 * root.scale)

                // ═══════════════════════════════════════════════════
                // COLUMN 1: Profile (0, 0) + System (0, 455)
                // ═══════════════════════════════════════════════════

                // PROFILE - eww: x=150, y=150, w=350, h=440
                Rectangle {
                    x: 0
                    y: 0
                    width: Math.round(350 * root.scale)
                    height: Math.round(440 * root.scale)
                    radius: 14
                    color: root.bgCardDark

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12

                        Item { Layout.fillHeight: true }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 65; height: 65
                            radius: 32.5
                            color: "#1E2128"
                            Text { anchors.centerIn: parent; text: "🌙"; font.pixelSize: 24; opacity: 0.5 }
                        }

                        Text { Layout.alignment: Qt.AlignHCenter; text: "Aditya Shakya"; font.pixelSize: 12; font.bold: true; color: root.accentPink }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "@adi1090x"; font.pixelSize: 9; color: root.textMuted }

                        Item { Layout.fillHeight: true }
                    }
                }

                // SYSTEM (Stats) - eww: x=150, y=605, w=350, h=325 -> relative y = 455
                Rectangle {
                    x: 0
                    y: Math.round(455 * root.scale)
                    width: Math.round(350 * root.scale)
                    height: Math.round(325 * root.scale)
                    radius: 14
                    color: root.bgCardDark

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text { text: "⚙"; font.pixelSize: 10; color: root.textMuted }

                        ResourceBar { Layout.fillWidth: true; iconColor: root.accentPink; barColor: root.accentPink; value: 0.50 }
                        ResourceBar { Layout.fillWidth: true; iconColor: root.accentGreen; barColor: root.accentGreen; value: 0.70 }
                        ResourceBar { Layout.fillWidth: true; iconColor: root.accentYellow; barColor: root.accentYellow; value: 0.40 }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ═══════════════════════════════════════════════════
                // COLUMN 2: Clock (365, 0) + Uptime (365, 170) + Music (365, 340) + Social (365, 635)
                // ═══════════════════════════════════════════════════

                // CLOCK - eww: x=515, y=150, w=350, h=155 -> relative x = 365
                Rectangle {
                    x: Math.round(365 * root.scale)
                    y: 0
                    width: Math.round(350 * root.scale)
                    height: Math.round(155 * root.scale)
                    radius: 14
                    color: root.bgCard

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 0

                        Text { text: "10"; font.pixelSize: 42; font.bold: true; color: root.textWhite }
                        Text { Layout.alignment: Qt.AlignTop; Layout.topMargin: 3; text: "43"; font.pixelSize: 24; font.bold: true; color: root.textWhite }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 6
                            Layout.leftMargin: 4
                            spacing: 0

                            Text { text: "PM"; font.pixelSize: 11; font.bold: true; color: root.accentPink }
                            Text { text: "Wednesday"; font.pixelSize: 8; color: root.textMuted }
                        }
                    }
                }

                // UPTIME - eww: x=515, y=320, w=350, h=155 -> relative y = 170
                Rectangle {
                    x: Math.round(365 * root.scale)
                    y: Math.round(170 * root.scale)
                    width: Math.round(350 * root.scale)
                    height: Math.round(155 * root.scale)
                    radius: 14
                    color: root.bgCard

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 22; height: 22; radius: 4
                            color: "transparent"; border.width: 2; border.color: root.accentYellow
                            Text { anchors.centerIn: parent; text: "💡"; font.pixelSize: 10 }
                        }

                        ColumnLayout {
                            spacing: 0
                            Text { text: "9 hours"; font.pixelSize: 13; font.bold: true; color: root.textWhite }
                            Text { text: "55 minutes"; font.pixelSize: 9; color: root.textMuted }
                        }
                    }
                }

                // MUSIC - eww: x=515, y=490, w=610, h=280 -> relative y = 340
                Rectangle {
                    x: Math.round(365 * root.scale)
                    y: Math.round(340 * root.scale)
                    width: Math.round(610 * root.scale)
                    height: Math.round(280 * root.scale)
                    radius: 14
                    color: root.bgCard
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            color: "#2A3040"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 1

                                Text { text: "THE"; font.pixelSize: 10; font.bold: true; color: root.textWhite }
                                Text { text: "NIGHT"; font.pixelSize: 13; font.bold: true; color: root.textWhite }
                                Text { text: "WE MET"; font.pixelSize: 13; font.bold: true; color: root.textWhite }
                                Item { Layout.fillHeight: true }
                                Text { text: "LORD HURON"; font.pixelSize: 7; color: root.textMuted }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: 12
                            spacing: 4

                            Item { Layout.fillHeight: true }
                            Text { text: "The Night We Met"; font.pixelSize: 14; font.bold: true; color: root.textWhite }
                            Text { text: "Lord Huron"; font.pixelSize: 10; color: root.textMuted; font.italic: true }
                            RowLayout {
                                Layout.topMargin: 6
                                spacing: 16
                                Text { text: "⏮"; font.pixelSize: 14; color: root.textGray }
                                Rectangle {
                                    width: 28; height: 28; radius: 14; color: root.textWhite
                                    Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 10; color: root.bgCard }
                                }
                                Text { text: "⏭"; font.pixelSize: 14; color: root.textGray }
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                // SOCIAL (4 buttons) - eww: x=515-983, y=785, each w=141, h=145 -> relative y = 635
                Row {
                    x: Math.round(365 * root.scale)
                    y: Math.round(635 * root.scale)
                    spacing: root.gap

                    Repeater {
                        model: [
                            { color: "#24292E", icon: "🐙" },
                            { color: "#FF4500", icon: "🔴" },
                            { color: "#1DA1F2", icon: "🐦" },
                            { color: "#FF0000", icon: "▶" }
                        ]

                        Rectangle {
                            required property var modelData
                            width: Math.round(141 * root.scale)
                            height: Math.round(145 * root.scale)
                            radius: 12
                            color: modelData.color
                            Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 18; color: root.textWhite }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════
                // COLUMN 3: Weather (730, 0) + Apps (990, 340) + Mail (990, 635)
                // ═══════════════════════════════════════════════════

                // WEATHER - eww: x=880, y=150, w=550, h=325 -> relative x = 730
                Rectangle {
                    x: Math.round(730 * root.scale)
                    y: 0
                    width: Math.round(550 * root.scale)
                    height: Math.round(325 * root.scale)
                    radius: 14
                    color: root.bgCard

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "🌙"; font.pixelSize: 40 }
                            Item { Layout.fillWidth: true }
                            Text { text: "35°C"; font.pixelSize: 28; font.bold: true; color: root.accentCyan }
                        }

                        Text { text: "Clear Sky"; font.pixelSize: 16; font.bold: true; font.italic: true; color: root.accentGreen }
                        Text { text: "It's a clear night"; font.pixelSize: 10; color: root.textMuted }
                        Text { Layout.fillWidth: true; text: "You might want to take a evening stroll to relax..."; font.pixelSize: 9; color: root.textMuted; wrapMode: Text.WordWrap }

                        Item { Layout.fillHeight: true }
                    }
                }

                // APPS - eww: x=1140, y=490, w=290, h=280 -> relative x = 990
                Rectangle {
                    x: Math.round(990 * root.scale)
                    y: Math.round(340 * root.scale)
                    width: Math.round(290 * root.scale)
                    height: Math.round(280 * root.scale)
                    radius: 14
                    color: root.bgCard

                    GridLayout {
                        anchors.centerIn: parent
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: ["#5E66F2", "#28A8E8", "#7289DA", "#28B463", "#3498DB", "#F4B400", "#2196F3", "#6B4FBB", "#00BCD4"]
                            Rectangle { required property var modelData; width: 30; height: 30; radius: 6; color: modelData }
                        }
                    }
                }

                // MAIL - eww: x=1140, y=785, w=290, h=145 -> relative y = 635
                Rectangle {
                    x: Math.round(990 * root.scale)
                    y: Math.round(635 * root.scale)
                    width: Math.round(290 * root.scale)
                    height: Math.round(145 * root.scale)
                    radius: 14
                    color: "#FFFFFF"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text { text: "✉"; font.pixelSize: 24; color: "#EA4335" }
                        Rectangle {
                            width: badgeNum.width + 8; height: 20; radius: 10; color: root.accentYellow
                            Text { id: badgeNum; anchors.centerIn: parent; text: "230"; font.pixelSize: 10; font.bold: true; color: "#1E2128" }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════
                // COLUMN 4: Power 2x2 (1295, 0) + Folders (1295, 340)
                // ═══════════════════════════════════════════════════

                // POWER GRID (2x2) - eww: x=1445-1770, y=150-475, each w=155, h=155
                Grid {
                    x: Math.round(1295 * root.scale)
                    y: 0
                    columns: 2
                    spacing: root.gap

                    Repeater {
                        model: [
                            { icon: "⇥", color: root.accentPink },
                            { icon: "⏻", color: root.accentGreen },
                            { icon: "🔄", color: root.accentCyan },
                            { icon: "⏻", color: root.accentRed }
                        ]

                        Rectangle {
                            required property var modelData
                            width: Math.round(155 * root.scale)
                            height: Math.round(155 * root.scale)
                            radius: 14
                            color: root.bgCard
                            Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 20; color: modelData.color }
                        }
                    }
                }

                // FOLDERS (Storage) - eww: x=1445, y=490, w=325, h=440 -> relative y = 340
                Rectangle {
                    x: Math.round(1295 * root.scale)
                    y: Math.round(340 * root.scale)
                    width: Math.round(325 * root.scale)
                    height: Math.round(440 * root.scale)
                    radius: 14
                    color: root.bgCard

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 5

                        RowLayout {
                            spacing: 6
                            Text { text: "💾"; font.pixelSize: 18 }
                            Text { text: "15GB"; font.pixelSize: 18; font.bold: true; color: root.textWhite }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textMuted; opacity: 0.3 }

                        Repeater {
                            model: [
                                { color: root.accentRed, label: "Documents" },
                                { color: root.accentPurple, label: "Downloads" },
                                { color: root.accentYellow, label: "Music" },
                                { color: root.accentCyan, label: "Pictures" },
                                { color: root.accentCyan, label: "~/.config" },
                                { color: root.accentCyan, label: "~/.local" }
                            ]

                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 6
                                Rectangle { width: 12; height: 12; radius: 2; color: modelData.color }
                                Text { text: modelData.label; font.pixelSize: 11; color: root.accentCyan }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            Text { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 8; text: "Lockscreen - Absolute Positioning (eww-based)"; font.pixelSize: 11; color: root.textMuted }
            Text { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 8; text: "Press ESC to close"; font.pixelSize: 9; color: root.textMuted }
            Shortcut { sequences: ["Escape"]; onActivated: Qt.quit() }
        }
    }

    component ResourceBar: RowLayout {
        id: resBar
        required property color iconColor
        required property color barColor
        required property real value
        spacing: 5
        Rectangle {
            width: 14; height: 14; radius: 2; color: "transparent"; border.width: 1.5; border.color: resBar.iconColor
            Text { anchors.centerIn: parent; text: "⏻"; font.pixelSize: 7; color: resBar.iconColor }
        }
        Rectangle {
            Layout.fillWidth: true; height: 5; radius: 2.5; color: "#2A2F3A"
            Rectangle { width: parent.width * resBar.value; height: parent.height; radius: 2.5; color: resBar.barColor }
        }
    }
}
