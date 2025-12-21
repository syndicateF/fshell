import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// PowerProfile Design Preview V5
// Improved Style C: Minimal Cards variations
// Run: quickshell -c prototypes/powerprofile-v2

Scope {
    id: root

    // Material You Dark Theme
    property color clSurface: "#1C1B1F"
    property color clSurfaceContainer: "#2B2930"
    property color clSurfaceContainerHigh: "#36343B"
    property color clSurfaceContainerHighest: "#48464C"
    property color clPrimary: "#D0BCFF"
    property color clOnPrimary: "#381E72"
    property color clPrimaryContainer: "#4F378B"
    property color clOnPrimaryContainer: "#EADDFF"
    property color clSecondary: "#CCC2DC"
    property color clSecondaryContainer: "#4A4458"
    property color clOnSecondaryContainer: "#E8DEF8"
    property color clTertiary: "#7DD3C0"
    property color clTertiaryContainer: "#1F4D44"
    property color clOnTertiaryContainer: "#A4F4DC"
    property color clError: "#F2B8B5"
    property color clOnSurface: "#E6E1E5"
    property color clOnSurfaceVariant: "#CAC4D0"
    property color clOutline: "#938F99"
    property color clOutlineVariant: "#49454F"

    property var profileColors: ["#4CAF50", "#2196F3", "#FF9800"]
    property var profileIcons: ["🌿", "⚖️", "⚡"]
    property var profileNames: ["Power Saver", "Balanced", "Performance"]

    // State
    property int selectedProfile: 1
    property int selectedEpp: 2
    property bool longLifeEnabled: false
    property int batteryPercent: 87
    property int healthPercent: 95
    property int cycleCount: 127
    property bool isCharging: true

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            
            anchors { top: true; left: true; right: true; bottom: true }
            margins { top: 40; bottom: 40; left: 50; right: 50 }
            visible: true
            
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "power-prototype-v5"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(root.clSurface, 0.98)
                radius: 24
                border.width: 1
                border.color: root.clOutlineVariant

                Column {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 16
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Minimal Cards - Improved Variations"; font.pixelSize: 20; font.bold: true; color: root.clOnSurface }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Based on Style C • Click to interact • ESC to close"; font.pixelSize: 12; color: root.clOutline }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    anchors.topMargin: 70
                    anchors.bottomMargin: 30
                    spacing: 24

                    // ════════════════════════════════════════════════════════════
                    // C1: Glass Cards
                    // ════════════════════════════════════════════════════════════
                    DesignCard {
                        label: "C1: Glass Cards"
                        recommended: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            DragHandle {}

                            // Battery Glass Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 72
                                radius: 16
                                color: Qt.alpha(root.clSurfaceContainerHigh, 0.8)
                                border.width: 1
                                border.color: Qt.alpha(root.clOutlineVariant, 0.5)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 14

                                    // Battery circle
                                    Rectangle {
                                        width: 44; height: 44
                                        radius: 22
                                        color: root.isCharging 
                                            ? Qt.alpha(root.clPrimary, 0.15) 
                                            : Qt.alpha(root.clTertiary, 0.15)
                                        border.width: 3
                                        border.color: root.isCharging ? root.clPrimary : root.clTertiary

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.batteryPercent
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: root.clOnSurface
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Row {
                                            spacing: 6
                                            Text { text: root.isCharging ? "Charging" : "On Battery"; font.pixelSize: 13; font.bold: true; color: root.clOnSurface }
                                            Text { visible: root.isCharging; text: "⚡"; font.pixelSize: 12; color: root.clPrimary }
                                        }
                                        Text { text: root.healthPercent + "% health • " + root.cycleCount + " cycles"; font.pixelSize: 10; color: root.clOutline }
                                    }

                                    ToggleSwitch {
                                        isOn: root.longLifeEnabled
                                        onToggled: root.longLifeEnabled = !root.longLifeEnabled
                                    }
                                }
                            }

                            // Profile Header
                            SectionHeader { text: root.profileNames[root.selectedProfile] }

                            // Profile Glass Cards
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: 3
                                    Rectangle {
                                        required property int index
                                        Layout.fillWidth: true
                                        height: 72
                                        radius: 14
                                        color: root.selectedProfile === index 
                                            ? Qt.alpha(root.profileColors[index], 0.15)
                                            : Qt.alpha(root.clSurfaceContainerHigh, 0.8)
                                        border.width: root.selectedProfile === index ? 2 : 1
                                        border.color: root.selectedProfile === index 
                                            ? root.profileColors[index]
                                            : Qt.alpha(root.clOutlineVariant, 0.5)

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.profileIcons[index]
                                                font.pixelSize: 22
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: ["Eco", "Bal", "Perf"][index]
                                                font.pixelSize: 11
                                                font.bold: root.selectedProfile === index
                                                color: root.selectedProfile === index 
                                                    ? root.profileColors[index] 
                                                    : root.clOnSurfaceVariant
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedProfile = index
                                        }
                                    }
                                }
                            }

                            SectionHeader { text: "Energy Preference" }

                            // EPP Glass Pills
                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: ["Default", "Perf", "Balance", "Saver"]
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        width: eppText1.width + 24
                                        height: 34
                                        radius: 17
                                        color: root.selectedEpp === index 
                                            ? root.clSecondaryContainer 
                                            : Qt.alpha(root.clSurfaceContainerHigh, 0.8)
                                        border.width: root.selectedEpp === index ? 0 : 1
                                        border.color: Qt.alpha(root.clOutlineVariant, 0.5)

                                        Text {
                                            id: eppText1
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            color: root.selectedEpp === index 
                                                ? root.clOnSecondaryContainer 
                                                : root.clOnSurfaceVariant
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedEpp = index
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // ════════════════════════════════════════════════════════════
                    // C2: Elevated Cards
                    // ════════════════════════════════════════════════════════════
                    DesignCard {
                        label: "C2: Elevated Cards"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            DragHandle {}

                            // Battery Elevated Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 64
                                radius: 14
                                color: root.clSurfaceContainerHigh

                                // Subtle shadow effect
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.topMargin: 2
                                    radius: 14
                                    color: Qt.alpha("#000000", 0.15)
                                    z: -1
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Rectangle {
                                        width: 40; height: 40
                                        radius: 10
                                        color: root.isCharging ? root.clPrimaryContainer : root.clTertiaryContainer

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.isCharging ? "⚡" : "🔋"
                                            font.pixelSize: 16
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: root.batteryPercent + "% " + (root.isCharging ? "Charging" : ""); font.pixelSize: 14; font.bold: true; color: root.clOnSurface }
                                        Text { text: root.healthPercent + "% • Long Life " + (root.longLifeEnabled ? "On" : "Off"); font.pixelSize: 10; color: root.clOutline }
                                    }

                                    ToggleSwitch { isOn: root.longLifeEnabled; onToggled: root.longLifeEnabled = !root.longLifeEnabled }
                                }
                            }

                            SectionHeader { text: root.profileNames[root.selectedProfile] }

                            // Profile Elevated Cards
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: 3
                                    Rectangle {
                                        required property int index
                                        Layout.fillWidth: true
                                        height: 68
                                        radius: 12
                                        color: root.selectedProfile === index 
                                            ? Qt.alpha(root.profileColors[index], 0.2)
                                            : root.clSurfaceContainerHigh

                                        Rectangle {
                                            visible: root.selectedProfile !== index
                                            anchors.fill: parent
                                            anchors.topMargin: 2
                                            radius: 12
                                            color: Qt.alpha("#000000", 0.1)
                                            z: -1
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 36; height: 36
                                                radius: 10
                                                color: root.selectedProfile === index
                                                    ? Qt.alpha(root.profileColors[index], 0.3)
                                                    : root.clSurfaceContainerHighest

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: root.profileIcons[index]
                                                    font.pixelSize: 16
                                                }
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: ["Eco", "Bal", "Perf"][index]
                                                font.pixelSize: 10
                                                font.bold: root.selectedProfile === index
                                                color: root.selectedProfile === index 
                                                    ? root.profileColors[index] 
                                                    : root.clOnSurfaceVariant
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedProfile = index
                                        }
                                    }
                                }
                            }

                            SectionHeader { text: "Energy Preference" }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 6
                                columnSpacing: 6

                                Repeater {
                                    model: ["Default", "Perf", "Balance", "Saver"]
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: 10
                                        color: root.selectedEpp === index 
                                            ? root.clSecondaryContainer 
                                            : root.clSurfaceContainerHigh

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            color: root.selectedEpp === index 
                                                ? root.clOnSecondaryContainer 
                                                : root.clOnSurfaceVariant
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedEpp = index
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // ════════════════════════════════════════════════════════════
                    // C3: Compact Stacked
                    // ════════════════════════════════════════════════════════════
                    DesignCard {
                        label: "C3: Compact Stacked"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            DragHandle {}

                            // Battery Row (super compact)
                            RowLayout {
                                spacing: 10

                                Text { text: "🔋"; font.pixelSize: 20 }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text { 
                                        text: root.batteryPercent + "%" + (root.isCharging ? " ⚡" : "")
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: root.clOnSurface
                                    }
                                    Text { 
                                        text: root.healthPercent + "% health"
                                        font.pixelSize: 10
                                        color: root.clOutline
                                    }
                                }

                                Column {
                                    spacing: 0
                                    Text { text: "Long Life"; font.pixelSize: 9; color: root.clOutline; anchors.right: parent.right }
                                    ToggleSwitch { isOn: root.longLifeEnabled; onToggled: root.longLifeEnabled = !root.longLifeEnabled }
                                }
                            }

                            // Progress bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: root.clSurfaceContainerHighest

                                Rectangle {
                                    width: parent.width * (root.batteryPercent / 100)
                                    height: parent.height
                                    radius: 2
                                    color: root.isCharging ? root.clPrimary : root.clTertiary
                                }
                            }

                            SectionHeader { text: root.profileNames[root.selectedProfile] }

                            // Stacked Profile Cards
                            Column {
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: 3
                                    Rectangle {
                                        required property int index
                                        width: parent.width
                                        height: 44
                                        radius: 10
                                        color: root.selectedProfile === index 
                                            ? Qt.alpha(root.profileColors[index], 0.15)
                                            : root.clSurfaceContainerHigh

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            Text { text: root.profileIcons[index]; font.pixelSize: 16 }
                                            
                                            Text {
                                                Layout.fillWidth: true
                                                text: root.profileNames[index]
                                                font.pixelSize: 12
                                                font.bold: root.selectedProfile === index
                                                color: root.selectedProfile === index 
                                                    ? root.profileColors[index] 
                                                    : root.clOnSurface
                                            }

                                            Rectangle {
                                                visible: root.selectedProfile === index
                                                width: 20; height: 20
                                                radius: 10
                                                color: root.profileColors[index]
                                                Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 10; color: "#fff" }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedProfile = index
                                        }
                                    }
                                }
                            }

                            SectionHeader { text: "Energy Pref" }

                            // EPP Row
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4

                                Repeater {
                                    model: ["D", "P", "B", "S"]
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        width: 40; height: 32
                                        radius: 8
                                        color: root.selectedEpp === index 
                                            ? root.clSecondaryContainer 
                                            : root.clSurfaceContainerHigh

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.selectedEpp === index 
                                                ? root.clOnSecondaryContainer 
                                                : root.clOnSurfaceVariant
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedEpp = index
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // ════════════════════════════════════════════════════════════
                    // C4: Floating Cards
                    // ════════════════════════════════════════════════════════════
                    DesignCard {
                        label: "C4: Floating Cards"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            DragHandle {}

                            // Floating Battery Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 56
                                radius: 28
                                color: root.clSurfaceContainerHigh

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 14
                                    spacing: 10

                                    Rectangle {
                                        width: 44; height: 44
                                        radius: 22
                                        color: root.isCharging ? root.clPrimaryContainer : root.clTertiaryContainer

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.batteryPercent + ""
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: root.isCharging ? root.clOnPrimaryContainer : root.clOnTertiaryContainer
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text { text: root.isCharging ? "Charging ⚡" : "On Battery"; font.pixelSize: 12; font.bold: true; color: root.clOnSurface }
                                        Text { text: root.healthPercent + "% health"; font.pixelSize: 10; color: root.clOutline }
                                    }

                                    ToggleSwitch { isOn: root.longLifeEnabled; onToggled: root.longLifeEnabled = !root.longLifeEnabled }
                                }
                            }

                            SectionHeader { text: root.profileNames[root.selectedProfile] }

                            // Floating Profile Pills
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                Repeater {
                                    model: 3
                                    Rectangle {
                                        required property int index
                                        width: 72
                                        height: 72
                                        radius: 36
                                        color: root.selectedProfile === index 
                                            ? Qt.alpha(root.profileColors[index], 0.2)
                                            : root.clSurfaceContainerHigh
                                        border.width: root.selectedProfile === index ? 3 : 0
                                        border.color: root.profileColors[index]

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.profileIcons[index]
                                                font.pixelSize: 22
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: ["Eco", "Bal", "Perf"][index]
                                                font.pixelSize: 9
                                                font.bold: root.selectedProfile === index
                                                color: root.selectedProfile === index 
                                                    ? root.profileColors[index] 
                                                    : root.clOnSurfaceVariant
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedProfile = index
                                        }
                                    }
                                }
                            }

                            SectionHeader { text: "Energy Pref" }

                            // Floating EPP Pills
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6

                                Repeater {
                                    model: ["Default", "Perf", "Bal", "Save"]
                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        width: eppText4.width + 20
                                        height: 30
                                        radius: 15
                                        color: root.selectedEpp === index 
                                            ? root.clSecondaryContainer 
                                            : root.clSurfaceContainerHigh

                                        Text {
                                            id: eppText4
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 10
                                            color: root.selectedEpp === index 
                                                ? root.clOnSecondaryContainer 
                                                : root.clOnSurfaceVariant
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedEpp = index
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
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

    // ════════════════════════════════════════════════════════════
    // COMPONENTS
    // ════════════════════════════════════════════════════════════

    component DesignCard: Rectangle {
        property string label: ""
        property bool recommended: false

        Layout.fillHeight: true
        Layout.fillWidth: true
        radius: 16
        color: root.clSurfaceContainer
        border.width: recommended ? 2 : 1
        border.color: recommended ? root.clPrimary : root.clOutlineVariant

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: -12
            width: labelText.width + 20
            height: 24
            radius: 12
            color: recommended ? root.clPrimaryContainer : root.clSurfaceContainerHigh

            Text {
                id: labelText
                anchors.centerIn: parent
                text: label + (recommended ? " ⭐" : "")
                font.pixelSize: 11
                font.bold: true
                color: recommended ? root.clOnPrimaryContainer : root.clOnSurfaceVariant
            }
        }
    }

    component DragHandle: Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 48
        implicitHeight: 14

        Rectangle {
            anchors.centerIn: parent
            width: 32
            height: 4
            radius: 2
            color: root.clOutlineVariant
        }
    }

    component SectionHeader: RowLayout {
        property string text: ""
        Layout.fillWidth: true
        spacing: 6

        Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
        Text { text: parent.text; font.pixelSize: 10; font.bold: true; color: root.clOutline }
        Rectangle { Layout.fillWidth: true; height: 1; color: root.clOutlineVariant }
    }

    component ToggleSwitch: Rectangle {
        property bool isOn: false
        signal toggled()

        width: 44; height: 24; radius: 12
        color: isOn ? root.clPrimary : root.clSurfaceContainer
        border.width: isOn ? 0 : 1
        border.color: root.clOutlineVariant

        Rectangle {
            x: parent.isOn ? 22 : 2
            y: 2; width: 20; height: 20; radius: 10
            color: parent.isOn ? root.clOnPrimary : root.clOutline
            Behavior on x { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled()
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
