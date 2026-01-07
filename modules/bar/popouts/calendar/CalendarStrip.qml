pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

// CalendarStrip - 7-day week view with forecast icons
// Today in center (index 3), shows 3 past + today + 3 future
RowLayout {
    id: root

    Layout.fillWidth: true
    spacing: 4

    Repeater {
        model: 7

        StyledRect {
            id: dayItem
            required property int index

            // Today in CENTER (index 3)
            readonly property int dayOffset: index - 3
            readonly property date dayDate: {
                const d = new Date();
                d.setDate(d.getDate() + dayOffset);
                return d;
            }
            readonly property int dayNum: dayDate.getDate()
            readonly property bool isToday: dayOffset === 0
            readonly property bool isPast: dayOffset < 0
            readonly property bool isHoliday: Holidays.hasEvent(dayDate)
            readonly property bool isSunday: dayDate.getDay() === 0
            // Past days fade more, future days fade less
            readonly property real distanceOpacity: 1.0 - (Math.abs(dayOffset) * 0.12)

            Layout.fillWidth: true
            implicitWidth: Appearance.font.size.small * 3
            // Uniform height for all days
            implicitHeight: Appearance.font.size.normal * 5
            radius: Appearance.rounding.small
            color: isToday ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                opacity: dayItem.isToday ? 1.0 : dayItem.distanceOpacity

                // Day name (first letter)
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.locale().dayName(dayItem.dayDate.getDay()).substring(0, 1)
                    font.pointSize: Appearance.font.size.smaller
                    font.weight: Font.Medium
                    color: dayItem.isToday ? Colours.palette.m3onPrimary 
                        : (dayItem.isSunday ? Colours.palette.m3secondary : Colours.palette.m3outline)
                }

                // Day number
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dayItem.dayNum
                    font.pointSize: Appearance.font.size.normal
                    font.weight: Font.Normal
                    color: {
                        if (dayItem.isToday) return Colours.palette.m3onPrimary;
                        if (dayItem.isSunday) return Colours.palette.m3secondary;
                        if (dayItem.isHoliday) return Colours.palette.m3tertiary;
                        return Colours.palette.m3onSurface;
                    }
                }
                
                // Forecast icon for ALL days
                MaterialIcon {
                    id: forecastIcon
                    Layout.alignment: Qt.AlignHCenter
                    property string weatherIcon: ""
                    
                    function updateIcon() {
                        // For past days, use today's weather icon
                        // For today and future, use forecast
                        const forecastIndex = Math.max(0, dayItem.dayOffset);
                        if (forecastIndex < Weather.dailyForecast.length) {
                            const f = Weather.dailyForecast[forecastIndex];
                            if (f && typeof f.weather_code === 'number') {
                                weatherIcon = Icons.getWeatherIcon(f.weather_code, true);
                                return;
                            }
                        }
                        weatherIcon = "";
                    }
                    
                    Component.onCompleted: updateIcon()
                    Connections {
                        target: Weather
                        function onForecastVersionChanged() { forecastIcon.updateIcon(); }
                    }
                    
                    visible: weatherIcon !== ""
                    text: weatherIcon
                    font.pointSize: Appearance.font.size.small
                    color: dayItem.isToday ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                }
                
                // Holiday indicator (only if no forecast icon)
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: dayItem.isHoliday && forecastIcon.weatherIcon === ""
                    width: 4
                    height: 4
                    radius: 2
                    color: dayItem.isToday ? Colours.palette.m3onPrimary : Colours.palette.m3tertiary
                }
            }
        }
    }
}
