pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    property color hourColour: Colours.palette.m3peach
    property color minuteColour: Colours.palette.m3onSurface
    
    // Time format
    property string timeString: Time.format(Config.services.useTwelveHourClock ? "hh:mm" : "HH:mm")

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: content.implicitHeight + Config.bar.sizes.itemPadding * 2
    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding
    
    // Glassmorphic thin border
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3outline, 0.08)

    // Dynamic weather color based on WMO code
    readonly property color weatherColor: {
        if (!Weather.hasData || Weather.hasError) return Colours.palette.m3error;
        const code = Weather.weatherCode;
        if (code === 0 || code === 1) {
            return "#FFB300"; // Sunny/Clear: Warm Amber
        } else if (code === 2 || code === 3) {
            return "#90A4AE"; // Partly cloudy/Overcast: Slate Gray
        } else if (code >= 45 && code <= 48) {
            return "#B0BEC5"; // Fog: Soft Gray
        } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
            return "#29B6F6"; // Rain/Showers: Cyan Blue
        } else if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
            return "#80DEEA"; // Snow/Ice: Mint/Ice Blue
        } else if (code >= 95 && code <= 99) {
            return "#BA68C8"; // Thunderstorm: Purple/Violet
        }
        return Colours.palette.m3peach; // Default fallback
    }

    ColumnLayout {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: 8

        // Clock section - clean vertical typography with bold hours
        ColumnLayout {
            id: clockColumn
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: root.timeString.split(/[: ]/)

                delegate: Text {
                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.padStart(2, "0")
                    font.pointSize: Config.bar.sizes.font.clockDigits
                    font.family: Appearance.font.family.clock
                    font.hintingPreference: Font.PreferDefaultHinting
                    font.bold: index === 0
                    font.weight: index === 0 ? Font.Bold : Font.Normal
                    font.variableAxes: ({ "wght": index === 0 ? 700 : 400 })
                    color: Colours.palette.m3onSurface
                    renderType: Text.NativeRendering
                }
            }
        }

        // Weather section - clean flat icon with dynamic weatherColor and muted temp
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: Weather.hasData || Weather.loading || Weather.hasError

            MaterialIcon {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                animate: true
                text: Weather.hasData ? Weather.icon : (Weather.hasError ? "cloud_off" : "cloud")
                font.pointSize: Config.bar.sizes.font.materialIcon
                color: Weather.hasError 
                    ? Colours.palette.m3error 
                    : (Weather.isStale ? Qt.alpha(root.weatherColor, 0.6) : root.weatherColor)

                Behavior on color { ColorAnimation { duration: 400 } }
            }

            // Temperature text
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: Weather.hasData || Weather.loading
                text: Weather.hasData ? `${Weather.tempC}°` : "..."
                font.pointSize: Config.bar.sizes.font.clockDate
                font.family: Appearance.font.family.sans
                font.weight: Font.Medium
                color: Weather.isStale 
                    ? Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.6) 
                    : Colours.palette.m3onSurfaceVariant
                renderType: Text.NativeRendering
            }
        }
    }
}
