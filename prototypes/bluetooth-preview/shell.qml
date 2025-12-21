import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Bluetooth Popout Preview - Standalone prototype
// Run: quickshell -c path/to/bluetooth-preview

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
    property color clError: "#F2B8B5"
    property color clErrorContainer: "#8C1D18"

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
            margins.top: 80
            margins.bottom: 80
            margins.left: 100
            margins.right: 100
            
            visible: true
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "bluetooth-prototype"
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
                    text: "Bluetooth Popout - Design Concepts"
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
                    anchors.margins: 40
                    anchors.topMargin: 60
                    spacing: 24

                    // ==================== OPTION A: Minimal ====================
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 260
                        radius: 16
                        color: root.clSurfaceContainer

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -12
                            width: labelA.width + 16
                            height: 24
                            radius: 12
                            color: root.clSurfaceContainerHigh
                            Text {
                                id: labelA
                                anchors.centerIn: parent
                                text: "A: Minimal"
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

                            // Status card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 50
                                radius: 10
                                color: root.clSurfaceContainerHigh
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    
                                    Text { text: "📶"; font.pixelSize: 18 }
                                    Text { text: "Bluetooth"; font.pixelSize: 13; font.bold: true; color: root.clOnSurface }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 44; height: 24; radius: 12
                                        color: root.clPrimary
                                        Rectangle {
                                            x: parent.width - 22; y: 2
                                            width: 20; height: 20; radius: 10
                                            color: root.clOnPrimary
                                        }
                                    }
                                }
                            }

                            // Devices header
                            RowLayout {
                                spacing: 6
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                                Text { text: "3 devices"; font.pixelSize: 10; color: root.clOutline }
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                            }

                            // Device list
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 10
                                color: root.clSurfaceContainerHigh
                                
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 2

                                    // Connected device
                                    Rectangle {
                                        width: parent.width; height: 40
                                        color: Qt.alpha(root.clPrimary, 0.15); radius: 6
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 8
                                            Text { text: "🎧"; font.pixelSize: 14 }
                                            Text { text: "AirPods Pro"; font.pixelSize: 12; color: root.clPrimary; Layout.fillWidth: true }
                                            Text { text: "🔋85%"; font.pixelSize: 10; color: root.clPrimary }
                                            Rectangle { width: 24; height: 24; radius: 12; color: root.clPrimary
                                                Text { anchors.centerIn: parent; text: "🔗"; font.pixelSize: 10 }
                                            }
                                        }
                                    }

                                    // Paired device
                                    Rectangle {
                                        width: parent.width; height: 40
                                        color: "transparent"; radius: 6
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 8
                                            Text { text: "⌨️"; font.pixelSize: 14 }
                                            Text { text: "Magic Keyboard"; font.pixelSize: 12; color: root.clOnSurface; Layout.fillWidth: true }
                                            Rectangle { width: 24; height: 24; radius: 12; color: "transparent"; border.width: 1; border.color: root.clOutline
                                                Text { anchors.centerIn: parent; text: "🔗"; font.pixelSize: 10; color: root.clOutline }
                                            }
                                        }
                                    }

                                    // Available device
                                    Rectangle {
                                        width: parent.width; height: 40
                                        color: "transparent"; radius: 6
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 8
                                            Text { text: "🖱️"; font.pixelSize: 14; opacity: 0.6 }
                                            Text { text: "Unknown Mouse"; font.pixelSize: 12; color: root.clOnSurfaceVariant; Layout.fillWidth: true }
                                            Rectangle { width: 24; height: 24; radius: 12; color: "transparent"; border.width: 1; border.color: root.clOutlineVariant
                                                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 12; color: root.clOutlineVariant }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // ==================== OPTION B: Feature Rich ====================
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 300
                        radius: 16
                        color: root.clSurfaceContainer
                        border.width: 2
                        border.color: root.clPrimary

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -12
                            width: labelB.width + 16
                            height: 24
                            radius: 12
                            color: root.clPrimaryContainer
                            Text {
                                id: labelB
                                anchors.centerIn: parent
                                text: "B: Feature Rich"
                                font.pixelSize: 11
                                font.bold: true
                                color: root.clOnPrimaryContainer
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            anchors.topMargin: 20
                            spacing: 8

                            // Drag handle
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 36; height: 4; radius: 2
                                color: root.clOutlineVariant
                            }

                            // Status card with more info
                            Rectangle {
                                Layout.fillWidth: true
                                height: 70
                                radius: 10
                                color: root.clSurfaceContainerHigh
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6
                                    
                                    RowLayout {
                                        Text { text: "📶"; font.pixelSize: 18 }
                                        ColumnLayout {
                                            spacing: 0
                                            Text { text: "Bluetooth"; font.pixelSize: 13; font.bold: true; color: root.clOnSurface }
                                            Text { text: "1 connected • 2 paired"; font.pixelSize: 10; color: root.clOutline }
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            width: 44; height: 24; radius: 12
                                            color: root.clPrimary
                                            Rectangle {
                                                x: parent.width - 22; y: 2
                                                width: 20; height: 20; radius: 10
                                                color: root.clOnPrimary
                                            }
                                        }
                                    }
                                    
                                    RowLayout {
                                        spacing: 8
                                        Rectangle {
                                            width: scanLabel.width + 16; height: 24; radius: 12
                                            color: root.clTertiaryContainer
                                            Text { id: scanLabel; anchors.centerIn: parent; text: "🔍 Scanning..."; font.pixelSize: 10; color: root.clOnTertiaryContainer }
                                        }
                                        Rectangle {
                                            width: visLabel.width + 16; height: 24; radius: 12
                                            color: root.clSecondaryContainer
                                            Text { id: visLabel; anchors.centerIn: parent; text: "👁 Visible"; font.pixelSize: 10; color: root.clOnSecondaryContainer }
                                        }
                                    }
                                }
                            }

                            // Quick actions
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                
                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: 8
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "🔍 Scan"; font.pixelSize: 11; color: root.clOnSurfaceVariant }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: 8
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "➕ Pair"; font.pixelSize: 11; color: root.clOnSurfaceVariant }
                                }
                            }

                            // Connected section
                            RowLayout {
                                spacing: 6
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                                Text { text: "Connected"; font.pixelSize: 10; color: root.clPrimary }
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 56
                                radius: 10
                                color: Qt.alpha(root.clPrimary, 0.1)
                                border.width: 1
                                border.color: Qt.alpha(root.clPrimary, 0.3)
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10
                                    spacing: 10
                                    
                                    Rectangle {
                                        width: 36; height: 36; radius: 8
                                        color: root.clPrimaryContainer
                                        Text { anchors.centerIn: parent; text: "🎧"; font.pixelSize: 18 }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text { text: "AirPods Pro"; font.pixelSize: 12; font.bold: true; color: root.clPrimary }
                                        RowLayout {
                                            spacing: 8
                                            Text { text: "🔋 L: 85%"; font.pixelSize: 9; color: root.clOutline }
                                            Text { text: "🔋 R: 82%"; font.pixelSize: 9; color: root.clOutline }
                                            Text { text: "📦 90%"; font.pixelSize: 9; color: root.clOutline }
                                        }
                                    }
                                    
                                    Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: root.clPrimary
                                        Text { anchors.centerIn: parent; text: "⏸"; font.pixelSize: 12 }
                                    }
                                }
                            }

                            // Paired section
                            RowLayout {
                                spacing: 6
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                                Text { text: "Paired"; font.pixelSize: 10; color: root.clOutline }
                                Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 80
                                radius: 10
                                color: root.clSurfaceContainerHigh
                                
                                Column {
                                    anchors.fill: parent; anchors.margins: 6
                                    spacing: 2
                                    
                                    Rectangle {
                                        width: parent.width; height: 36
                                        color: "transparent"; radius: 6
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 8
                                            Text { text: "⌨️"; font.pixelSize: 12 }
                                            Text { text: "Magic Keyboard"; font.pixelSize: 11; color: root.clOnSurface; Layout.fillWidth: true }
                                            Text { text: "🗑"; font.pixelSize: 12; color: root.clError }
                                            Rectangle { width: 22; height: 22; radius: 11; color: "transparent"; border.width: 1; border.color: root.clOutline
                                                Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 8; color: root.clOutline }
                                            }
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 36
                                        color: "transparent"; radius: 6
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 8
                                            Text { text: "🖱️"; font.pixelSize: 12 }
                                            Text { text: "MX Master 3"; font.pixelSize: 11; color: root.clOnSurface; Layout.fillWidth: true }
                                            Text { text: "🗑"; font.pixelSize: 12; color: root.clError }
                                            Rectangle { width: 22; height: 22; radius: 11; color: "transparent"; border.width: 1; border.color: root.clOutline
                                                Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 8; color: root.clOutline }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // ==================== OPTION C: Compact ====================
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 220
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
                                text: "C: Compact"
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

                            // Drag handle
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 36; height: 4; radius: 2
                                color: root.clOutlineVariant
                            }

                            // Compact header
                            RowLayout {
                                spacing: 8
                                Text { text: "📶"; font.pixelSize: 16 }
                                Text { text: "Bluetooth"; font.pixelSize: 12; font.bold: true; color: root.clOnSurface }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 36; height: 20; radius: 10
                                    color: root.clPrimary
                                    Rectangle {
                                        x: parent.width - 18; y: 2
                                        width: 16; height: 16; radius: 8
                                        color: root.clOnPrimary
                                    }
                                }
                            }

                            // Inline scan toggle
                            RowLayout {
                                spacing: 6
                                Text { text: "🔍"; font.pixelSize: 12 }
                                Text { text: "Scan"; font.pixelSize: 11; color: root.clOnSurfaceVariant }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 32; height: 16; radius: 8
                                    color: root.clTertiaryContainer
                                    Rectangle {
                                        x: parent.width - 14; y: 2
                                        width: 12; height: 12; radius: 6
                                        color: root.clTertiary
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }

                            // Ultra compact device list
                            Column {
                                Layout.fillWidth: true
                                spacing: 4

                                // Connected
                                RowLayout {
                                    width: parent.width
                                    spacing: 6
                                    Rectangle { width: 6; height: 6; radius: 3; color: root.clPrimary }
                                    Text { text: "🎧 AirPods Pro"; font.pixelSize: 11; color: root.clPrimary; Layout.fillWidth: true }
                                    Text { text: "85%"; font.pixelSize: 10; color: root.clPrimary }
                                }

                                // Paired
                                RowLayout {
                                    width: parent.width
                                    spacing: 6
                                    Rectangle { width: 6; height: 6; radius: 3; color: root.clOutline }
                                    Text { text: "⌨️ Magic Keyboard"; font.pixelSize: 11; color: root.clOnSurfaceVariant; Layout.fillWidth: true }
                                }

                                // Paired
                                RowLayout {
                                    width: parent.width
                                    spacing: 6
                                    Rectangle { width: 6; height: 6; radius: 3; color: root.clOutline }
                                    Text { text: "🖱️ MX Master 3"; font.pixelSize: 11; color: root.clOnSurfaceVariant; Layout.fillWidth: true }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Quick action row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; radius: 6
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "➕"; font.pixelSize: 12 }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; radius: 6
                                    color: root.clSurfaceContainerHigh
                                    Text { anchors.centerIn: parent; text: "⚙️"; font.pixelSize: 12 }
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
