pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

StyledRect {
    id: root

    // Warna default sebelumnya
    property color colour: Colours.palette.m3tertiary
    
    // Time format sesuai ii - DEFAULT "hh:mm" tanpa AM/PM
    property string timeString: Time.format(Config.services.useTwelveHourClock ? "hh:mm" : "hh:mm")
    
    // Date format sesuai ii (dd/MM lalu di-split)
    property string shortDate: Time.format("dd/MM")
    property var dayOfMonth: shortDate.split(/[-\/]/)[0]
    property var monthOfYear: shortDate.split(/[-\/]/)[1]

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: content.implicitHeight + Config.bar.sizes.itemPadding * 2
    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: Appearance.spacing.smaller

        // Clock section - persis kayak ii VerticalClockWidget
        ColumnLayout {
            id: clockColumn
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            Repeater {
                model: root.timeString.split(/[: ]/)

                delegate: Text {
                    required property string modelData

                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.padStart(2, "0")
                    font.pixelSize: modelData.match(/am|pm/i) ? 12 : 17
                    font.family: Appearance.font.family.clock
                    font.hintingPreference: Font.PreferDefaultHinting
                    font.variableAxes: ({ "wght": 450 })
                    color: root.colour
                    renderType: Text.NativeRendering
                }
            }
        }

        // HorizontalBarSeparator - divider antara clock dan date
        Rectangle {
            Layout.fillWidth: true
            // Layout.leftMargin: 8
            // Layout.rightMargin: 8
            implicitHeight: 1
            color: root.colour
            opacity: 0.5
        }

        // Date section - persis kayak ii VerticalDateWidget
        Item {
            id: dateContent
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 24
            implicitHeight: 30

            Shape {
                id: diagonalLine
                property real padding: 4
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                opacity: 0.5

                ShapePath {
                    strokeWidth: 1.2
                    strokeColor: root.colour
                    fillColor: "transparent"
                    startX: dateContent.width - diagonalLine.padding
                    startY: diagonalLine.padding
                    PathLine {
                        x: diagonalLine.padding
                        y: dateContent.height - diagonalLine.padding
                    }
                }
            }

            Text {
                id: dayText
                anchors {
                    top: parent.top
                    left: parent.left
                }
                font.pixelSize: 13
                font.family: Appearance.font.family.sans
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes: ({ "wght": Config.bar.sizes.textWeight, "wdth": Config.bar.sizes.textWidth })
                color: root.colour
                text: root.dayOfMonth
                renderType: Text.NativeRendering
            }

            Text {
                id: monthText
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                }
                font.pixelSize: 13
                font.family: Appearance.font.family.sans
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes: ({ "wght": Config.bar.sizes.textWeight, "wdth": Config.bar.sizes.textWidth })
                color: root.colour
                text: root.monthOfYear
                renderType: Text.NativeRendering
            }
        }
    }
}
