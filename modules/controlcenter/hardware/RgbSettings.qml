pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property Session session
    property int selectedZone: -1
    implicitWidth: 400

    function getContrastColor(hexColor: string): color {
        if (!hexColor || hexColor.length < 7) return "#FFFFFF";
        var r = parseInt(hexColor.substring(1, 3), 16);
        var g = parseInt(hexColor.substring(3, 5), 16);
        var b = parseInt(hexColor.substring(5, 7), 16);
        var luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        return luminance > 0.5 ? "#000000" : "#FFFFFF";
    }

    StyledFlickable {
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        contentHeight: mainCol.height

        ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            // Header Icon
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "keyboard"
                font.pointSize: Appearance.font.size.extraLarge * 3
                color: Colours.palette.m3tertiary
            }

            // Title
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("RGB Keyboard")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            // Subtitle
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Hardware.rgbDeviceName || "OpenRGB"
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideMiddle
                Layout.maximumWidth: parent.width - 20
            }

            // Reset Button
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Reset")
                icon: "restart_alt"
                visible: Hardware.hasRgbKeyboard
                onClicked: Hardware.resetRgbToDefault()
            }

            // Not Available Warning
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 20
                visible: !Hardware.hasRgbKeyboard
                spacing: 10

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "warning"
                    font.pointSize: 40
                    color: Colours.palette.m3error
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("RGB not detected")
                    color: Colours.palette.m3error
                }
            }

            // ========== MAIN CONTENT ==========
            ColumnLayout {
                Layout.fillWidth: true
                visible: Hardware.hasRgbKeyboard
                spacing: Appearance.spacing.normal

                // Toggle Card
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    radius: Appearance.rounding.normal
                    color: Hardware.rgbEnabled ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("RGB Lighting")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 600
                        }

                        StyledSwitch {
                            checked: Hardware.rgbEnabled
                            onClicked: Hardware.toggleRgb()
                        }
                    }
                }

                // Mode Selection
                StyledText {
                    Layout.topMargin: 10
                    text: qsTr("Mode")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    opacity: Hardware.rgbEnabled ? 1 : 0.5
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: modeCol.height + 20
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    opacity: Hardware.rgbEnabled ? 1 : 0.5

                    Column {
                        id: modeCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Repeater {
                            model: Hardware.rgbModes
                            delegate: Rectangle {
                                width: modeCol.width
                                height: 45
                                radius: 8
                                color: Hardware.rgbCurrentMode === modelData ? Colours.palette.m3primaryContainer : "transparent"
                                required property string modelData

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: Hardware.rgbEnabled
                                    onClicked: Hardware.setRgbMode(modelData)
                                }
                            }
                        }
                    }
                }

                // Zone Colors Title
                StyledText {
                    Layout.topMargin: 10
                    text: qsTr("Zone Colors")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    opacity: Hardware.rgbEnabled ? 1 : 0.5
                }

                // ========== ZONE COLORS - USING FIXED WIDTH ==========
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    opacity: Hardware.rgbEnabled ? 1 : 0.5

                    Row {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5

                        // Zone 0
                        Rectangle {
                            width: 80
                            height: parent.height
                            radius: 8
                            color: Hardware.rgbColors[0] || "#FF0000"
                            border.width: root.selectedZone === 0 ? 3 : 0
                            border.color: Colours.palette.m3primary

                            Text {
                                anchors.centerIn: parent
                                text: "Left"
                                font.bold: true
                                font.pixelSize: 12
                                color: root.getContrastColor(parent.color.toString())
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedZone = root.selectedZone === 0 ? -1 : 0
                            }
                        }

                        // Zone 1
                        Rectangle {
                            width: 80
                            height: parent.height
                            radius: 8
                            color: Hardware.rgbColors[1] || "#00FF00"
                            border.width: root.selectedZone === 1 ? 3 : 0
                            border.color: Colours.palette.m3primary

                            Text {
                                anchors.centerIn: parent
                                text: "L-Mid"
                                font.bold: true
                                font.pixelSize: 12
                                color: root.getContrastColor(parent.color.toString())
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedZone = root.selectedZone === 1 ? -1 : 1
                            }
                        }

                        // Zone 2
                        Rectangle {
                            width: 80
                            height: parent.height
                            radius: 8
                            color: Hardware.rgbColors[2] || "#0000FF"
                            border.width: root.selectedZone === 2 ? 3 : 0
                            border.color: Colours.palette.m3primary

                            Text {
                                anchors.centerIn: parent
                                text: "R-Mid"
                                font.bold: true
                                font.pixelSize: 12
                                color: root.getContrastColor(parent.color.toString())
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedZone = root.selectedZone === 2 ? -1 : 2
                            }
                        }

                        // Zone 3
                        Rectangle {
                            width: 80
                            height: parent.height
                            radius: 8
                            color: Hardware.rgbColors[3] || "#FF00FF"
                            border.width: root.selectedZone === 3 ? 3 : 0
                            border.color: Colours.palette.m3primary

                            Text {
                                anchors.centerIn: parent
                                text: "Right"
                                font.bold: true
                                font.pixelSize: 12
                                color: root.getContrastColor(parent.color.toString())
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedZone = root.selectedZone === 3 ? -1 : 3
                            }
                        }
                    }
                }

                // Quick Color Picker (when zone selected)
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.selectedZone >= 0 && Hardware.rgbEnabled
                    spacing: 8

                    StyledText {
                        text: qsTr("Pick color for Zone %1").arg(root.selectedZone + 1)
                        font.weight: 500
                    }

                    // Color Grid - Fixed size boxes
                    Flow {
                        spacing: 8

                        Repeater {
                            model: ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", 
                                    "#00FFFF", "#FFFFFF", "#FF8800", "#8800FF", "#00FF88"]
                            
                            Rectangle {
                                width: 45
                                height: 45
                                radius: 8
                                color: modelData
                                border.width: 2
                                border.color: "#666666"
                                required property string modelData

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Hardware.setRgbColor(root.selectedZone, modelData.substring(1))
                                }
                            }
                        }
                    }
                }

                // Presets
                StyledText {
                    Layout.topMargin: 15
                    text: qsTr("Presets")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    opacity: Hardware.rgbEnabled ? 1 : 0.5
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    opacity: Hardware.rgbEnabled ? 1 : 0.5

                    Repeater {
                        model: Hardware.rgbPresets

                        Rectangle {
                            width: 100
                            height: 55
                            radius: 8
                            color: Colours.tPalette.m3surfaceContainer
                            required property var modelData
                            required property int index

                            Column {
                                anchors.centerIn: parent
                                spacing: 3

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2
                                    Repeater {
                                        model: 4
                                        Rectangle {
                                            width: 14
                                            height: 14
                                            radius: 3
                                            required property int index
                                            color: {
                                                var c = modelData.colors;
                                                return c && c[index] ? "#" + c[index] : "#888"
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.name || "Preset"
                                    font.pixelSize: 10
                                    color: Colours.palette.m3onSurface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Hardware.rgbEnabled
                                onClicked: Hardware.applyRgbPreset(index)
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 30 }
            }
        }
    }
}
