pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    property color colour: Colours.palette.m3tertiary
    
    // Time format
    property string timeString: Time.format(Config.services.useTwelveHourClock ? "hh:mm" : "HH:mm")

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: content.implicitHeight + Config.bar.sizes.itemPadding * 2
    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding

    ColumnLayout {
        id: content
        anchors.centerIn: parent

        // Clock section - stacked time digits
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
                    font.pointSize: Config.bar.sizes.font.clockDigits
                    font.family: Appearance.font.family.clock
                    font.hintingPreference: Font.PreferDefaultHinting
                    font.variableAxes: ({ "wght": 450 })
                    color: root.colour
                    renderType: Text.NativeRendering
                }
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

        // Divider
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: root.colour
            // opacity: 0.5
        }

        // Weather section - vertical (icon above, temp below)
        ColumnLayout {
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
            }
        }
    }
}
