import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Calendar Popout Preview - Timeline + Glassmorphism
// Run: quickshell -c prototypes/calendar-preview
// Press Q or click close button to exit

Scope {
    id: root

    // Theme colors (Material You Dark)
    property color clSurface: "#1C1B1F"
    property color clSurfaceContainer: "#2B2930"
    property color clSurfaceContainerHigh: "#36343B"
    property color clPrimary: "#D0BCFF"
    property color clOnPrimary: "#381E72"
    property color clPrimaryContainer: "#4F378B"
    property color clOnPrimaryContainer: "#EADDFF"
    property color clSecondary: "#CCC2DC"
    property color clSecondaryContainer: "#4A4458"
    property color clOnSecondaryContainer: "#E8DEF8"
    property color clTertiary: "#7DD3C0"
    property color clTertiaryContainer: "#1D4E4A"
    property color clOnTertiaryContainer: "#A2F2DF"
    property color clOnSurface: "#E6E1E5"
    property color clOnSurfaceVariant: "#CAC4D0"
    property color clOutline: "#938F99"
    property color clOutlineVariant: "#49454F"
    property color clYellow: "#E5C76B"
    property color clBlue: "#8AB4F8"
    property color clRed: "#F28B82"

    // Current date info
    readonly property var now: new Date()
    readonly property int currentMonth: now.getMonth()
    readonly property int currentYear: now.getFullYear()
    readonly property int todayDate: now.getDate()

    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function getFirstDayOfMonth(year, month) {
        return new Date(year, month, 1).getDay();
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: previewWindow
            
            required property var modelData
            screen: modelData
            
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            margins.top: 100
            margins.bottom: 100
            margins.left: 200
            margins.right: 200
            
            visible: true
            focusable: true
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "calendar-prototype"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            // Focus on load
            Component.onCompleted: forceActiveFocus()

            // Key handler
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                    Qt.quit();
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(root.clSurface, 0.97)
                radius: 24
                border.width: 1
                border.color: root.clOutlineVariant

                // Title
                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 20
                    text: "Calendar - Timeline Design"
                    font.pixelSize: 18
                    font.bold: true
                    color: root.clOnSurface
                }

                // Close button (top right)
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 16
                    anchors.rightMargin: 20
                    width: 80
                    height: 32
                    radius: 16
                    color: root.clSurfaceContainerHigh

                    Text {
                        anchors.centerIn: parent
                        text: "✕ Close"
                        font.pixelSize: 12
                        color: root.clOnSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 16
                    text: "Press Q or ESC to close"
                    font.pixelSize: 12
                    color: root.clOutline
                }

                // Design container
                Item {
                    anchors.centerIn: parent
                    width: 320
                    height: 560

                    // Main card background with gradient
                    Rectangle {
                        anchors.fill: parent
                        radius: 28
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.alpha(root.clPrimaryContainer, 0.2) }
                            GradientStop { position: 0.5; color: root.clSurfaceContainer }
                            GradientStop { position: 1.0; color: root.clSurfaceContainer }
                        }
                        border.width: 1
                        border.color: Qt.alpha(root.clOnSurface, 0.08)
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        // ═══════════════════════════════════════════════════
                        // DATE HERO (Timeline style)
                        // ═══════════════════════════════════════════════════
                        Row {
                            width: parent.width
                            spacing: 16

                            // Big date number
                            Column {
                                spacing: -4

                                Text {
                                    text: root.todayDate
                                    font.pixelSize: 72
                                    font.weight: Font.Bold
                                    color: root.clPrimary
                                }

                                Text {
                                    text: Qt.locale().monthName(root.currentMonth).substring(0, 3).toUpperCase()
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.letterSpacing: 4
                                    color: root.clOutline
                                }
                            }

                            // Weather + time column
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Text {
                                    text: Qt.formatTime(root.now, "hh:mm")
                                    font.pixelSize: 28
                                    font.weight: Font.Light
                                    color: root.clOnSurface
                                }

                                // Weather badge
                                Rectangle {
                                    width: weatherRow.width + 16
                                    height: 28
                                    radius: 14
                                    color: Qt.alpha(root.clYellow, 0.15)

                                    Row {
                                        id: weatherRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: "☀️"
                                            font.pixelSize: 14
                                        }

                                        Text {
                                            text: "28°C"
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: root.clYellow
                                        }
                                    }
                                }

                                Text {
                                    text: Qt.formatDate(root.now, "dddd")
                                    font.pixelSize: 13
                                    color: root.clOnSurfaceVariant
                                }
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // WEEK VIEW STRIP
                        // ═══════════════════════════════════════════════════
                        Row {
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: 7

                                Rectangle {
                                    readonly property int dayOffset: index - 3
                                    readonly property int dayNum: {
                                        const d = new Date();
                                        d.setDate(d.getDate() + dayOffset);
                                        return d.getDate();
                                    }
                                    readonly property bool isToday: dayOffset === 0

                                    width: (parent.width - 24) / 7
                                    height: 56
                                    radius: 12
                                    color: isToday ? root.clPrimary : Qt.alpha(root.clSurfaceContainerHigh, 0.7)
                                    border.width: isToday ? 0 : 1
                                    border.color: Qt.alpha(root.clOnSurface, 0.05)

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: {
                                                const d = new Date();
                                                d.setDate(d.getDate() + dayOffset);
                                                return Qt.locale().dayName(d.getDay()).substring(0, 1);
                                            }
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: isToday ? root.clOnPrimary : root.clOutline
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: dayNum
                                            font.pixelSize: 16
                                            font.weight: isToday ? Font.Bold : Font.Normal
                                            color: isToday ? root.clOnPrimary : root.clOnSurface
                                        }
                                    }
                                }
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // SCHEDULE SECTION (Glassmorphism style)
                        // ═══════════════════════════════════════════════════
                        Item {
                            width: parent.width
                            height: parent.height - 200

                            Column {
                                anchors.fill: parent
                                spacing: 10

                                Text {
                                    text: "TODAY"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 2
                                    color: root.clOutline
                                }

                                // Event 1 - Glassmorphism card
                                Rectangle {
                                    width: parent.width
                                    height: 64
                                    radius: 16
                                    color: Qt.alpha(root.clSurfaceContainerHigh, 0.6)
                                    border.width: 1
                                    border.color: Qt.alpha(root.clOnSurface, 0.08)

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12

                                        Rectangle {
                                            width: 4
                                            height: parent.height
                                            radius: 2
                                            color: root.clBlue
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Text {
                                                text: "Morning Standup"
                                                font.pixelSize: 14
                                                font.weight: Font.Medium
                                                color: root.clOnSurface
                                            }

                                            Row {
                                                spacing: 8

                                                Text {
                                                    text: "9:00 AM"
                                                    font.pixelSize: 12
                                                    color: root.clBlue
                                                }

                                                Text {
                                                    text: "• 15 min"
                                                    font.pixelSize: 12
                                                    color: root.clOutline
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            text: "🎥"
                                            font.pixelSize: 20
                                        }
                                    }
                                }

                                // Event 2 - Glassmorphism card
                                Rectangle {
                                    width: parent.width
                                    height: 64
                                    radius: 16
                                    color: Qt.alpha(root.clTertiaryContainer, 0.4)
                                    border.width: 1
                                    border.color: Qt.alpha(root.clTertiary, 0.2)

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12

                                        Rectangle {
                                            width: 4
                                            height: parent.height
                                            radius: 2
                                            color: root.clTertiary
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Text {
                                                text: "Design Review"
                                                font.pixelSize: 14
                                                font.weight: Font.Medium
                                                color: root.clOnSurface
                                            }

                                            Row {
                                                spacing: 8

                                                Text {
                                                    text: "2:00 PM"
                                                    font.pixelSize: 12
                                                    color: root.clTertiary
                                                }

                                                Text {
                                                    text: "• 1 hour"
                                                    font.pixelSize: 12
                                                    color: root.clOutline
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            text: "👥"
                                            font.pixelSize: 20
                                        }
                                    }
                                }

                                // Event 3 - Glassmorphism card
                                Rectangle {
                                    width: parent.width
                                    height: 64
                                    radius: 16
                                    color: Qt.alpha(root.clYellow, 0.1)
                                    border.width: 1
                                    border.color: Qt.alpha(root.clYellow, 0.2)

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12

                                        Rectangle {
                                            width: 4
                                            height: parent.height
                                            radius: 2
                                            color: root.clYellow
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Text {
                                                text: "Gym Session"
                                                font.pixelSize: 14
                                                font.weight: Font.Medium
                                                color: root.clOnSurface
                                            }

                                            Row {
                                                spacing: 8

                                                Text {
                                                    text: "6:00 PM"
                                                    font.pixelSize: 12
                                                    color: root.clYellow
                                                }

                                                Text {
                                                    text: "• 1.5 hours"
                                                    font.pixelSize: 12
                                                    color: root.clOutline
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            text: "💪"
                                            font.pixelSize: 20
                                        }
                                    }
                                }

                                // Add event button
                                Rectangle {
                                    width: parent.width
                                    height: 44
                                    radius: 12
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Qt.alpha(root.clPrimary, 0.3)

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            text: "+"
                                            font.pixelSize: 18
                                            font.weight: Font.Light
                                            color: root.clPrimary
                                        }

                                        Text {
                                            text: "Add Event"
                                            font.pixelSize: 13
                                            color: root.clPrimary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
