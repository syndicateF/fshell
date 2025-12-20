import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Standalone prototype - NO x-shell dependencies
// Run: quickshell -c path/to/power-preview

Scope {
    id: root

    // Theme colors
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
    property color clOnSurface: "#E6E1E5"
    property color clOnSurfaceVariant: "#CAC4D0"
    property color clOutline: "#938F99"
    property color clOutlineVariant: "#49454F"

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: previewWindow
            
            required property var modelData
            screen: modelData
            
            // Center on screen using margins
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
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "power-prototype"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(root.clSurface, 0.97)
                radius: 20
                border.width: 1
                border.color: root.clOutlineVariant

                // Title
                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 16
                    text: "Power Profile Popout - Design Preview"
                    font.pixelSize: 18
                    font.bold: true
                    color: root.clOnSurface
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 12
                    text: "Press ESC to close"
                    font.pixelSize: 12
                    color: root.clOutline
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
                        color: root.clSurfaceContainer
                        border.width: 2
                        border.color: root.clPrimary

                        // Label
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -12
                            width: labelA.width + 16
                            height: 24
                            radius: 12
                            color: root.clPrimaryContainer
                            Text {
                                id: labelA
                                anchors.centerIn: parent
                                text: "A: Unified Card"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.clOnPrimaryContainer
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
                                Text { text: "Power"; font.pixelSize: 14; font.bold: true; color: root.clOnSurface }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 36; height: 20; radius: 10
                                    color: root.clPrimaryContainer
                                    Text { anchors.centerIn: parent; text: "87%"; font.pixelSize: 10; color: root.clOnPrimaryContainer }
                                }
                            }

                            // Profile pills
                            Item {
                                Layout.fillWidth: true
                                height: 40
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    color: root.clSurfaceContainerHigh
                                }
                                
                                Rectangle {
                                    x: 48
                                    width: 40; height: 40
                                    radius: 20
                                    color: root.clPrimary
                                }
                                
                                Row {
                                    anchors.fill: parent
                                    spacing: 4
                                    
                                    Rectangle {
                                        width: 40; height: 40; color: "transparent"
                                        Text { anchors.centerIn: parent; text: "🌿"; font.pixelSize: 16; opacity: 0.6 }
                                    }
                                    Rectangle {
                                        width: 40; height: 40; color: "transparent"
                                        Text { anchors.centerIn: parent; text: "⚖️"; font.pixelSize: 16 }
                                    }
                                    Rectangle {
                                        width: 40; height: 40; color: "transparent"
                                        Text { anchors.centerIn: parent; text: "⚡"; font.pixelSize: 16; opacity: 0.6 }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }

                            // EPP Grid
                            GridLayout {
                                columns: 2
                                rowSpacing: 6
                                columnSpacing: 6
                                Layout.fillWidth: true

                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: 16
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "Performance"; font.pixelSize: 11; color: root.clOnSurfaceVariant }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: 16
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "Bal. Perf"; font.pixelSize: 11; color: root.clOnSurfaceVariant }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: 16
                                    color: root.clSecondaryContainer
                                    Text { anchors.centerIn: parent; text: "Bal. Power"; font.pixelSize: 11; color: root.clOnSecondaryContainer }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: 16
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "Power Saver"; font.pixelSize: 11; color: root.clOnSurfaceVariant }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }

                            // Toggle
                            RowLayout {
                                spacing: 8
                                Text { text: "🔋"; font.pixelSize: 12 }
                                Text { text: "Long Life"; font.pixelSize: 12; color: root.clOnSurfaceVariant }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 40; height: 20; radius: 10
                                    color: root.clSurfaceContainerHigh
                                    Rectangle {
                                        x: 2; y: 2
                                        width: 16; height: 16; radius: 8
                                        color: root.clOutline
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
                        color: root.clSurfaceContainer

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -12
                            width: labelB.width + 16
                            height: 24
                            radius: 12
                            color: root.clSurfaceContainerHigh
                            Text {
                                id: labelB
                                anchors.centerIn: parent
                                text: "B: Compact"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.clOnSurfaceVariant
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
                                Text { text: "🔋 87%"; font.pixelSize: 11; color: root.clOnSurface }
                                Item { Layout.fillWidth: true }
                                Text { text: "Long Life"; font.pixelSize: 10; color: root.clOutline }
                                Rectangle {
                                    width: 32; height: 16; radius: 8
                                    color: root.clSurfaceContainerHigh
                                    Rectangle {
                                        x: 2; y: 2; width: 12; height: 12; radius: 6
                                        color: root.clOutline
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }

                            // Radio-style profiles
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 16
                                
                                Row {
                                    spacing: 4
                                    Text { text: "🌿"; font.pixelSize: 14; opacity: 0.5 }
                                    Rectangle {
                                        width: 10; height: 10; radius: 5
                                        color: "transparent"
                                        border.width: 1; border.color: root.clOutline
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                Row {
                                    spacing: 4
                                    Text { text: "⚖️"; font.pixelSize: 14 }
                                    Rectangle {
                                        width: 10; height: 10; radius: 5
                                        color: root.clPrimary
                                        border.width: 1; border.color: root.clPrimary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                Row {
                                    spacing: 4
                                    Text { text: "⚡"; font.pixelSize: 14; opacity: 0.5 }
                                    Rectangle {
                                        width: 10; height: 10; radius: 5
                                        color: "transparent"
                                        border.width: 1; border.color: root.clOutline
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }

                            // EPP horizontal chips
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4
                                
                                Rectangle {
                                    width: 44; height: 22; radius: 11
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "Perf"; font.pixelSize: 10; color: root.clOnSurfaceVariant }
                                }
                                Rectangle {
                                    width: 44; height: 22; radius: 11
                                    color: root.clSecondaryContainer
                                    Text { anchors.centerIn: parent; text: "Bal"; font.pixelSize: 10; color: root.clOnSecondaryContainer }
                                }
                                Rectangle {
                                    width: 44; height: 22; radius: 11
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "Save"; font.pixelSize: 10; color: root.clOnSurfaceVariant }
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
                        color: root.clSurfaceContainer

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -12
                            width: labelC.width + 16
                            height: 24
                            radius: 12
                            color: root.clSurfaceContainerHigh
                            Text {
                                id: labelC
                                anchors.centerIn: parent
                                text: "C: iOS Sheet"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.clOnSurfaceVariant
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
                                color: root.clOutlineVariant
                            }

                            // Battery card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 10
                                color: root.clSurfaceContainerHigh
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    Text { text: "🔋"; font.pixelSize: 14 }
                                    Text { text: "Battery Health"; font.pixelSize: 12; color: root.clOnSurface; Layout.fillWidth: true }
                                    Text { text: "87%"; font.pixelSize: 12; font.bold: true; color: root.clPrimary }
                                }
                            }

                            // Section header
                            RowLayout {
                                spacing: 6
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                                Text { text: "Platform Profile"; font.pixelSize: 10; color: root.clOutline }
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                            }

                            // Profile list
                            Rectangle {
                                Layout.fillWidth: true
                                height: 120
                                radius: 10
                                color: root.clSurfaceContainerHigh
                                
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 2
                                    
                                    Rectangle {
                                        width: parent.width; height: 36
                                        color: "transparent"; radius: 6
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 8
                                            Text { text: "🌿"; font.pixelSize: 14 }
                                            Text { text: "Low Power"; font.pixelSize: 12; color: root.clOnSurface; Layout.fillWidth: true }
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 36
                                        color: Qt.alpha(root.clPrimary, 0.15); radius: 6
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 8
                                            Text { text: "⚖️"; font.pixelSize: 14 }
                                            Text { text: "Balanced"; font.pixelSize: 12; color: root.clPrimary; Layout.fillWidth: true }
                                            Text { text: "✓"; font.pixelSize: 14; color: root.clPrimary }
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 36
                                        color: "transparent"; radius: 6
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 8
                                            Text { text: "⚡"; font.pixelSize: 14 }
                                            Text { text: "Performance"; font.pixelSize: 12; color: root.clOnSurface; Layout.fillWidth: true }
                                        }
                                    }
                                }
                            }

                            // Section header
                            RowLayout {
                                spacing: 6
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                                Text { text: "Energy Pref"; font.pixelSize: 10; color: root.clOutline }
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                            }

                            // EPP 2x2
                            GridLayout {
                                columns: 2
                                rowSpacing: 4
                                columnSpacing: 4
                                Layout.fillWidth: true

                                Rectangle {
                                    Layout.fillWidth: true; height: 30; radius: 6
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "Default"; font.pixelSize: 10; color: root.clOnSurfaceVariant }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 30; radius: 6
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "Perform"; font.pixelSize: 10; color: root.clOnSurfaceVariant }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 30; radius: 6
                                    color: root.clSecondaryContainer
                                    Text { anchors.centerIn: parent; text: "Bal. Pwr"; font.pixelSize: 10; color: root.clOnSecondaryContainer }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 30; radius: 6
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "Saver"; font.pixelSize: 10; color: root.clOnSurfaceVariant }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Long Life card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 10
                                color: root.clSurfaceContainerHigh
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    Text { text: "🔋"; font.pixelSize: 12 }
                                    Text { text: "Long Life Charging"; font.pixelSize: 11; color: root.clOnSurface; Layout.fillWidth: true }
                                    Rectangle {
                                        width: 36; height: 18; radius: 9
                                        color: root.clSurfaceContainer
                                        Rectangle {
                                            x: 2; y: 2; width: 14; height: 14; radius: 7
                                            color: root.clOutline
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
