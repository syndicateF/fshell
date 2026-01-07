pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import "."  // Import EventCard from same directory

// UpcomingEvents - Shows up to 3 upcoming events + action button
// Used in Panel 0 of CalendarPopout
ColumnLayout {
    id: root

    // Signal emitted when user clicks "See All Events" button
    signal openEventsListRequested()

    Layout.fillWidth: true
    spacing: Appearance.spacing.small

    // Event cards (up to 3 upcoming events - pre-computed by backend)
    Repeater {
        model: Holidays.topUpcomingEvents

        EventCard {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            eventData: modelData
            showCountdown: true
        }
    }

    // Action button - "See all events"
    StyledRect {
        visible: Holidays.thisMonthEvents.length > 0
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Appearance.rounding.small
        color: Qt.alpha(Colours.palette.m3primary, 0.1)
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3primary, 0.3)

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                text: "calendar_month"
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3primary
            }

            StyledText {
                text: Qt.locale().monthName(new Date().getMonth()) + " - " + Holidays.thisMonthEvents.length + " Events"
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3primary
            }
        }

        StateLayer {
            radius: Appearance.rounding.small
            color: Colours.palette.m3primary
            function onClicked(): void {
                root.openEventsListRequested();
            }
        }
    }
}
