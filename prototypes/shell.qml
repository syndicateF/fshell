pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Standalone prototype - NO x-shell dependencies
// Run: quickshell -c /path/to/PowerProfilePrototype.qml

Scope {
    id: root

    // Theme colors (hardcoded for standalone)
    readonly property color surface: "#1C1B1F"
    readonly property color surfaceContainer: "#2B2930"
    readonly property color surfaceContainerHigh: "#36343B"
    readonly property color primary: "#D0BCFF"
    readonly property color onPrimary: "#381E72"
    readonly property color primaryContainer: "#4F378B"
    readonly property color onPrimaryContainer: "#EADDFF"
    readonly property color secondary: "#CCC2DC"
    readonly property color secondaryContainer: "#4A4458"
    readonly property color onSecondaryContainer: "#E8DEF8"
    readonly property color onSurface: "#E6E1E5"
    readonly property color onSurfaceVariant: "#CAC4D0"
    readonly property color outline: "#938F99"
    readonly property color outlineVariant: "#49454F"

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: previewWindow
            
            required property var modelData
            screen: modelData
            
            anchors.centerIn: true
            width: 920
            height: 520
            visible: true
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "power-prototype"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(root.surface, 0.97)
                radius: 20
                border.width: 1
                border.color: root.outlineVariant

                // Title
                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 16
                    text: "Power Profile Popout - Design Preview"
                    font.pixelSize: 18
                    font.bold: true
                    color: root.onSurface
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 12
                    text: "Press ESC to close"
                    font.pixelSize: 12
                    color: root.outline
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 50
                    anchors.topMargin: 60
                    spacing: 24

                    // ==================== OPTION A ====================
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 260
                        radius: 16
                        color: root.surfaceContainer
                        border.width: 2
                        border.color: root.primary

                        // Label
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -12
                            width: labelA.width + 16
                            height: 24
                            radius: 12
                            color: root.primaryContainer
                            Text {
                                id: labelA
                                anchors.centerIn: parent
                                text: "A: Unified Card"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.onPrimaryContainer
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            anchors.topMargin: 20
                            spacing: 10

                            // Header
                            RowLayout {
                                spacing: 8
                                Text { text: "⚡"; font.pixelSize: 16 }
                                Text { text: "Power"; font.pixelSize: 14; font.bold: true; color: root.onSurface }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 36; height: 20; radius: 10
                                    color: root.primaryContainer
                                    Text { anchors.centerIn: parent; text: "87%"; font.pixelSize: 10; color: root.onPrimaryContainer }
                                }
                            }

                            // Profile pills
                            Item {
                                Layout.fillWidth: true
                                height: 40
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    color: root.surfaceContainerHigh
                                }
                                
                                Rectangle {
                                    x: 48
                                    width: 40; height: 40
                                    radius: 20
                                    color: root.primary
                                }
                                
                                Row {
                                    anchors.fill: parent
                                    spacing: 4
                                    Repeater {
                                        model: ["🌿", "⚖️", "⚡"]
                                        Rectangle {
                                            width: 40; height: 40
                                            color: "transparent"
                                            Text {
                                                required property int index
                                                required property string modelData
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.pixelSize: 16
                                                opacity: index === 1 ? 1 : 0.6
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.outlineVariant }

                            // EPP Grid
                            GridLayout {
                                columns: 2
                                rowSpacing: 6
                                columnSpacing: 6
                                Layout.fillWidth: true

                                Repeater {
                                    model: ["Performance", "Bal. Perf", "Bal. Power", "Power Saver"]
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        height: 32
                                        radius: 16
                                        color: index === 2 ? root.secondaryContainer : root.surfaceContainerHigh
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            color: index === 2 ? root.onSecondaryContainer : root.onSurfaceVariant
                                        }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.outlineVariant }

                            // Toggle
                            RowLayout {
                                spacing: 8
                                Text { text: "🔋"; font.pixelSize: 12 }
                                Text { text: "Long Life"; font.pixelSize: 12; color: root.onSurfaceVariant }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 40; height: 20; radius: 10
                                    color: root.surfaceContainerHigh
                                    Rectangle {
                                        x: 2; y: 2
                                        width: 16; height: 16; radius: 8
                                        color: root.outline
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // ==================== OPTION B ====================
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 200
                        radius: 16
                        color: root.surfaceContainer

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -12
                            width: labelB.width + 16
                            height: 24
                            radius: 12
                            color: root.surfaceContainerHigh
                            Text {
                                id: labelB
                                anchors.centerIn: parent
                                text: "B: Compact"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.onSurfaceVariant
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            anchors.topMargin: 20
                            spacing: 8

                            // Battery + toggle
                            RowLayout {
                                spacing: 6
                                Text { text: "🔋 87%"; font.pixelSize: 11; color: root.onSurface }
                                Item { Layout.fillWidth: true }
                                Text { text: "Long Life"; font.pixelSize: 10; color: root.outline }
                                Rectangle {
                                    width: 32; height: 16; radius: 8
                                    color: root.surfaceContainerHigh
                                    Rectangle {
                                        x: 2; y: 2; width: 12; height: 12; radius: 6
                                        color: root.outline
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.outlineVariant }

                            // Radio-style profiles
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 16
                                Repeater {
                                    model: [
                                        { icon: "🌿", active: false },
                                        { icon: "⚖️", active: true },
                                        { icon: "⚡", active: false }
                                    ]
                                    Row {
                                        required property var modelData
                                        spacing: 4
                                        Text { text: modelData.icon; font.pixelSize: 14; opacity: modelData.active ? 1 : 0.5 }
                                        Rectangle {
                                            width: 10; height: 10; radius: 5
                                            color: modelData.active ? root.primary : "transparent"
                                            border.width: 1
                                            border.color: modelData.active ? root.primary : root.outline
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.outlineVariant }

                            // EPP horizontal chips
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4
                                Repeater {
                                    model: ["Perf", "Bal", "Save"]
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        width: chipText.width + 12
                                        height: 22
                                        radius: 11
                                        color: index === 1 ? root.secondaryContainer : root.surfaceContainerHigh
                                        Text {
                                            id: chipText
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 10
                                            color: index === 1 ? root.onSecondaryContainer : root.onSurfaceVariant
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // ==================== OPTION C ====================
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 300
                        radius: 16
                        color: root.surfaceContainer

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -12
                            width: labelC.width + 16
                            height: 24
                            radius: 12
                            color: root.surfaceContainerHigh
                            Text {
                                id: labelC
                                anchors.centerIn: parent
                                text: "C: iOS Sheet"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.onSurfaceVariant
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            anchors.topMargin: 20
                            spacing: 10

                            // Drag handle
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 36; height: 4; radius: 2
                                color: root.outlineVariant
                            }

                            // Battery card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 10
                                color: root.surfaceContainerHigh
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    Text { text: "🔋"; font.pixelSize: 14 }
                                    Text { text: "Battery Health"; font.pixelSize: 12; color: root.onSurface; Layout.fillWidth: true }
                                    Text { text: "87%"; font.pixelSize: 12; font.bold: true; color: root.primary }
                                }
                            }

                            // Section header
                            RowLayout {
                                spacing: 6
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.outlineVariant }
                                Text { text: "Platform Profile"; font.pixelSize: 10; color: root.outline }
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.outlineVariant }
                            }

                            // Profile list
                            Rectangle {
                                Layout.fillWidth: true
                                height: 120
                                radius: 10
                                color: root.surfaceContainerHigh
                                
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 2
                                    Repeater {
                                        model: [
                                            { icon: "🌿", name: "Low Power", active: false },
                                            { icon: "⚖️", name: "Balanced", active: true },
                                            { icon: "⚡", name: "Performance", active: false }
                                        ]
                                        Rectangle {
                                            required property var modelData
                                            width: parent.width
                                            height: 36
                                            color: modelData.active ? Qt.alpha(root.primary, 0.15) : "transparent"
                                            radius: 6
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                Text { text: modelData.icon; font.pixelSize: 14 }
                                                Text { 
                                                    text: modelData.name
                                                    font.pixelSize: 12
                                                    color: modelData.active ? root.primary : root.onSurface
                                                    Layout.fillWidth: true
                                                }
                                                Text {
                                                    text: "✓"
                                                    visible: modelData.active
                                                    font.pixelSize: 14
                                                    color: root.primary
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Section header
                            RowLayout {
                                spacing: 6
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.outlineVariant }
                                Text { text: "Energy Pref"; font.pixelSize: 10; color: root.outline }
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.outlineVariant }
                            }

                            // EPP 2x2
                            GridLayout {
                                columns: 2
                                rowSpacing: 4
                                columnSpacing: 4
                                Layout.fillWidth: true

                                Repeater {
                                    model: ["Default", "Perform", "Bal. Pwr", "Saver"]
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        height: 30
                                        radius: 6
                                        color: index === 2 ? root.secondaryContainer : root.surfaceContainerHigh
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 10
                                            color: index === 2 ? root.onSecondaryContainer : root.onSurfaceVariant
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Long Life card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 10
                                color: root.surfaceContainerHigh
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    Text { text: "🔋"; font.pixelSize: 12 }
                                    Text { text: "Long Life Charging"; font.pixelSize: 11; color: root.onSurface; Layout.fillWidth: true }
                                    Rectangle {
                                        width: 36; height: 18; radius: 9
                                        color: root.surfaceContainer
                                        Rectangle {
                                            x: 2; y: 2; width: 14; height: 14; radius: 7
                                            color: root.outline
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
