import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// PowerProfile iOS Sheet Preview - Exactly like Bluetooth/Network
// Run: quickshell -c prototypes/powerprofile-v2

Scope {
    id: root

    // Material You Dark Theme (from x-shell)
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

    // Simulated Power state
    property string platformProfile: "balanced"
    property string epp: "balance_performance"
    property bool longLifeEnabled: false
    property bool isBusy: false
    property bool safeModeActive: false
    property int batteryPercent: 87
    property int healthPercent: 95
    property bool isCharging: true
    
    property var availableProfiles: ["low-power", "balanced", "performance"]
    property var availableEpp: ["default", "performance", "balance_performance", "balance_power", "power"]

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            
            anchors { top: true; left: true; right: true; bottom: true }
            margins { top: 100; bottom: 100; left: 200; right: 200 }
            visible: true
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "power-ios-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(root.m3surface, 0.98)
                radius: 24
                border.width: 1
                border.color: root.m3outlineVariant

                Column {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 20
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "PowerProfile - iOS Sheet Style"; font.pixelSize: 22; font.bold: true; color: root.m3onSurface }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Matching Bluetooth/Network Popout Style"; font.pixelSize: 12; color: root.m3outline }
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 16
                    text: "Click to interact • ESC to close"
                    font.pixelSize: 12
                    color: root.m3outline
                }

                // Main preview - recreating exactly the popout style
                Rectangle {
                    anchors.centerIn: parent
                    width: 300
                    height: contentCol.height + 24
                    radius: 16
                    color: root.m3surfaceContainer
                    border.width: 1
                    border.color: root.m3outlineVariant

                    ColumnLayout {
                        id: contentCol
                        width: parent.width - 24
                        x: 12; y: 12
                        spacing: 8

                        // ═══════════════════════════════════════════════════
                        // iOS Drag Handle
                        // ═══════════════════════════════════════════════════
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 48
                            implicitHeight: 16

                            Rectangle {
                                anchors.centerIn: parent
                                width: 36; height: 4; radius: 2
                                color: root.m3outlineVariant
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // Status Card (like Bluetooth/Network)
                        // ═══════════════════════════════════════════════════
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: statusContent.height + 20
                            radius: 12
                            color: root.m3surfaceContainerHigh

                            ColumnLayout {
                                id: statusContent
                                width: parent.width - 20
                                x: 10; y: 10
                                spacing: 8

                                // Header row
                                RowLayout {
                                    width: parent.width
                                    spacing: 10

                                    // Icon circle
                                    Rectangle {
                                        width: 32; height: 32
                                        radius: 8
                                        color: root.isCharging 
                                            ? Qt.alpha(root.m3primary, 0.2) 
                                            : Qt.alpha(root.m3tertiary, 0.2)

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.isCharging ? "⚡" : "🔋"
                                            font.pixelSize: 14
                                        }
                                    }

                                    Column {
                                        spacing: 0
                                        Text {
                                            text: "Power"
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: root.m3onSurface
                                        }
                                        Text {
                                            text: root.batteryPercent + "% • " + (root.isCharging ? "Charging" : "On battery")
                                            font.pixelSize: 10
                                            color: root.m3outline
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Health badge
                                    Rectangle {
                                        width: healthText.width + 12
                                        height: 22
                                        radius: 11
                                        color: root.healthPercent >= 80 
                                            ? Qt.alpha(root.m3primary, 0.2)
                                            : Qt.alpha(root.m3tertiary, 0.2)

                                        Text {
                                            id: healthText
                                            anchors.centerIn: parent
                                            text: root.healthPercent + "%"
                                            font.pixelSize: 10
                                            color: root.healthPercent >= 80 ? root.m3primary : root.m3tertiary
                                        }
                                    }
                                }

                                // Battery progress bar
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.m3surfaceContainerHighest

                                    Rectangle {
                                        width: parent.width * (root.batteryPercent / 100)
                                        height: parent.height
                                        radius: 3
                                        color: root.isCharging ? root.m3primary : root.m3tertiary
                                        Behavior on width { NumberAnimation { duration: 300 } }
                                    }
                                }
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // Profile Section Header (like Bluetooth device sections)
                        // ═══════════════════════════════════════════════════
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.m3outlineVariant }
                            Text { 
                                text: {
                                    switch (root.platformProfile) {
                                        case "low-power": return "Power Saver"
                                        case "balanced": return "Balanced"
                                        case "performance": return "Performance"
                                        default: return root.platformProfile
                                    }
                                }
                                font.pixelSize: 10
                                font.bold: true
                                color: root.m3outline
                            }
                            Rectangle { Layout.fillWidth: true; height: 1; color: root.m3outlineVariant }
                        }

                        // ═══════════════════════════════════════════════════
                        // Profile Cards (like Bluetooth device list)
                        // ═══════════════════════════════════════════════════
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: profileCol.height + 12
                            radius: 12
                            color: root.m3surfaceContainerHigh

                            Column {
                                id: profileCol
                                width: parent.width - 12
                                x: 6; y: 6
                                spacing: 2

                                Repeater {
                                    model: [
                                        { id: "low-power", name: "Power Saver", icon: "eco", desc: "Extend battery life" },
                                        { id: "balanced", name: "Balanced", icon: "balance", desc: "Optimal performance" },
                                        { id: "performance", name: "Performance", icon: "bolt", desc: "Maximum power" }
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        required property int index

                                        width: parent.width
                                        height: 48
                                        radius: 8
                                        color: root.platformProfile === modelData.id
                                            ? Qt.alpha(root.m3primary, 0.15)
                                            : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            // Icon with background
                                            Rectangle {
                                                width: 28; height: 28
                                                radius: 8
                                                color: root.platformProfile === modelData.id
                                                    ? root.m3primaryContainer
                                                    : root.m3surfaceContainerHighest

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon === "eco" ? "🌿" 
                                                        : modelData.icon === "balance" ? "⚖️" : "⚡"
                                                    font.pixelSize: 12
                                                }
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 0
                                                Text {
                                                    text: modelData.name
                                                    font.pixelSize: 12
                                                    font.bold: root.platformProfile === modelData.id
                                                    color: root.platformProfile === modelData.id 
                                                        ? root.m3primary 
                                                        : root.m3onSurface
                                                }
                                                Text {
                                                    text: modelData.desc
                                                    font.pixelSize: 9
                                                    color: root.m3outline
                                                }
                                            }

                                            // Checkmark for active
                                            Rectangle {
                                                visible: root.platformProfile === modelData.id
                                                width: 20; height: 20
                                                radius: 10
                                                color: root.m3primary

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✓"
                                                    font.pixelSize: 10
                                                    color: root.m3onPrimary
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.platformProfile = modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // EPP Section Header
                        // ═══════════════════════════════════════════════════
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.m3outlineVariant }
                            Text { text: "Energy Preference"; font.pixelSize: 10; font.bold: true; color: root.m3outline }
                            Rectangle { Layout.fillWidth: true; height: 1; color: root.m3outlineVariant }
                        }

                        // ═══════════════════════════════════════════════════
                        // EPP Grid (2 columns)
                        // ═══════════════════════════════════════════════════
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 4

                            Repeater {
                                model: [
                                    { id: "default", name: "Default", icon: "settings_suggest" },
                                    { id: "performance", name: "Performance", icon: "bolt" },
                                    { id: "balance_performance", name: "Bal. Perf", icon: "speed" },
                                    { id: "balance_power", name: "Bal. Power", icon: "eco" },
                                    { id: "power", name: "Power Saver", icon: "battery_saver" }
                                ]

                                Rectangle {
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 8
                                    color: root.epp === modelData.id
                                        ? root.m3secondaryContainer
                                        : root.m3surfaceContainerHigh

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: modelData.icon === "settings_suggest" ? "⚙️"
                                                : modelData.icon === "bolt" ? "⚡"
                                                : modelData.icon === "speed" ? "🚀"
                                                : modelData.icon === "eco" ? "🌿"
                                                : "🔋"
                                            font.pixelSize: 10
                                        }

                                        Text {
                                            text: modelData.name
                                            font.pixelSize: 10
                                            color: root.epp === modelData.id
                                                ? root.m3onSecondaryContainer
                                                : root.m3onSurfaceVariant
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.epp = modelData.id
                                    }
                                }
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // Long Life Toggle Card (like Bluetooth quick actions)
                        // ═══════════════════════════════════════════════════
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 12
                            color: root.longLifeEnabled 
                                ? Qt.alpha(root.m3primary, 0.1)
                                : root.m3surfaceContainerHigh
                            border.width: root.longLifeEnabled ? 1 : 0
                            border.color: Qt.alpha(root.m3primary, 0.3)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Rectangle {
                                    width: 28; height: 28
                                    radius: 8
                                    color: root.longLifeEnabled 
                                        ? root.m3tertiaryContainer 
                                        : root.m3surfaceContainerHighest

                                    Text {
                                        anchors.centerIn: parent
                                        text: "🔋"
                                        font.pixelSize: 12
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text { text: "Long Life Mode"; font.pixelSize: 11; color: root.m3onSurface }
                                    Text { text: "Limit charge to 80%"; font.pixelSize: 9; color: root.m3outline }
                                }

                                // Toggle switch
                                Rectangle {
                                    width: 44; height: 24; radius: 12
                                    color: root.longLifeEnabled ? root.m3primary : root.m3surfaceContainer
                                    border.width: root.longLifeEnabled ? 0 : 1
                                    border.color: root.m3outlineVariant

                                    Rectangle {
                                        x: root.longLifeEnabled ? 22 : 2
                                        y: 2; width: 20; height: 20; radius: 10
                                        color: root.longLifeEnabled ? root.m3onPrimary : root.m3outline
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.longLifeEnabled = !root.longLifeEnabled
                                    }
                                }
                            }

                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // ═══════════════════════════════════════════════════
                        // Open Panel Button (like Bluetooth/Network)
                        // ═══════════════════════════════════════════════════
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: openLabel.width + 32
                            height: 32
                            radius: 16
                            color: root.m3primaryContainer

                            RowLayout {
                                id: openLabel
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "Open panel"
                                    font.pixelSize: 11
                                    color: root.m3onPrimaryContainer
                                }

                                Text {
                                    text: "›"
                                    font.pixelSize: 14
                                    color: root.m3onPrimaryContainer
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

            Shortcut {
                sequences: ["Escape"]
                onActivated: Qt.quit()
            }
        }
    }
}
