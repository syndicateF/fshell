pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

/**
 * Hardware Pane - List-Detail layout
 * 
 * Left panel: Hardware list (Power, RGB Keyboard)
 * Right panel: Details for selected item
 */
RowLayout {
    id: root

    required property Session session

    anchors.fill: parent
    spacing: 0

    // ==================== LEFT PANEL: Hardware List ====================
    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 320
        Layout.fillHeight: true

        StyledFlickable {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            flickableDirection: Flickable.VerticalFlick
            contentHeight: listContent.height

            ColumnLayout {
                id: listContent
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Appearance.spacing.normal

                // Header
                StyledText {
                    text: qsTr("Hardware")
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Bold
                }

                StyledText {
                    text: qsTr("System hardware control")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3outline
                }

                // Power item
                HardwareListItem {
                    icon: "electric_bolt"
                    title: qsTr("Power")
                    subtitle: Power.available 
                        ? qsTr("Profile: %1").arg(Power.platformProfile || Power.cpuGovernor)
                        : qsTr("Daemon not available")
                    available: Power.available
                    isActive: root.session.hw.active === "power"

                    onClicked: root.session.hw.active = "power"
                }

                // RGB Keyboard item
                HardwareListItem {
                    icon: "keyboard"
                    title: qsTr("RGB Keyboard")
                    subtitle: {
                        if (LegionRgb.busy) return qsTr("Loading...");
                        if (!LegionRgb.available) return qsTr("Not connected");
                        switch (LegionRgb.effect) {
                            case "static": return qsTr("Static color");
                            case "breath": return qsTr("Breathing");
                            case "wave": return qsTr("Wave %1").arg(LegionRgb.direction === "ltr" ? "→" : "←");
                            case "hue": return qsTr("Color cycle");
                            case "off": return qsTr("Off");
                            default: return qsTr("Unknown");
                        }
                    }
                    available: LegionRgb.available || LegionRgb.hasState
                    isActive: root.session.hw.active === "rgb"
                    showColorPreview: LegionRgb.available && LegionRgb.effect !== "off" && LegionRgb.effect !== "wave" && LegionRgb.effect !== "hue"
                    previewColor: LegionRgb.colors.length > 0 ? "#" + LegionRgb.colors[0] : "#000000"

                    onClicked: {
                        root.session.hw.active = "rgb";
                        LegionRgb.refresh();
                    }
                }
            }
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    // ==================== RIGHT PANEL: Detail View ====================
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: rightBorder.innerRadius
            color: "transparent"

            // No selection placeholder
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.session.hw.active === ""
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "touch_app"
                    font.pointSize: Appearance.font.size.extraLarge * 2
                    color: Colours.palette.m3outline
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Select a hardware item")
                    color: Colours.palette.m3outline
                }
            }

            // Power detail
            Loader {
                anchors.fill: parent
                active: root.session.hw.active === "power"
                asynchronous: true

                sourceComponent: PowerPane {
                    session: root.session
                }
            }

            // RGB detail
            Loader {
                anchors.fill: parent
                active: root.session.hw.active === "rgb"
                asynchronous: true

                sourceComponent: RgbPane {}
            }
        }

        InnerBorder {
            id: rightBorder
            leftThickness: Appearance.padding.normal / 2
        }
    }

    // Hardware list item component
    component HardwareListItem: StyledRect {
        id: listItem

        required property string icon
        required property string title
        required property string subtitle
        required property bool available
        required property bool isActive
        property bool showColorPreview: false
        property color previewColor: "transparent"

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: itemRow.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.normal
        color: isActive ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        StateLayer {
            radius: parent.radius
            function onClicked(): void {
                listItem.clicked();
            }
        }

        RowLayout {
            id: itemRow
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: listItem.icon
                font.pointSize: Appearance.font.size.large
                color: listItem.available 
                    ? (listItem.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3primary)
                    : Colours.palette.m3outline
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: listItem.title
                    font.weight: listItem.isActive ? Font.Medium : Font.Normal
                    color: listItem.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                }

                StyledText {
                    text: listItem.subtitle
                    font.pointSize: Appearance.font.size.small
                    color: listItem.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline
                }
            }

            // Color preview
            Rectangle {
                visible: listItem.showColorPreview
                width: 20
                height: 20
                radius: 10
                color: listItem.previewColor
                border.width: 2
                border.color: Colours.palette.m3outline
            }

            MaterialIcon {
                text: "chevron_right"
                color: listItem.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline
            }
        }
    }
}
