pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// EventCard - Reusable event card with accent bar, title, date badge
// Used in both UpcomingEvents (Panel 0) and EventsListPanel (Panel 1)
StyledRect {
    id: root

    // Required: event data object with daysUntil, isToday, name, date
    required property var eventData
    
    // Optional: show countdown (true for upcoming, false for list)
    property bool showCountdown: true

    // Computed from event data
    readonly property var eventMeta: Holidays.getEventMeta(eventData)
    readonly property color accentColor: eventMeta.color
    readonly property bool isToday: eventData?.isToday ?? false
    readonly property int daysUntil: eventData?.daysUntil ?? 0
    readonly property bool isPast: daysUntil < 0

    // Card styling
    implicitHeight: Math.max(60, cardContent.implicitHeight + Appearance.padding.normal * 2)
    radius: Appearance.rounding.small
    // color: Colours.palette.m3surfaceContainerHigh
    color: Colours.tPalette.m3surfaceContainer
    opacity: isPast ? 0.5 : 1.0

    RowLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        // Left accent bar
        Rectangle {
            width: 7
            Layout.fillHeight: true
            radius: Appearance.rounding.small / 2
            color: root.accentColor
        }

        // Center content: countdown/today on top, title below
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // Countdown or Today indicator (optional)
            StyledText {
                visible: root.showCountdown && (root.daysUntil > 0 || root.isToday)
                text: {
                    if (root.isToday) return "Today";
                    if (root.daysUntil === 1) return "Tomorrow";
                    return root.daysUntil + " days";
                }
                font.pointSize: Appearance.font.size.smaller
                font.weight: Font.Medium
                color: root.isToday ? root.accentColor : Colours.palette.m3outline
            }

            // Event title
            StyledText {
                Layout.fillWidth: true
                text: root.eventData?.name ?? ""
                font.pointSize: Appearance.font.size.smaller
                font.weight: Font.Normal
                color: Colours.palette.m3onSurface
                wrapMode: Text.Wrap
            }
        }

        // Right: Vertical date badge (using backend-provided display values)
        Rectangle {
            id: dateBadge
            readonly property int day: root.eventData?.dayNum ?? 0
            readonly property string monthStr: root.eventData?.monthShort ?? ""

            implicitWidth: 44
            Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: Qt.alpha(root.accentColor, 0.15)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                // Day number
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dateBadge.day.toString()
                    font.weight: Font.Medium
                    color: root.accentColor
                }

                // Month (3 letters)
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dateBadge.monthStr
                    font.weight: Font.Medium
                    color: root.accentColor
                }
            }
        }
    }
}
