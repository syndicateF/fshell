import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

// Calendar Popup Preview - 5 Design Concepts
// Run: quickshell -c prototypes/calendar-popup
// Press 1-5 to switch between designs, ESC to close

Scope {
    id: root

    // Material You Dark Theme
    property color m3surface: "#1C1B1F"
    property color m3surfaceContainer: "#2B2930"
    property color m3surfaceContainerHigh: "#36343B"
    property color m3surfaceContainerHighest: "#48464C"
    property color m3primary: "#D0BCFF"
    property color m3onPrimary: "#381E72"
    property color m3primaryContainer: "#4F378B"
    property color m3onPrimaryContainer: "#EADDFF"
    property color m3secondary: "#CCC2DC"
    property color m3secondaryContainer: "#4A4458"
    property color m3onSecondaryContainer: "#E8DEF8"
    property color m3tertiary: "#7DD3C0"
    property color m3tertiaryContainer: "#1F4D44"
    property color m3onTertiaryContainer: "#A4F4DC"
    property color m3error: "#F2B8B5"
    property color m3errorContainer: "#8C1D18"
    property color m3onSurface: "#E6E1E5"
    property color m3onSurfaceVariant: "#CAC4D0"
    property color m3outline: "#938F99"
    property color m3outlineVariant: "#49454F"

    // Current design selection (1-5)
    property int currentDesign: 1

    // Simulated data
    property string currentTime: "08:48"
    property string currentDate: "Sunday, 22 December 2024"
    property string weatherIcon: "☀️"
    property string weatherTemp: "28°C"
    property string weatherDesc: "Sunny"
    property int currentDay: 22
    property int currentMonth: 12
    property string monthName: "December 2024"

    // Days of week
    property var daysOfWeek: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // Calendar grid (simplified December 2024)
    property var calendarDays: [
        { day: 0, prevMonth: true },  // Sun placeholder
        { day: 0, prevMonth: true },  // Mon placeholder
        { day: 0, prevMonth: true },  // Tue placeholder
        { day: 0, prevMonth: true },  // Wed placeholder
        { day: 0, prevMonth: true },  // Thu placeholder
        { day: 0, prevMonth: true },  // Fri placeholder
        { day: 1, prevMonth: false },
        { day: 2, prevMonth: false },
        { day: 3, prevMonth: false },
        { day: 4, prevMonth: false },
        { day: 5, prevMonth: false },
        { day: 6, prevMonth: false },
        { day: 7, prevMonth: false },
        { day: 8, prevMonth: false },
        { day: 9, prevMonth: false },
        { day: 10, prevMonth: false },
        { day: 11, prevMonth: false },
        { day: 12, prevMonth: false },
        { day: 13, prevMonth: false },
        { day: 14, prevMonth: false },
        { day: 15, prevMonth: false },
        { day: 16, prevMonth: false },
        { day: 17, prevMonth: false },
        { day: 18, prevMonth: false },
        { day: 19, prevMonth: false },
        { day: 20, prevMonth: false },
        { day: 21, prevMonth: false },
        { day: 22, prevMonth: false },
        { day: 23, prevMonth: false },
        { day: 24, prevMonth: false },
        { day: 25, prevMonth: false },
        { day: 26, prevMonth: false },
        { day: 27, prevMonth: false },
        { day: 28, prevMonth: false },
        { day: 29, prevMonth: false },
        { day: 30, prevMonth: false },
        { day: 31, prevMonth: false }
    ]

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true; bottom: true }
            margins { top: 60; bottom: 60; left: 80; right: 80 }
            visible: true

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "calendar-popup-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(root.m3surface, 0.98)
                radius: 24
                border.width: 1
                border.color: root.m3outlineVariant

                // Title bar
                Column {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 16
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Calendar Popup - 5 Design Concepts"
                        font.pixelSize: 22
                        font.bold: true
                        color: root.m3onSurface
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Press 1-5 to switch designs • Current: Design " + root.currentDesign
                        font.pixelSize: 12
                        color: root.m3outline
                    }
                }

                // Footer
                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 12
                    text: "ESC to close • Design " + root.currentDesign + " of 5"
                    font.pixelSize: 11
                    color: root.m3outline
                }

                // Design tabs
                Row {
                    anchors.top: parent.top
                    anchors.topMargin: 60
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 1, name: "Glass Dock" },
                            { idx: 2, name: "Split Panel" },
                            { idx: 3, name: "Card Stack" },
                            { idx: 4, name: "Timeline" },
                            { idx: 5, name: "Compact" }
                        ]

                        Rectangle {
                            required property var modelData

                            width: tabLabel.width + 24
                            height: 32
                            radius: 16
                            color: root.currentDesign === modelData.idx
                                ? root.m3primaryContainer
                                : root.m3surfaceContainerHigh

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData.idx + ". " + modelData.name
                                font.pixelSize: 11
                                font.bold: root.currentDesign === modelData.idx
                                color: root.currentDesign === modelData.idx
                                    ? root.m3onPrimaryContainer
                                    : root.m3onSurfaceVariant
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentDesign = modelData.idx
                            }
                        }
                    }
                }

                // Main preview area
                Item {
                    anchors.fill: parent
                    anchors.topMargin: 110
                    anchors.bottomMargin: 50
                    anchors.leftMargin: 40
                    anchors.rightMargin: 40

                    // ═══════════════════════════════════════════════════
                    // DESIGN 1: Glass Dock Style
                    // Minimalist vertical dengan weather header subtle
                    // ═══════════════════════════════════════════════════
                    Rectangle {
                        id: design1
                        visible: root.currentDesign === 1
                        anchors.centerIn: parent
                        width: 320
                        height: contentD1.height + 28
                        radius: 20
                        color: Qt.alpha(root.m3surfaceContainer, 0.95)
                        border.width: 1
                        border.color: Qt.alpha(root.m3outline, 0.2)

                        layer.enabled: true
                        layer.effect: DropShadow {
                            transparentBorder: true
                            radius: 24
                            samples: 49
                            color: Qt.alpha("#000000", 0.4)
                        }

                        ColumnLayout {
                            id: contentD1
                            width: parent.width - 28
                            x: 14; y: 14
                            spacing: 12

                            // Weather header - subtle gradient
                            Rectangle {
                                Layout.fillWidth: true
                                height: 60
                                radius: 14
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.alpha(root.m3primary, 0.15) }
                                    GradientStop { position: 1.0; color: Qt.alpha(root.m3primary, 0.05) }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    // Animated weather icon
                                    Item {
                                        width: 40; height: 40

                                        Text {
                                            id: weatherIconD1
                                            anchors.centerIn: parent
                                            text: root.weatherIcon
                                            font.pixelSize: 28

                                            SequentialAnimation on scale {
                                                running: true
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 1.1; duration: 2000; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                                            }
                                        }
                                    }

                                    Column {
                                        spacing: 0
                                        Text {
                                            text: root.weatherTemp
                                            font.pixelSize: 18
                                            font.bold: true
                                            color: root.m3primary
                                        }
                                        Text {
                                            text: root.weatherDesc
                                            font.pixelSize: 11
                                            color: root.m3onSurfaceVariant
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Column {
                                        spacing: 0
                                        Text {
                                            anchors.right: parent.right
                                            text: root.currentTime
                                            font.pixelSize: 16
                                            font.bold: true
                                            color: root.m3onSurface
                                        }
                                        Text {
                                            anchors.right: parent.right
                                            text: "Today"
                                            font.pixelSize: 10
                                            color: root.m3outline
                                        }
                                    }
                                }
                            }

                            // Month navigation
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: root.m3surfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 16; color: root.m3tertiary }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: root.monthName
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: root.m3primary
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: root.m3surfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 16; color: root.m3tertiary }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                                }
                            }

                            // Days of week header
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4

                                Repeater {
                                    model: root.daysOfWeek
                                    Text {
                                        required property string modelData
                                        required property int index
                                        width: 36; height: 24
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: (index >= 5) ? root.m3secondary : root.m3outline
                                    }
                                }
                            }

                            // Calendar grid
                            Grid {
                                Layout.alignment: Qt.AlignHCenter
                                columns: 7
                                spacing: 4

                                Repeater {
                                    model: root.calendarDays

                                    Rectangle {
                                        required property var modelData
                                        required property int index

                                        property bool isToday: modelData.day === root.currentDay && !modelData.prevMonth
                                        property bool isWeekend: (index % 7) >= 5

                                        width: 36; height: 36
                                        radius: 18
                                        color: isToday ? root.m3primary
                                            : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day > 0 ? modelData.day : ""
                                            font.pixelSize: 12
                                            font.bold: isToday
                                            color: isToday ? root.m3onPrimary
                                                : modelData.prevMonth ? Qt.alpha(root.m3outline, 0.4)
                                                : isWeekend ? root.m3secondary
                                                : root.m3onSurface
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: modelData.day > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            hoverEnabled: true
                                            onEntered: if (!parent.isToday && modelData.day > 0) parent.color = Qt.alpha(root.m3primary, 0.2)
                                            onExited: if (!parent.isToday) parent.color = "transparent"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // DESIGN 2: Split Panel
                    // Calendar kiri, Weather + Info kanan
                    // ═══════════════════════════════════════════════════
                    Rectangle {
                        id: design2
                        visible: root.currentDesign === 2
                        anchors.centerIn: parent
                        width: 500
                        height: 380
                        radius: 20
                        color: root.m3surfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14

                            // Left: Calendar
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: root.m3surfaceContainerHigh

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    // Month nav
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Rectangle {
                                            width: 24; height: 24; radius: 12
                                            color: root.m3surfaceContainer
                                            Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 14; color: root.m3tertiary }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: root.monthName
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: root.m3primary
                                        }

                                        Rectangle {
                                            width: 24; height: 24; radius: 12
                                            color: root.m3surfaceContainer
                                            Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 14; color: root.m3tertiary }
                                        }
                                    }

                                    // Days header
                                    Row {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 2
                                        Repeater {
                                            model: root.daysOfWeek
                                            Text {
                                                required property string modelData
                                                required property int index
                                                width: 32; height: 20
                                                horizontalAlignment: Text.AlignHCenter
                                                text: modelData.substring(0, 2)
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: (index >= 5) ? root.m3secondary : root.m3outline
                                            }
                                        }
                                    }

                                    // Grid
                                    Grid {
                                        Layout.alignment: Qt.AlignHCenter
                                        columns: 7
                                        spacing: 2

                                        Repeater {
                                            model: root.calendarDays
                                            Rectangle {
                                                required property var modelData
                                                required property int index
                                                property bool isToday: modelData.day === root.currentDay && !modelData.prevMonth

                                                width: 32; height: 32; radius: 16
                                                color: isToday ? root.m3primary : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.day > 0 ? modelData.day : ""
                                                    font.pixelSize: 11
                                                    color: isToday ? root.m3onPrimary
                                                        : modelData.prevMonth ? Qt.alpha(root.m3outline, 0.3)
                                                        : root.m3onSurface
                                                }
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }
                                }
                            }

                            // Right: Weather + Info
                            ColumnLayout {
                                Layout.preferredWidth: 150
                                Layout.fillHeight: true
                                spacing: 10

                                // Weather card
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 140
                                    radius: 14
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: root.m3tertiaryContainer }
                                        GradientStop { position: 1.0; color: Qt.alpha(root.m3tertiaryContainer, 0.6) }
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.weatherIcon
                                            font.pixelSize: 40

                                            SequentialAnimation on rotation {
                                                running: true
                                                loops: Animation.Infinite
                                                NumberAnimation { to: -5; duration: 3000; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: 5; duration: 3000; easing.type: Easing.InOutSine }
                                            }
                                        }

                                        Column {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 2
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.weatherTemp
                                                font.pixelSize: 22
                                                font.bold: true
                                                color: root.m3onTertiaryContainer
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.weatherDesc
                                                font.pixelSize: 11
                                                color: root.m3onTertiaryContainer
                                            }
                                        }
                                    }
                                }

                                // Time card
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    radius: 14
                                    color: root.m3surfaceContainerHigh

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.currentTime
                                            font.pixelSize: 28
                                            font.bold: true
                                            color: root.m3primary
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "Sunday"
                                            font.pixelSize: 11
                                            color: root.m3outline
                                        }
                                    }
                                }

                                // Quick info
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 14
                                    color: root.m3surfaceContainerHigh

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8

                                        Row {
                                            spacing: 6
                                            Text { text: "🌅"; font.pixelSize: 12 }
                                            Text { text: "06:12"; font.pixelSize: 11; color: root.m3onSurfaceVariant }
                                        }
                                        Row {
                                            spacing: 6
                                            Text { text: "🌇"; font.pixelSize: 12 }
                                            Text { text: "17:48"; font.pixelSize: 11; color: root.m3onSurfaceVariant }
                                        }
                                        Row {
                                            spacing: 6
                                            Text { text: "💧"; font.pixelSize: 12 }
                                            Text { text: "65%"; font.pixelSize: 11; color: root.m3onSurfaceVariant }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // DESIGN 3: Card Stack
                    // Calendar main, Weather floating overlay
                    // ═══════════════════════════════════════════════════
                    Item {
                        id: design3
                        visible: root.currentDesign === 3
                        anchors.centerIn: parent
                        width: 360
                        height: 440

                        // Main calendar card
                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 30
                            radius: 20
                            color: root.m3surfaceContainer

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                anchors.topMargin: 40
                                spacing: 12

                                // Date display
                                Column {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 2

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.currentDay
                                        font.pixelSize: 48
                                        font.bold: true
                                        color: root.m3primary
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.monthName
                                        font.pixelSize: 14
                                        color: root.m3onSurfaceVariant
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: root.m3outlineVariant }

                                // Month nav
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 20
                                    Layout.rightMargin: 20

                                    Text { text: "‹"; font.pixelSize: 18; color: root.m3tertiary }
                                    Item { Layout.fillWidth: true }
                                    Text { text: root.monthName; font.pixelSize: 13; font.bold: true; color: root.m3onSurface }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "›"; font.pixelSize: 18; color: root.m3tertiary }
                                }

                                // Days header
                                Row {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6
                                    Repeater {
                                        model: root.daysOfWeek
                                        Text {
                                            required property string modelData
                                            required property int index
                                            width: 38; height: 20
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.substring(0, 1)
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: (index >= 5) ? root.m3secondary : root.m3outline
                                        }
                                    }
                                }

                                // Grid
                                Grid {
                                    Layout.alignment: Qt.AlignHCenter
                                    columns: 7
                                    spacing: 6

                                    Repeater {
                                        model: root.calendarDays
                                        Rectangle {
                                            required property var modelData
                                            required property int index
                                            property bool isToday: modelData.day === root.currentDay && !modelData.prevMonth

                                            width: 38; height: 38; radius: 19
                                            color: isToday ? root.m3primary : "transparent"
                                            border.width: modelData.day === 25 && !modelData.prevMonth ? 2 : 0
                                            border.color: root.m3secondary

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.day > 0 ? modelData.day : ""
                                                font.pixelSize: 12
                                                font.bold: isToday
                                                color: isToday ? root.m3onPrimary
                                                    : modelData.prevMonth ? Qt.alpha(root.m3outline, 0.3)
                                                    : root.m3onSurface
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }

                        // Floating weather card (overlay)
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.rightMargin: -20
                            width: 120
                            height: 100
                            radius: 16
                            color: root.m3primaryContainer

                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                radius: 16
                                samples: 33
                                color: Qt.alpha("#000000", 0.3)
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.weatherIcon
                                    font.pixelSize: 32
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.weatherTemp
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: root.m3onPrimaryContainer
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.weatherDesc
                                    font.pixelSize: 10
                                    color: root.m3onPrimaryContainer
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // DESIGN 4: Unified Timeline
                    // Weather integrated ke header, seamless flow
                    // ═══════════════════════════════════════════════════
                    Rectangle {
                        id: design4
                        visible: root.currentDesign === 4
                        anchors.centerIn: parent
                        width: 340
                        height: contentD4.height + 24
                        radius: 20
                        color: root.m3surfaceContainer

                        ColumnLayout {
                            id: contentD4
                            width: parent.width - 24
                            x: 12; y: 12
                            spacing: 0

                            // Unified header - time + weather
                            Rectangle {
                                Layout.fillWidth: true
                                height: 100
                                radius: 14
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: root.m3primaryContainer }
                                    GradientStop { position: 1.0; color: root.m3tertiaryContainer }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 0

                                    // Left: Time
                                    Column {
                                        spacing: 0
                                        Text {
                                            text: root.currentTime
                                            font.pixelSize: 36
                                            font.bold: true
                                            color: root.m3onPrimaryContainer
                                        }
                                        Text {
                                            text: "Sunday, Dec 22"
                                            font.pixelSize: 12
                                            color: root.m3onPrimaryContainer
                                            opacity: 0.8
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Vertical divider
                                    Rectangle {
                                        width: 1
                                        height: 50
                                        color: Qt.alpha(root.m3onPrimaryContainer, 0.3)
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Right: Weather
                                    Row {
                                        spacing: 10

                                        Text {
                                            text: root.weatherIcon
                                            font.pixelSize: 32
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Column {
                                            spacing: 0
                                            Text {
                                                text: root.weatherTemp
                                                font.pixelSize: 20
                                                font.bold: true
                                                color: root.m3onTertiaryContainer
                                            }
                                            Text {
                                                text: root.weatherDesc
                                                font.pixelSize: 10
                                                color: root.m3onTertiaryContainer
                                                opacity: 0.8
                                            }
                                        }
                                    }
                                }
                            }

                            // Timeline connector
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 2
                                height: 16
                                color: root.m3outline
                            }

                            // Calendar section
                            Rectangle {
                                Layout.fillWidth: true
                                height: calContent.height + 16
                                radius: 14
                                color: root.m3surfaceContainerHigh

                                ColumnLayout {
                                    id: calContent
                                    width: parent.width - 16
                                    x: 8; y: 8
                                    spacing: 8

                                    // Month nav
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "‹"; font.pixelSize: 16; color: root.m3tertiary }
                                        Item { Layout.fillWidth: true }
                                        Text { text: root.monthName; font.pixelSize: 12; font.bold: true; color: root.m3onSurface }
                                        Item { Layout.fillWidth: true }
                                        Text { text: "›"; font.pixelSize: 16; color: root.m3tertiary }
                                    }

                                    // Days header
                                    Row {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 3
                                        Repeater {
                                            model: root.daysOfWeek
                                            Text {
                                                required property string modelData
                                                required property int index
                                                width: 38; height: 18
                                                horizontalAlignment: Text.AlignHCenter
                                                text: modelData.substring(0, 2)
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: (index >= 5) ? root.m3secondary : root.m3outline
                                            }
                                        }
                                    }

                                    // Grid
                                    Grid {
                                        Layout.alignment: Qt.AlignHCenter
                                        columns: 7
                                        spacing: 3

                                        Repeater {
                                            model: root.calendarDays
                                            Rectangle {
                                                required property var modelData
                                                required property int index
                                                property bool isToday: modelData.day === root.currentDay && !modelData.prevMonth

                                                width: 38; height: 34; radius: 8
                                                color: isToday ? root.m3primary : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.day > 0 ? modelData.day : ""
                                                    font.pixelSize: 11
                                                    color: isToday ? root.m3onPrimary
                                                        : modelData.prevMonth ? Qt.alpha(root.m3outline, 0.3)
                                                        : root.m3onSurface
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // DESIGN 5: Compact Dock
                    // Mirip macOS menu bar dropdown
                    // ═══════════════════════════════════════════════════
                    Rectangle {
                        id: design5
                        visible: root.currentDesign === 5
                        anchors.centerIn: parent
                        width: 280
                        height: contentD5.height + 20
                        radius: 14
                        color: root.m3surfaceContainer
                        border.width: 1
                        border.color: root.m3outlineVariant

                        ColumnLayout {
                            id: contentD5
                            width: parent.width - 20
                            x: 10; y: 10
                            spacing: 8

                            // Compact header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // Weather mini
                                Row {
                                    spacing: 6
                                    Text { text: root.weatherIcon; font.pixelSize: 16 }
                                    Text { text: root.weatherTemp; font.pixelSize: 12; font.bold: true; color: root.m3primary }
                                }

                                Item { Layout.fillWidth: true }

                                // Time mini
                                Row {
                                    spacing: 4
                                    Text { text: "🕐"; font.pixelSize: 12 }
                                    Text { text: root.currentTime; font.pixelSize: 12; color: root.m3onSurfaceVariant }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.m3outlineVariant }

                            // Month nav - extra compact
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "◀"; font.pixelSize: 10; color: root.m3tertiary }
                                Item { Layout.fillWidth: true }
                                Text { text: root.monthName; font.pixelSize: 11; font.bold: true; color: root.m3onSurface }
                                Item { Layout.fillWidth: true }
                                Text { text: "▶"; font.pixelSize: 10; color: root.m3tertiary }
                            }

                            // Days header - ultra compact
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 0
                                Repeater {
                                    model: root.daysOfWeek
                                    Text {
                                        required property string modelData
                                        required property int index
                                        width: 34; height: 16
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.substring(0, 1)
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: (index >= 5) ? root.m3secondary : root.m3outline
                                    }
                                }
                            }

                            // Grid - compact
                            Grid {
                                Layout.alignment: Qt.AlignHCenter
                                columns: 7
                                spacing: 2

                                Repeater {
                                    model: root.calendarDays
                                    Rectangle {
                                        required property var modelData
                                        required property int index
                                        property bool isToday: modelData.day === root.currentDay && !modelData.prevMonth

                                        width: 32; height: 28; radius: 6
                                        color: isToday ? root.m3primary : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day > 0 ? modelData.day : ""
                                            font.pixelSize: 10
                                            color: isToday ? root.m3onPrimary
                                                : modelData.prevMonth ? Qt.alpha(root.m3outline, 0.3)
                                                : root.m3onSurface
                                        }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.m3outlineVariant }

                            // Quick actions row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28; radius: 6
                                    color: root.m3surfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "📅 Events"; font.pixelSize: 10; color: root.m3onSurfaceVariant }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28; radius: 6
                                    color: root.m3surfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "⏰ Reminders"; font.pixelSize: 10; color: root.m3onSurfaceVariant }
                                }
                            }
                        }
                    }
                }
            }

            // Keyboard shortcuts
            Shortcut {
                sequences: ["Escape"]
                onActivated: Qt.quit()
            }
            Shortcut {
                sequence: "1"
                onActivated: root.currentDesign = 1
            }
            Shortcut {
                sequence: "2"
                onActivated: root.currentDesign = 2
            }
            Shortcut {
                sequence: "3"
                onActivated: root.currentDesign = 3
            }
            Shortcut {
                sequence: "4"
                onActivated: root.currentDesign = 4
            }
            Shortcut {
                sequence: "5"
                onActivated: root.currentDesign = 5
            }
        }
    }
}
