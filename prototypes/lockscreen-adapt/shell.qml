import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Lockscreen Adaptation v2 - Battery Bar + Wide Notifications
// Run: quickshell -p prototypes/lockscreen-adapt
// 
// Changes from v1:
// - Quick Info removed
// - Battery bar added below Media (horizontal)
// - Notifications expanded to fill Column 3+4 area

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
    property color accentOrange: "#E57C46"
    property color accentBlue: "#61AFEF"
    property color accentPeach: "#E5A07B"
    
    property color textWhite: "#FFFFFF"
    property color textGray: "#8B919D"
    property color textMuted: "#5C6370"

    property real scale: 0.45
    property int gap: Math.round(15 * scale)

    property string passwordDots: "●●●●●●"
    property bool passwordFocused: true

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: previewWindow
            
            required property var modelData
            screen: modelData
            
            anchors { top: true; left: true; right: true; bottom: true }
            visible: true
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "lockscreen-adapt"
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

            Item {
                id: container
                anchors.centerIn: parent
                width: Math.round(1620 * root.scale)
                height: Math.round(780 * root.scale)

                // ═══════════════════════════════════════════════════
                // COLUMN 1: Profile + Password | Stats
                // ═══════════════════════════════════════════════════

                // PROFILE + PASSWORD
                Rectangle {
                    x: 0
                    y: 0
                    width: Math.round(350 * root.scale)
                    height: Math.round(440 * root.scale)
                    radius: 14
                    color: root.bgCardDark

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Item { Layout.preferredHeight: 8 }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 65; height: 65
                            radius: 32.5
                            color: "#1E2128"
                            border.width: 2
                            border.color: root.accentPink
                            
                            Text { anchors.centerIn: parent; text: "🌙"; font.pixelSize: 24; opacity: 0.5 }
                        }

                        Text { Layout.alignment: Qt.AlignHCenter; text: "Aditya Shakya"; font.pixelSize: 12; font.bold: true; color: root.accentPink }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "@adi1090x"; font.pixelSize: 9; color: root.textMuted }

                        Item { Layout.preferredHeight: 10 }

                        // Password Input
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            Layout.margins: 8
                            radius: 20
                            color: "#2A2F3A"
                            border.width: root.passwordFocused ? 2 : 0
                            border.color: root.accentPink

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text { text: "🔒"; font.pixelSize: 14; color: root.accentPink }
                                Text { Layout.fillWidth: true; text: root.passwordDots; font.pixelSize: 16; font.letterSpacing: 4; color: root.textWhite; horizontalAlignment: Text.AlignHCenter }
                                Text { text: "👆"; font.pixelSize: 14; color: root.accentCyan }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Rectangle {
                                width: capsText.width + 12; height: 18; radius: 9
                                color: root.accentYellow

                                Text { id: capsText; anchors.centerIn: parent; text: "CAPS"; font.pixelSize: 8; font.bold: true; color: "#1E2128" }
                            }

                            Text { text: "🌐 us"; font.pixelSize: 10; color: root.textMuted }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // STATS
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

                        Text { text: "⚙ Resources"; font.pixelSize: 10; color: root.textMuted }

                        ResourceBar { Layout.fillWidth: true; label: "CPU"; iconColor: root.accentPink; barColor: root.accentPink; value: 0.35 }
                        ResourceBar { Layout.fillWidth: true; label: "RAM"; iconColor: root.accentGreen; barColor: root.accentGreen; value: 0.62 }
                        ResourceBar { Layout.fillWidth: true; label: "TMP"; iconColor: root.accentYellow; barColor: root.accentYellow; value: 0.45 }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ═══════════════════════════════════════════════════
                // COLUMN 2: Clock | Uptime | Music | Battery Bar
                // ═══════════════════════════════════════════════════

                // CLOCK
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

                // UPTIME
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

                // MUSIC (smaller now, battery bar below)
                Rectangle {
                    x: Math.round(365 * root.scale)
                    y: Math.round(340 * root.scale)
                    width: Math.round(610 * root.scale)
                    height: Math.round(280 * root.scale) // Original height
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

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                height: 4
                                radius: 2
                                color: "#2A2F3A"

                                Rectangle {
                                    width: parent.width * 0.35
                                    height: parent.height
                                    radius: 2
                                    color: root.accentPeach
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "1:23"; font.pixelSize: 9; color: root.textMuted }
                                Item { Layout.fillWidth: true }
                                Text { text: "3:58"; font.pixelSize: 9; color: root.textMuted }
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 6
                                spacing: 20
                                Text { text: "⏮"; font.pixelSize: 14; color: root.textGray }
                                Rectangle {
                                    width: 32; height: 32; radius: 16; color: root.textWhite
                                    Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 12; color: root.bgCard }
                                }
                                Text { text: "⏭"; font.pixelSize: 14; color: root.textGray }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                // BATTERY BAR (new - below Music)
                Rectangle {
                    x: Math.round(365 * root.scale)
                    y: Math.round(635 * root.scale) // Below music
                    width: Math.round(610 * root.scale) // Same width as music
                    height: Math.round(145 * root.scale)
                    radius: 14
                    color: root.bgCard

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        // Battery icon
                        Rectangle {
                            width: 50; height: 50
                            radius: 25
                            color: root.accentGreen
                            opacity: 0.2

                            Text {
                                anchors.centerIn: parent
                                text: "🔋"
                                font.pixelSize: 24
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "85%"
                                    font.pixelSize: 22
                                    font.bold: true
                                    color: root.accentGreen
                                }

                                Text {
                                    text: "⚡ Charging"
                                    font.pixelSize: 11
                                    color: root.accentYellow
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "~45 min to full"
                                    font.pixelSize: 10
                                    color: root.textMuted
                                }
                            }

                            // Battery progress bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: "#2A2F3A"

                                Rectangle {
                                    width: parent.width * 0.85
                                    height: parent.height
                                    radius: 4
                                    
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: root.accentGreen }
                                        GradientStop { position: 1.0; color: root.accentYellow }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Text { text: "🔌 AC Power"; font.pixelSize: 9; color: root.textMuted }
                                Text { text: "•"; font.pixelSize: 9; color: root.textMuted }
                                Text { text: "Health: 92%"; font.pixelSize: 9; color: root.accentCyan }
                                Item { Layout.fillWidth: true }
                                Text { text: "45W"; font.pixelSize: 9; color: root.textMuted }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════
                // COLUMN 3: Weather | NOTIFICATIONS (wide - merged col 3+4)
                // ═══════════════════════════════════════════════════

                // WEATHER
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

                // NOTIFICATIONS (wider - takes col 3 + col 4 space)
                Rectangle {
                    x: Math.round(990 * root.scale)
                    y: Math.round(340 * root.scale)
                    width: Math.round(630 * root.scale) // 290 + 15 + 325 = ~630
                    height: Math.round(440 * root.scale)
                    radius: 14
                    color: root.bgCard

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "🔔"; font.pixelSize: 16 }
                            Text { text: "Notifications"; font.pixelSize: 14; font.bold: true; color: root.textWhite }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: countText.width + 10; height: 20; radius: 10
                                color: root.accentPurple

                                Text { id: countText; anchors.centerIn: parent; text: "5"; font.pixelSize: 11; font.bold: true; color: root.textWhite }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textMuted; opacity: 0.3 }

                        // Notification items (larger with more details)
                        Repeater {
                            model: [
                                { app: "Discord", icon: "💬", summary: "New message from @archivist", body: "Did you check the latest commit?", color: "#5865F2", time: "2m ago" },
                                { app: "Telegram", icon: "✈", summary: "Photo from John", body: "Check out this sunset photo", color: "#28A8E8", time: "5m ago" },
                                { app: "Email", icon: "✉", summary: "Meeting reminder", body: "Team sync in 30 minutes", color: "#EA4335", time: "15m ago" },
                                { app: "System", icon: "⚙", summary: "Update available", body: "linux-zen 6.12.4 ready to install", color: "#5DDE85", time: "1h ago" },
                                { app: "Calendar", icon: "📅", summary: "Upcoming event", body: "Dinner with friends at 8 PM", color: "#E5C07B", time: "30m" }
                            ]

                            Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: 10
                                color: index === 0 ? Qt.rgba(255,255,255,0.05) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    Rectangle {
                                        width: 36; height: 36; radius: 8
                                        color: modelData.color

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            font.pixelSize: 16
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: modelData.app; font.pixelSize: 11; font.bold: true; color: root.textWhite }
                                            Item { Layout.fillWidth: true }
                                            Text { text: modelData.time; font.pixelSize: 9; color: root.textMuted }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.summary
                                            font.pixelSize: 10
                                            color: root.textGray
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.body
                                            font.pixelSize: 9
                                            color: root.textMuted
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Clear all
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 16
                            color: Qt.rgba(255,255,255,0.08)

                            Text { anchors.centerIn: parent; text: "Clear All Notifications"; font.pixelSize: 11; color: root.textMuted }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════
                // COLUMN 4: Power 2x2 only (no Quick Info)
                // ═══════════════════════════════════════════════════

                // POWER GRID (2x2)
                Grid {
                    x: Math.round(1295 * root.scale)
                    y: 0
                    columns: 2
                    spacing: root.gap

                    Repeater {
                        model: [
                            { icon: "⇥", label: "Logout", color: root.accentPink },
                            { icon: "💤", label: "Sleep", color: root.accentGreen },
                            { icon: "🔄", label: "Reboot", color: root.accentCyan },
                            { icon: "⏻", label: "Power", color: root.accentRed }
                        ]

                        Rectangle {
                            required property var modelData
                            width: Math.round(155 * root.scale)
                            height: Math.round(155 * root.scale)
                            radius: 14
                            color: root.bgCard

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.icon; font.pixelSize: 22; color: modelData.color }
                                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.label; font.pixelSize: 8; color: root.textMuted }
                            }
                        }
                    }
                }
            }

            Text { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 8; text: "Lockscreen v2 - Battery Bar + Wide Notifications"; font.pixelSize: 11; color: root.textMuted }
            Text { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 8; text: "Press ESC to close"; font.pixelSize: 9; color: root.textMuted }
            Shortcut { sequences: ["Escape"]; onActivated: Qt.quit() }
        }
    }

    component ResourceBar: RowLayout {
        id: resBar
        required property string label
        required property color iconColor
        required property color barColor
        required property real value
        spacing: 6

        Rectangle {
            width: 14; height: 14; radius: 2
            color: "transparent"; border.width: 1.5; border.color: resBar.iconColor
            Text { anchors.centerIn: parent; text: "⏻"; font.pixelSize: 7; color: resBar.iconColor }
        }

        Text { text: resBar.label; font.pixelSize: 9; color: root.textMuted; Layout.preferredWidth: 25 }

        Rectangle {
            Layout.fillWidth: true; height: 5; radius: 2.5; color: "#2A2F3A"
            Rectangle { width: parent.width * resBar.value; height: parent.height; radius: 2.5; color: resBar.barColor }
        }

        Text { text: Math.round(resBar.value * 100) + "%"; font.pixelSize: 8; color: resBar.iconColor; Layout.preferredWidth: 25 }
    }
}
