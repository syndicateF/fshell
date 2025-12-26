pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Lock Calendar Widget - Month grid with navigation + Holiday banner
ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: Appearance.padding.large
    spacing: Appearance.spacing.small

    // Calendar state
    property date viewDate: new Date()
    readonly property int viewMonth: viewDate.getMonth()
    readonly property int viewYear: viewDate.getFullYear()
    readonly property date today: new Date()

    // Get next upcoming holiday (any month, not just current)
    function getNextHoliday() {
        const events = Holidays.upcomingEvents ?? [];
        if (events.length > 0) return events[0];
        return null;
    }

    // Easter egg: end-of-year quotes when no holidays ahead
    readonly property var endYearQuotes: [
        "The only way to do great work is to love what you do.",
        "Not all those who wander are lost.",
        "The wound is the place where the Light enters you.",
        "What we think, we become.",
        "The obstacle is the way.",
        "Memento mori.",
        "This too shall pass.",
        "Be water, my friend.",
        "The unexamined life is not worth living.",
        "Amor fati.",
        "Wabi-sabi.",
        "Kintsugi your broken pieces.",
        "Mono no aware.",
        "Ikigai awaits.",
        "Wu wei."
    ]
    readonly property string randomQuote: endYearQuotes[Math.floor(Math.random() * endYearQuotes.length)]


    // ═══════════════════════════════════════════════════
    // NAVIGATION HEADER
    // ═══════════════════════════════════════════════════
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        // Prev month button
        StyledRect {
            implicitWidth: Appearance.font.size.large * 2
            implicitHeight: implicitWidth
            radius: Appearance.rounding.full
            color: "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                text: "chevron_left"
                font.pointSize: Appearance.font.size.large
                color: Colours.palette.m3primary
            }

            StateLayer {
                radius: Appearance.rounding.full
                function onClicked() {
                    const d = new Date(root.viewDate);
                    d.setMonth(d.getMonth() - 1);
                    root.viewDate = d;
                }
            }
        }

        // Month Year title
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.locale().monthName(root.viewMonth) + " " + root.viewYear
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.mono
            font.weight: Font.Bold
            color: Colours.palette.m3primary
        }

        // Next month button
        StyledRect {
            implicitWidth: Appearance.font.size.large * 2
            implicitHeight: implicitWidth
            radius: Appearance.rounding.full
            color: "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                text: "chevron_right"
                font.pointSize: Appearance.font.size.large
                color: Colours.palette.m3primary
            }

            StateLayer {
                radius: Appearance.rounding.full
                function onClicked() {
                    const d = new Date(root.viewDate);
                    d.setMonth(d.getMonth() + 1);
                    root.viewDate = d;
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // DAY HEADERS
    // ═══════════════════════════════════════════════════
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Repeater {
            model: 7
            StyledText {
                required property int index
                readonly property bool isSunday: (index + Qt.locale().firstDayOfWeek) % 7 === 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((index + Qt.locale().firstDayOfWeek) % 7).substring(0, 3)
                font.pointSize: Appearance.font.size.smaller
                font.family: Appearance.font.family.mono
                font.weight: Font.Bold
                color: isSunday ? Colours.palette.m3secondary : Colours.palette.m3outline
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // CALENDAR GRID
    // ═══════════════════════════════════════════════════
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 7
        columnSpacing: 7

        Repeater {
            model: 42

            Rectangle {
                id: dayCell
                required property int index

                readonly property int firstDay: new Date(root.viewYear, root.viewMonth, 1).getDay()
                readonly property int adjustedFirst: (firstDay - Qt.locale().firstDayOfWeek + 7) % 7
                readonly property int dayNum: index - adjustedFirst + 1
                readonly property int daysInMonth: new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
                readonly property int daysInPrevMonth: new Date(root.viewYear, root.viewMonth, 0).getDate()
                readonly property bool isCurrentMonth: dayNum >= 1 && dayNum <= daysInMonth
                readonly property int displayNum: {
                    if (dayNum < 1) return daysInPrevMonth + dayNum;
                    if (dayNum > daysInMonth) return dayNum - daysInMonth;
                    return dayNum;
                }
                readonly property bool isToday: isCurrentMonth && dayNum === root.today.getDate() &&
                                                root.viewMonth === root.today.getMonth() &&
                                                root.viewYear === root.today.getFullYear()
                readonly property bool isSunday: {
                    if (!isCurrentMonth) return false;
                    return new Date(root.viewYear, root.viewMonth, dayNum).getDay() === 0;
                }
                readonly property bool isHoliday: {
                    if (!isCurrentMonth) return false;
                    return Holidays.hasEvent(new Date(root.viewYear, root.viewMonth, dayNum));
                }

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                opacity: isCurrentMonth ? 1.0 : 0.35

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: {
                        if (dayCell.isToday) return Colours.palette.m3primary;
                        // if (!dayCell.isCurrentMonth) return "transparent";
                        // if (dayCell.isSunday) return Qt.alpha(Colours.palette.m3secondary, 0.2);
                        return Colours.palette.m3surfaceContainerHigh;
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: dayCell.displayNum
                    font.pointSize: Appearance.font.size.smaller
                    font.weight: dayCell.isToday ? Font.Medium : Font.Normal
                    color: {
                        if (dayCell.isToday) return Colours.palette.m3onPrimary;
                        if (dayCell.isSunday) return Colours.palette.m3secondary;
                        if (dayCell.isHoliday) return Colours.palette.m3tertiary;
                        return Colours.palette.m3onSurface;
                    }
                }

                // // Holiday dot indicator
                // Rectangle {
                //     anchors.horizontalCenter: parent.horizontalCenter
                //     anchors.bottom: parent.bottom
                //     visible: dayCell.isHoliday && !dayCell.isToday
                //     width: 4
                //     height: 4
                //     radius: Appearance.spacing.smaller / 2
                //     color: Colours.palette.m3tertiary
                // }
            }
        }
    }

    // Spacer between holiday and calendar
    // Item {
    //     Layout.fillWidth: true
    //     implicitHeight: Appearance.spacing.normal
    // }


    // ═══════════════════════════════════════════════════
    // HOLIDAY BANNER
    // ═══════════════════════════════════════════════════
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: holidayRow.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainerHigh
        // Always visible - shows holiday or easter egg quote

        RowLayout {
            id: holidayRow
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: Holidays.getTodayEvent() ? "celebration" : "event"
                font.pointSize: Appearance.font.size.normal
                color: Holidays.getTodayEvent() ? Colours.palette.m3tertiary : Colours.palette.m3primary
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    const todayEvent = Holidays.getTodayEvent();
                    if (todayEvent) return qsTr("Today: %1").arg(todayEvent.name);
                    const next = root.getNextHoliday();
                    if (next) {
                        const daysUntil = Math.ceil((new Date(next.date) - root.today) / (1000 * 60 * 60 * 24));
                        if (daysUntil === 1) return qsTr("Tomorrow: %1").arg(next.name);
                        return qsTr("In %1 days: %2").arg(daysUntil).arg(next.name);
                    }
                    // Easter egg fallback
                    return root.randomQuote;
                }
                font.pointSize: Appearance.font.size.small
                color: Holidays.getTodayEvent() ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
                elide: Text.ElideRight
            }
        }
    }




}
