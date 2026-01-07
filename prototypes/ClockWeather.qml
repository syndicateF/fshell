pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// ═══════════════════════════════════════════════════════════════════════════
// ClockWeather - Compact Bar Component Prototype
// Vertical clock + date + weather for the sidebar bar
// 
// Layout:
// ┌─────────┐
// │   01    │  <- Hour (accent color)
// │   52    │  <- Minute
// │   AM    │  <- AM/PM (subtle)
// ├─────────┤  <- Divider
// │  08/01  │  <- Date diagonal
// ├─────────┤  <- Divider
// │   ☀️    │  <- Weather icon  
// │  24°    │  <- Temperature
// └─────────┘
// ═══════════════════════════════════════════════════════════════════════════
StyledRect {
    id: root

    // ═══════════════════════════════════════════════════════════════════════
    // PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════
    property color colour: Colours.palette.m3tertiary
    
    // Time format
    property string timeString: Time.format(Config.services.useTwelveHourClock ? "hh:mm" : "HH:mm")
    property var timeParts: timeString.split(":")
    property string hourPart: (timeParts[0] || "00").padStart(2, "0")
    property string minutePart: (timeParts[1] || "00").padStart(2, "0")
    
    // Date format
    property string shortDate: Time.format("dd/MM")
    property var dayOfMonth: shortDate.split(/[-\/]/)[0]
    property var monthOfYear: shortDate.split(/[-\/]/)[1]

    // ═══════════════════════════════════════════════════════════════════════
    // SIZING - Match existing bar component sizing
    // ═══════════════════════════════════════════════════════════════════════
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: content.implicitHeight + Config.bar.sizes.itemPadding * 2
    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: Appearance.spacing.smaller

        // ═══════════════════════════════════════════════════════════════════
        // SECTION 1: TIME - Stacked HH:MM
        // ═══════════════════════════════════════════════════════════════════
        ColumnLayout {
            id: clockColumn
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            // Hour - accent color
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.hourPart
                font.pointSize: Config.bar.sizes.font.clockDigits
                font.family: Appearance.font.family.clock
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes: ({ "wght": 500 })
                color: root.colour
                renderType: Text.NativeRendering
            }

            // Minute - regular text color
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.minutePart
                font.pointSize: Config.bar.sizes.font.clockDigits
                font.family: Appearance.font.family.clock
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes: ({ "wght": 450 })
                color: Colours.palette.m3onSurface
                renderType: Text.NativeRendering
            }
            
            // AM/PM indicator
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                visible: Config.services.useTwelveHourClock
                text: Time.format("AP")
                font.pointSize: 8
                font.family: Appearance.font.family.sans
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes: ({ "wght": 500 })
                color: root.colour
                opacity: 0.7
                renderType: Text.NativeRendering
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // DIVIDER 1: Time-Date separator
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: root.colour
            opacity: 0.5
        }

        // ═══════════════════════════════════════════════════════════════════
        // SECTION 2: DATE - Diagonal style (same as current)
        // ═══════════════════════════════════════════════════════════════════
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
                font.pointSize: Config.bar.sizes.font.clockDate
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
                font.pointSize: Config.bar.sizes.font.clockDate
                font.family: Appearance.font.family.sans
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes: ({ "wght": Config.bar.sizes.textWeight, "wdth": Config.bar.sizes.textWidth })
                color: root.colour
                text: root.monthOfYear
                renderType: Text.NativeRendering
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // DIVIDER 2: Date-Weather separator
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            visible: Weather.hasData || Weather.loading || Weather.hasError
            implicitHeight: 1
            color: root.colour
            opacity: 0.3
        }

        // ═══════════════════════════════════════════════════════════════════
        // SECTION 3: WEATHER - Icon + Temp (compact)
        // ═══════════════════════════════════════════════════════════════════
        ColumnLayout {
            id: weatherSection
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            visible: Weather.hasData || Weather.loading || Weather.hasError

            // Weather icon
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: Weather.hasData ? Weather.icon : (Weather.hasError ? "cloud_off" : "cloud")
                font.pointSize: Config.bar.sizes.font.materialIcon
                color: Weather.hasError 
                    ? Colours.palette.m3error 
                    : (Weather.isStale ? Qt.alpha(root.colour, 0.6) : root.colour)
            }

            // Temperature
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: Weather.hasData || Weather.loading
                text: Weather.hasData ? `${Weather.tempC}°` : "..."
                font.pointSize: Config.bar.sizes.font.clockDate
                font.family: Appearance.font.family.sans
                font.weight: Font.Medium
                color: Weather.isStale ? Qt.alpha(root.colour, 0.7) : root.colour
                renderType: Text.NativeRendering

                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: parent; property: "opacity"; to: 0.5; duration: 80 }
                        NumberAnimation { target: parent; property: "opacity"; to: 1.0; duration: 80 }
                    }
                }
            }

            // Stale indicator (tiny dot)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                visible: Weather.isStale
                width: 4
                height: 4
                radius: 2
                color: Colours.palette.m3error
                opacity: 0.8
            }
        }
    }
}
