import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Performance Popout Preview - System Resources (CPU, GPU, Memory, Storage)
// Run: quickshell -c prototypes/performance-preview

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
    property color m3onErrorContainer: "#F9DEDC"
    property color m3onSurface: "#E6E1E5"
    property color m3onSurfaceVariant: "#CAC4D0"
    property color m3outline: "#938F99"
    property color m3outlineVariant: "#49454F"

    // Simulated system data (akan diganti dengan SystemUsage service)
    property real cpuUsage: 0.72
    property real cpuTemp: 68
    property real gpuUsage: 0.45
    property real gpuTemp: 52
    property real memUsage: 0.78
    property real memUsed: 12.4  // GB
    property real memTotal: 16   // GB
    property real storageUsage: 0.62
    property real storageUsed: 256  // GB
    property real storageTotal: 512 // GB

    // Animation timers untuk demo
    Timer {
        running: true
        repeat: true
        interval: 2000
        onTriggered: {
            root.cpuUsage = 0.3 + Math.random() * 0.5
            root.gpuUsage = 0.2 + Math.random() * 0.4
            root.cpuTemp = 55 + Math.random() * 25
            root.gpuTemp = 45 + Math.random() * 20
            root.memUsage = 0.6 + Math.random() * 0.25
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            
            anchors { top: true; left: true; right: true; bottom: true }
            margins { top: 50; bottom: 50; left: 100; right: 100 }
            visible: true
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "performance-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(root.m3surface, 0.98)
                radius: 24
                border.width: 1
                border.color: root.m3outlineVariant

                // Title
                Column {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 20
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Performance Popout - Design Options"; font.pixelSize: 22; font.bold: true; color: root.m3onSurface }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Choose your preferred style • Press 1-4 to switch"; font.pixelSize: 12; color: root.m3outline }
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 16
                    text: "Press 1/2/3/4 to switch designs • ESC to close"
                    font.pixelSize: 12
                    color: root.m3outline
                }

                // Design previews in row
                Row {
                    anchors.centerIn: parent
                    spacing: 40

                    // ═══════════════════════════════════════════════════
                    // DESIGN 1: Compact Vertical Cards
                    // ═══════════════════════════════════════════════════
                    Column {
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Design 1: Compact Cards"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.m3primary
                        }

                        Rectangle {
                            width: 280
                            height: contentCol1.height + 24
                            radius: 16
                            color: root.m3surfaceContainer
                            border.width: 1
                            border.color: root.m3outlineVariant

                            ColumnLayout {
                                id: contentCol1
                                width: parent.width - 24
                                x: 12; y: 12
                                spacing: 8

                                // Drag handle
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 48; implicitHeight: 12
                                    Rectangle { anchors.centerIn: parent; width: 36; height: 4; radius: 2; color: root.m3outlineVariant }
                                }

                                // Resource cards
                                Repeater {
                                    model: [
                                        { name: "CPU", icon: "🔥", usage: root.cpuUsage, temp: root.cpuTemp, color: root.m3primary },
                                        { name: "GPU", icon: "🎮", usage: root.gpuUsage, temp: root.gpuTemp, color: root.m3secondary },
                                        { name: "Memory", icon: "💾", usage: root.memUsage, value: root.memUsed + "/" + root.memTotal + " GB", color: root.m3tertiary },
                                        { name: "Storage", icon: "💿", usage: root.storageUsage, value: root.storageUsed + "/" + root.storageTotal + " GB", color: root.m3outline }
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true
                                        height: 52
                                        radius: 12
                                        color: root.m3surfaceContainerHigh

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            // Icon
                                            Rectangle {
                                                width: 32; height: 32; radius: 8
                                                color: Qt.alpha(modelData.color, 0.2)
                                                Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 14 }
                                            }

                                            // Labels
                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: modelData.name; font.pixelSize: 12; font.bold: true; color: root.m3onSurface }
                                                
                                                // Progress bar
                                                Rectangle {
                                                    width: 120; height: 4; radius: 2
                                                    color: root.m3surfaceContainerHighest

                                                    Rectangle {
                                                        width: parent.width * modelData.usage
                                                        height: parent.height; radius: 2
                                                        color: modelData.color
                                                        Behavior on width { NumberAnimation { duration: 500 } }
                                                    }
                                                }
                                            }

                                            // Value
                                            Column {
                                                spacing: 0
                                                Text { 
                                                    anchors.right: parent.right
                                                    text: modelData.temp !== undefined ? Math.round(modelData.temp) + "°C" : modelData.value
                                                    font.pixelSize: 11
                                                    color: root.m3onSurfaceVariant
                                                }
                                                Text { 
                                                    anchors.right: parent.right
                                                    text: Math.round(modelData.usage * 100) + "%"
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    color: modelData.color
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // DESIGN 2: Dual Ring Gauges (Stacked)
                    // ═══════════════════════════════════════════════════
                    Column {
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Design 2: Ring Gauges"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.m3secondary
                        }

                        Rectangle {
                            width: 200
                            height: contentCol2.height + 24
                            radius: 16
                            color: root.m3surfaceContainer
                            border.width: 1
                            border.color: root.m3outlineVariant

                            ColumnLayout {
                                id: contentCol2
                                width: parent.width - 24
                                x: 12; y: 12
                                spacing: 12

                                // Drag handle
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 48; implicitHeight: 12
                                    Rectangle { anchors.centerIn: parent; width: 36; height: 4; radius: 2; color: root.m3outlineVariant }
                                }

                                // Ring gauges
                                Repeater {
                                    model: [
                                        { name: "CPU", usage: root.cpuUsage, temp: root.cpuTemp, color: root.m3primary },
                                        { name: "GPU", usage: root.gpuUsage, temp: root.gpuTemp, color: root.m3secondary }
                                    ]

                                    Item {
                                        required property var modelData
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 80; implicitHeight: 80

                                        // Background ring
                                        Canvas {
                                            anchors.fill: parent
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.reset()
                                                ctx.lineWidth = 8
                                                ctx.lineCap = "round"
                                                ctx.strokeStyle = root.m3surfaceContainerHighest
                                                ctx.beginPath()
                                                ctx.arc(40, 40, 32, Math.PI * 0.75, Math.PI * 2.25)
                                                ctx.stroke()
                                            }
                                        }

                                        // Usage ring
                                        Canvas {
                                            id: usageRing
                                            anchors.fill: parent
                                            property real value: modelData.usage
                                            onValueChanged: requestPaint()
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.reset()
                                                ctx.lineWidth = 8
                                                ctx.lineCap = "round"
                                                ctx.strokeStyle = modelData.color
                                                ctx.beginPath()
                                                var startAngle = Math.PI * 0.75
                                                var endAngle = startAngle + (Math.PI * 1.5 * value)
                                                ctx.arc(40, 40, 32, startAngle, endAngle)
                                                ctx.stroke()
                                            }
                                            Behavior on value { NumberAnimation { duration: 500 } }
                                        }

                                        // Center text
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: -2
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: Math.round(modelData.usage * 100) + "%"
                                                font.pixelSize: 14
                                                font.bold: true
                                                color: modelData.color
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: modelData.name
                                                font.pixelSize: 9
                                                color: root.m3outline
                                            }
                                        }

                                        // Temp badge
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottomMargin: -4
                                            width: tempText.width + 8
                                            height: 16
                                            radius: 8
                                            color: root.m3surfaceContainerHigh
                                            Text {
                                                id: tempText
                                                anchors.centerIn: parent
                                                text: Math.round(modelData.temp) + "°"
                                                font.pixelSize: 9
                                                color: root.m3onSurfaceVariant
                                            }
                                        }
                                    }
                                }

                                // Memory & Storage bars
                                Repeater {
                                    model: [
                                        { name: "Memory", usage: root.memUsage, value: root.memUsed.toFixed(1) + "GB", color: root.m3tertiary },
                                        { name: "Storage", usage: root.storageUsage, value: root.storageUsed + "GB", color: root.m3outline }
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: 8
                                        color: root.m3surfaceContainerHigh

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            Text { text: modelData.name; font.pixelSize: 10; color: root.m3onSurfaceVariant }
                                            
                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 4; radius: 2
                                                color: root.m3surfaceContainerHighest
                                                Rectangle {
                                                    width: parent.width * modelData.usage
                                                    height: parent.height; radius: 2
                                                    color: modelData.color
                                                    Behavior on width { NumberAnimation { duration: 500 } }
                                                }
                                            }

                                            Text { text: modelData.value; font.pixelSize: 10; font.bold: true; color: modelData.color }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // DESIGN 3: Minimal Compact
                    // ═══════════════════════════════════════════════════
                    Column {
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Design 3: Minimal"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.m3tertiary
                        }

                        Rectangle {
                            width: 160
                            height: contentCol3.height + 20
                            radius: 16
                            color: root.m3surfaceContainer
                            border.width: 1
                            border.color: root.m3outlineVariant

                            ColumnLayout {
                                id: contentCol3
                                width: parent.width - 20
                                x: 10; y: 10
                                spacing: 6

                                // Compact rows
                                Repeater {
                                    model: [
                                        { icon: "🔥", name: "CPU", value: Math.round(root.cpuUsage * 100) + "%", temp: Math.round(root.cpuTemp) + "°", color: root.m3primary },
                                        { icon: "🎮", name: "GPU", value: Math.round(root.gpuUsage * 100) + "%", temp: Math.round(root.gpuTemp) + "°", color: root.m3secondary },
                                        { icon: "💾", name: "MEM", value: root.memUsed.toFixed(1) + "G", temp: Math.round(root.memUsage * 100) + "%", color: root.m3tertiary },
                                        { icon: "💿", name: "SSD", value: root.storageUsed + "G", temp: Math.round(root.storageUsage * 100) + "%", color: root.m3outline }
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        height: 32
                                        radius: 8
                                        color: root.m3surfaceContainerHigh

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 6

                                            Text { text: modelData.icon; font.pixelSize: 12 }
                                            Text { text: modelData.name; font.pixelSize: 10; color: root.m3onSurfaceVariant; Layout.fillWidth: true }
                                            Text { text: modelData.temp; font.pixelSize: 10; color: root.m3outline }
                                            Text { text: modelData.value; font.pixelSize: 11; font.bold: true; color: modelData.color }
                                        }

                                        // Mini progress at bottom
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.margins: 2
                                            height: 2
                                            radius: 1
                                            color: root.m3surfaceContainerHighest

                                            Rectangle {
                                                width: parent.width * (parseInt(modelData.value) / 100 || root.storageUsage)
                                                height: parent.height
                                                radius: 1
                                                color: Qt.alpha(modelData.color, 0.5)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // DESIGN 4: Grid Layout
                    // ═══════════════════════════════════════════════════
                    Column {
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Design 4: Grid"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.m3error
                        }

                        Rectangle {
                            width: 200
                            height: contentGrid.height + 24
                            radius: 16
                            color: root.m3surfaceContainer
                            border.width: 1
                            border.color: root.m3outlineVariant

                            ColumnLayout {
                                id: contentGrid
                                width: parent.width - 24
                                x: 12; y: 12
                                spacing: 8

                                // Drag handle
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 48; implicitHeight: 12
                                    Rectangle { anchors.centerIn: parent; width: 36; height: 4; radius: 2; color: root.m3outlineVariant }
                                }

                                // 2x2 Grid
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: 8
                                    columnSpacing: 8

                                    Repeater {
                                        model: [
                                            { icon: "🔥", name: "CPU", value: Math.round(root.cpuUsage * 100), sub: Math.round(root.cpuTemp) + "°C", color: root.m3primary },
                                            { icon: "🎮", name: "GPU", value: Math.round(root.gpuUsage * 100), sub: Math.round(root.gpuTemp) + "°C", color: root.m3secondary },
                                            { icon: "💾", name: "RAM", value: Math.round(root.memUsage * 100), sub: root.memUsed.toFixed(1) + "GB", color: root.m3tertiary },
                                            { icon: "💿", name: "SSD", value: Math.round(root.storageUsage * 100), sub: root.storageUsed + "GB", color: root.m3outline }
                                        ]

                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            height: 72
                                            radius: 12
                                            color: root.m3surfaceContainerHigh

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 4

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.icon
                                                    font.pixelSize: 18
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.value + "%"
                                                    font.pixelSize: 16
                                                    font.bold: true
                                                    color: modelData.color
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.sub
                                                    font.pixelSize: 9
                                                    color: root.m3outline
                                                }
                                            }

                                            // Circular progress indicator
                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: 4
                                                radius: 10
                                                color: "transparent"
                                                border.width: 2
                                                border.color: Qt.alpha(modelData.color, 0.3)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Shortcut {
                sequences: ["Escape"]
                onActivated: Qt.quit()
            }
        }
    }
}
