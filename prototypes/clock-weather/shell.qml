import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Clock + Weather - Multiple Style Variants
// Run: quickshell -p prototypes/clock-weather/shell.qml
// Press 1,2,3,4 to switch styles, Q/ESC to exit

Scope {
    id: root

    // Theme - Tokyo Night
    property color bgDark: "#1a1b26"
    property color bgContainer: "#24283b"
    property color accent: "#7dcfff"
    property color textPrimary: "#c0caf5"
    property color textMuted: "#565f89"

    // Time
    property var now: new Date()
    property string hour: Qt.formatTime(now, "hh")
    property string minute: Qt.formatTime(now, "mm")
    property string day: Qt.formatDate(now, "dd")
    property string month: Qt.formatDate(now, "MM")
    
    // Weather mock
    property int temp: 24

    // Current style (1-4)
    property int currentStyle: 1

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            
            anchors { top: true; left: true; right: true; bottom: true }
            margins { top: 80; bottom: 80; left: 150; right: 150 }
            
            visible: true
            focusable: true
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "clock-proto"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) Qt.quit()
                if (event.key === Qt.Key_1) root.currentStyle = 1
                if (event.key === Qt.Key_2) root.currentStyle = 2
                if (event.key === Qt.Key_3) root.currentStyle = 3
                if (event.key === Qt.Key_4) root.currentStyle = 4
            }

            Rectangle {
                anchors.fill: parent
                color: root.bgDark
                radius: 16

                // Header
                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 16
                    text: "Press 1-4 to switch styles | Q to quit"
                    font.pixelSize: 12
                    color: root.textMuted
                }

                // Style indicator
                Row {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 40
                    spacing: 12

                    Repeater {
                        model: 4
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 6
                            color: (index + 1) === root.currentStyle ? root.accent : root.bgContainer
                            Text {
                                anchors.centerIn: parent
                                text: index + 1
                                font.pixelSize: 12
                                font.bold: true
                                color: (index + 1) === root.currentStyle ? root.bgDark : root.textMuted
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentStyle = index + 1
                            }
                        }
                    }
                }

                // Clock widgets row
                Row {
                    anchors.centerIn: parent
                    spacing: 80

                    // ═══════════════════════════════════════════════════════════
                    // STYLE 1: Clean Stacked (Simple, elegant)
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        spacing: 8
                        visible: root.currentStyle === 1

                        Text { 
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "STYLE 1: Clean Stacked"
                            font.pixelSize: 10
                            color: root.textMuted
                        }

                        Rectangle {
                            width: 44
                            height: col1.height + 20
                            radius: 10
                            color: root.bgContainer

                            Column {
                                id: col1
                                anchors.centerIn: parent
                                spacing: 2

                                // Hour
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.hour
                                    font.pixelSize: 22
                                    font.weight: Font.Light
                                    color: root.accent
                                }
                                // Minute
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.minute
                                    font.pixelSize: 22
                                    font.weight: Font.Light
                                    color: root.textPrimary
                                }

                                // Simple line
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 24
                                    height: 1
                                    color: root.textMuted
                                }

                                // Date inline
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.day + "/" + root.month
                                    font.pixelSize: 9
                                    color: root.textMuted
                                }

                                // Spacer
                                Item { width: 1; height: 4 }

                                // Weather simple
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.temp + "°"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: root.accent
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════
                    // STYLE 2: Compact Mono (Monospace, technical)
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        spacing: 8
                        visible: root.currentStyle === 2

                        Text { 
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "STYLE 2: Compact Mono"
                            font.pixelSize: 10
                            color: root.textMuted
                        }

                        Rectangle {
                            width: 44
                            height: col2.height + 16
                            radius: 8
                            color: root.bgContainer

                            Column {
                                id: col2
                                anchors.centerIn: parent
                                spacing: 6

                                // Time as single column
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: -2

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.hour
                                        font.pixelSize: 18
                                        font.family: "monospace"
                                        font.weight: Font.Bold
                                        color: root.textPrimary
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: ":"
                                        font.pixelSize: 10
                                        font.family: "monospace"
                                        color: root.accent
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.minute
                                        font.pixelSize: 18
                                        font.family: "monospace"
                                        font.weight: Font.Bold
                                        color: root.textPrimary
                                    }
                                }

                                // Date compact
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2
                                    Text {
                                        text: root.day
                                        font.pixelSize: 9
                                        font.family: "monospace"
                                        color: root.textMuted
                                    }
                                    Text {
                                        text: "·"
                                        font.pixelSize: 9
                                        color: root.accent
                                    }
                                    Text {
                                        text: root.month
                                        font.pixelSize: 9
                                        font.family: "monospace"
                                        color: root.textMuted
                                    }
                                }

                                // Weather
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.temp + "°C"
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    color: root.accent
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════
                    // STYLE 3: Pill Segments (Each element in pill)
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        spacing: 8
                        visible: root.currentStyle === 3

                        Text { 
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "STYLE 3: Pill Segments"
                            font.pixelSize: 10
                            color: root.textMuted
                        }

                        Column {
                            spacing: 4

                            // Hour pill
                            Rectangle {
                                width: 44
                                height: 32
                                radius: 8
                                color: root.bgContainer

                                Text {
                                    anchors.centerIn: parent
                                    text: root.hour
                                    font.pixelSize: 18
                                    font.weight: Font.Medium
                                    color: root.accent
                                }
                            }

                            // Minute pill
                            Rectangle {
                                width: 44
                                height: 32
                                radius: 8
                                color: root.bgContainer

                                Text {
                                    anchors.centerIn: parent
                                    text: root.minute
                                    font.pixelSize: 18
                                    font.weight: Font.Medium
                                    color: root.textPrimary
                                }
                            }

                            // Date pill (smaller)
                            Rectangle {
                                width: 44
                                height: 22
                                radius: 6
                                color: root.bgContainer

                                Text {
                                    anchors.centerIn: parent
                                    text: root.day + "/" + root.month
                                    font.pixelSize: 10
                                    color: root.textMuted
                                }
                            }

                            // Weather pill
                            Rectangle {
                                width: 44
                                height: 26
                                radius: 6
                                color: root.bgContainer

                                Text {
                                    anchors.centerIn: parent
                                    text: "☀ " + root.temp + "°"
                                    font.pixelSize: 10
                                    color: root.accent
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════
                    // STYLE 4: Ultra Minimal (Just essentials)
                    // ═══════════════════════════════════════════════════════════
                    Column {
                        spacing: 8
                        visible: root.currentStyle === 4

                        Text { 
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "STYLE 4: Ultra Minimal"
                            font.pixelSize: 10
                            color: root.textMuted
                        }

                        Rectangle {
                            width: 40
                            height: col4.height + 12
                            radius: 6
                            color: "transparent"
                            border.width: 1
                            border.color: root.textMuted

                            Column {
                                id: col4
                                anchors.centerIn: parent
                                spacing: 0

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.hour
                                    font.pixelSize: 16
                                    font.weight: Font.ExtraLight
                                    color: root.textPrimary
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.minute
                                    font.pixelSize: 16
                                    font.weight: Font.ExtraLight
                                    color: root.textPrimary
                                }
                                
                                Item { width: 1; height: 4 }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.day
                                    font.pixelSize: 10
                                    color: root.textMuted
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.month
                                    font.pixelSize: 10
                                    color: root.textMuted
                                }

                                Item { width: 1; height: 4 }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.temp + "°"
                                    font.pixelSize: 10
                                    color: root.accent
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
