pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// CalendarPopout - Horizontal Slide Design
// Dynamic dimensions with max height limit
// Panel 0: Main content with "Upcoming" events preview
// Panel 1: Full month events list (slide in from right)
Item {
    id: rootWrapper

    required property Item wrapper

    // Font-based width for DPI scaling
    // Sized to fit events list panel content (longer event names)
    readonly property real popoutWidth: Appearance.font.size.normal * 21
    implicitWidth: popoutWidth
    implicitHeight: mainContent.implicitHeight + Appearance.padding.small * 2

    // Toggle between main view and events list
    property bool eventsListMode: false

    // Refresh weather when popout opens for more real-time data
    onVisibleChanged: {
        if (visible) {
            Weather.checkAndRefresh();
        }
    }

    // Horizontal slide container
    Item {
        id: slideContainer
        anchors.fill: parent
        clip: true

        RowLayout {
            id: slideRow
            spacing: 0
            height: parent.height

            // Slide animation
            x: rootWrapper.eventsListMode ? -rootWrapper.popoutWidth : 0

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            // ═══════════════════════════════════════════════════
            // PANEL 0: Main Content (no scroll)
            // ═══════════════════════════════════════════════════
            Item {
                id: mainPanel
                Layout.preferredWidth: rootWrapper.popoutWidth
                Layout.preferredHeight: mainContent.implicitHeight

                ColumnLayout {
                    id: mainContent
                    // Fill parent width so children can use Layout.fillWidth
                    width: parent.width
                    spacing: Appearance.spacing.small

                    // ───────────────────────────────────────────────
                    // WEATHER HERO
                    // ───────────────────────────────────────────────
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: heroContent.height + Appearance.padding.normal * 2
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3surfaceContainerHigh

                        ColumnLayout {
                            id: heroContent
                            width: parent.width - Appearance.padding.normal * 2
                            x: Appearance.padding.normal
                            y: Appearance.padding.normal
                            spacing: Appearance.spacing.normal

                            // Date header - elegant and light
                            StyledText {
                                text: Qt.formatDate(new Date(), "dddd, MMMM d")
                                font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3outline

                                // font.weight: Font.Medium
                                // color: Colours.palette.m3primary
                            }

                            // Weather row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                MaterialIcon {
                                    animate: true
                                    text: Weather.icon
                                    font.pointSize: 36
                                    color: Weather.hasError ? Colours.palette.m3error : Colours.palette.m3tertiary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        animate: true
                                        text: Weather.hasData ? Weather.temp : (Weather.loading ? "..." : "--")
                                        font.pointSize: 28
                                        font.weight: Font.Light
                                        color: Colours.palette.m3onSurface
                                    }

                                    StyledText {
                                        animate: true
                                        text: Weather.hasData ? Weather.displayDescription : (Weather.hasError ? qsTr("Offline") : qsTr("Loading..."))
                                        font.pointSize: Appearance.font.size.small
                                        color: Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }

                            // Location row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.smaller
                                visible: Weather.hasData

                                MaterialIcon {
                                    text: "location_on"
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3outline
                                }

                                StyledText {
                                    animate: true
                                    text: Weather.city
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3outline
                                }
                                
                                // Stale indicator
                                Rectangle {
                                    visible: Weather.isStale
                                    width: staleRow.width + 8
                                    height: staleRow.height + 4
                                    radius: height / 2
                                    color: Qt.alpha(Colours.palette.m3error, 0.15)
                                    
                                    Row {
                                        id: staleRow
                                        anchors.centerIn: parent
                                        spacing: 2
                                        
                                        MaterialIcon {
                                            text: "sync_problem"
                                            font.pointSize: Appearance.font.size.smaller
                                            color: Colours.palette.m3error
                                        }
                                        
                                        StyledText {
                                            text: qsTr("Stale")
                                            font.pointSize: Appearance.font.size.smaller
                                            color: Colours.palette.m3error
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Row {
                                    spacing: 4
                                    MaterialIcon {
                                        text: "water_drop"
                                        font.pointSize: Appearance.font.size.smaller
                                        color: Colours.palette.m3outline
                                    }
                                    StyledText {
                                        text: Weather.humidity + "%"
                                        font.pointSize: Appearance.font.size.smaller
                                        color: Colours.palette.m3outline
                                    }
                                }
                            }
                        }
                    }

                    // ───────────────────────────────────────────────
                    // WEEK VIEW STRIP
                    // ───────────────────────────────────────────────
                    RowLayout {
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

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Qt.locale().dayName(dayItem.dayDate.getDay()).substring(0, 1)
                                        font.pointSize: Appearance.font.size.smaller
                                        font.weight: Font.Medium
                                        color: dayItem.isToday ? Colours.palette.m3onPrimary 
                                            : (dayItem.isSunday ? Colours.palette.m3secondary : Colours.palette.m3outline)
                                    }

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
                                    
                                    // Forecast icon for ALL days (past uses today's, future uses forecast)
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



                    // EVENTS CARDS (upcoming + today's events)
                    Repeater {
                        model: Holidays.upcomingEvents.slice(0, 3)

                        StyledRect {
                            id: eventCard
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true

                            readonly property var eventMeta: Holidays.getEventMeta(modelData)
                            readonly property color accentColor: eventMeta.color
                            readonly property bool isToday: modelData?.isToday ?? false

                            implicitHeight: eventCardContent.implicitHeight + Appearance.padding.normal * 2
                            radius: Appearance.rounding.small
                            // Same color as hero and calendar strip
                            color: Colours.palette.m3surfaceContainerHigh

                            RowLayout {
                                id: eventCardContent
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                spacing: Appearance.spacing.normal

                                // Left accent bar - colorful based on event type
                                Rectangle {
                                    width: 7
                                    Layout.fillHeight: true
                                    radius: Appearance.rounding.small / 2
                                    color: eventCard.accentColor
                                }

                                // Center content: countdown/today on top, title below (vertically centered)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter  // Center vertically
                                    spacing: 2

                                    // Countdown or Today indicator
                                    StyledText {
                                        readonly property int daysUntil: eventCard.modelData?.daysUntil ?? 0
                                        visible: daysUntil > 0 || eventCard.isToday
                                        text: {
                                            if (eventCard.isToday) return "Today";
                                            if (daysUntil === 1) return "Tomorrow";
                                            return daysUntil + " days";
                                        }
                                        font.pointSize: Appearance.font.size.smaller
                                        font.weight: Font.Medium
                                        color: eventCard.isToday ? eventCard.accentColor : Colours.palette.m3outline
                                    }

                                    // Event title
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: eventCard.modelData?.name ?? ""
                                        font.pointSize: Appearance.font.size.smaller
                                        font.weight: Font.Normal
                                        color: Colours.palette.m3onSurface
                                        wrapMode: Text.Wrap
                                    }
                                }

                                // RIGHT: Vertical date badge with background (fills height with padding)
                                Rectangle {
                                    readonly property string dateStr: eventCard.modelData?.date ?? ""
                                    readonly property int day: dateStr.length >= 10 ? parseInt(dateStr.substring(8, 10)) : 0
                                    readonly property int monthNum: dateStr.length >= 7 ? parseInt(dateStr.substring(5, 7)) : 0
                                    readonly property var months: ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                                    readonly property string monthStr: monthNum > 0 && monthNum <= 12 ? months[monthNum] : ""

                                    implicitWidth: 44
                                    Layout.fillHeight: true
                                    radius: Appearance.rounding.small
                                    color: Qt.alpha(eventCard.accentColor, 0.15)

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 0

                                        // Day number (big)
                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: parent.parent.day.toString()
                                            font.weight: Font.Medium
                                            color: eventCard.accentColor
                                        }

                                        // Month (3 letters)
                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: parent.parent.monthStr
                                            font.weight: Font.Medium
                                            color: eventCard.accentColor
                                        }
                                    }
                                }
                            }
                        }
                    }




                    // ───────────────────────────────────────────────
                    // ACTION BUTTONS (Grid layout)
                    // ───────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        // See all events button
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
                                    text: qsTr("%1 Events").arg(Holidays.thisMonthEvents.length)
                                    font.pointSize: Appearance.font.size.smaller
                                    color: Colours.palette.m3primary
                                }
                            }

                            StateLayer {
                                radius: Appearance.rounding.small
                                color: Colours.palette.m3primary
                                function onClicked(): void {
                                    rootWrapper.eventsListMode = true;
                                    // Auto-scroll to current/upcoming event after slide
                                    scrollToCurrentTimer.restart();
                                }
                            }
                        }
                    }

                }
            }

            // Timer to auto-scroll to current event after slide animation
            Timer {
                id: scrollToCurrentTimer
                interval: 400  // Wait for slide animation
                onTriggered: {
                    // Find first non-past event
                    const events = Holidays.thisMonthEvents;
                    let targetIndex = 0;
                    for (let i = 0; i < events.length; i++) {
                        if (!events[i].isPast) {
                            targetIndex = i;
                            break;
                        }
                    }
                    // Scroll to that item (52px per item + 8px spacing)
                    const targetY = targetIndex * 60;
                    eventsFlickable.contentY = Math.min(targetY, eventsFlickable.contentHeight - eventsFlickable.height);
                }
            }

            // ═══════════════════════════════════════════════════
            // PANEL 1: Full Month Events List
            // ═══════════════════════════════════════════════════
            ColumnLayout {
                // Same width as Panel 0 for consistent horizontal slide
                Layout.preferredWidth: rootWrapper.popoutWidth
                Layout.fillHeight: true
                spacing: Appearance.spacing.small

                // Back header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.small
                    spacing: Appearance.spacing.small

                    StyledRect {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: Appearance.rounding.full
                        color: "transparent"

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "arrow_back"
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurface
                        }

                        StateLayer {
                            radius: Appearance.rounding.full
                            function onClicked(): void {
                                rootWrapper.eventsListMode = false;
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("All Events")
                        font.pointSize: Appearance.font.size.normal
                        font.weight: Font.DemiBold
                        color: Colours.palette.m3onSurface
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: Qt.locale().monthName(new Date().getMonth())
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colours.palette.m3outlineVariant
                }

                // Events list
                Flickable {
                    id: eventsFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: eventsColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: eventsColumn
                        width: parent.width
                        spacing: Appearance.spacing.small

                        Repeater {
                            model: Holidays.thisMonthEvents

                            StyledRect {
                                id: monthEventCard
                                required property var modelData
                                required property int index

                                readonly property bool isNational: modelData?.isNationalHoliday ?? false
                                readonly property color accentColor: isNational ? Colours.palette.m3primary : Colours.palette.m3outline

                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.padding.small
                                Layout.rightMargin: Appearance.padding.small
                                implicitHeight: 52
                                radius: Appearance.rounding.small
                                opacity: modelData?.isPast ? 0.5 : 1.0
                                color: modelData?.isToday 
                                    ? Qt.alpha(accentColor, 0.25)
                                    : Qt.alpha(accentColor, isNational ? 0.15 : 0.1)
                                border.width: modelData?.isToday ? 2 : 1
                                border.color: modelData?.isToday 
                                    ? accentColor
                                    : Qt.alpha(accentColor, 0.2)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Appearance.padding.small
                                    spacing: Appearance.spacing.normal

                                    Rectangle {
                                        width: 4
                                        Layout.fillHeight: true
                                        radius: 2
                                        color: monthEventCard.accentColor
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: monthEventCard.modelData?.name ?? ""
                                            font.pointSize: Appearance.font.size.normal
                                            font.weight: Font.Medium
                                            color: Colours.palette.m3onSurface
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        StyledText {
                                            text: `${monthEventCard.modelData?.dayName ?? ""} ${monthEventCard.modelData?.displayDate ?? ""}`
                                            font.pointSize: Appearance.font.size.smaller
                                            color: monthEventCard.accentColor
                                        }
                                    }

                                    MaterialIcon {
                                        text: monthEventCard.modelData?.isToday ? "today" : (monthEventCard.isNational ? "flag" : "event")
                                        font.pointSize: Appearance.font.size.large
                                        color: monthEventCard.accentColor
                                    }
                                }
                            }
                        }

                        // Empty state
                        Item {
                            visible: Holidays.thisMonthEvents.length === 0
                            Layout.fillWidth: true
                            implicitHeight: 120

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.normal

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "beach_access"
                                    font.pointSize: 40
                                    color: Colours.palette.m3tertiary
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("No holidays this month")
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }

                        // Bottom padding
                        Item { implicitHeight: Appearance.padding.normal }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // INLINE COMPONENTS
    // ═══════════════════════════════════════════════════

    component UpcomingEventCard: StyledRect {
        id: upcomingCard

        property var event: null
        signal clicked()

        readonly property bool isNational: event?.isNationalHoliday ?? false
        readonly property color accentColor: isNational ? Colours.palette.m3primary : Colours.palette.m3tertiary

        implicitHeight: 48
        radius: Appearance.rounding.small
        color: Qt.alpha(accentColor, 0.1)
        border.width: 1
        border.color: Qt.alpha(accentColor, 0.2)

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.normal

            // Date badge
            StyledRect {
                implicitWidth: 40
                implicitHeight: 36
                radius: Appearance.rounding.small
                color: Qt.alpha(upcomingCard.accentColor, 0.2)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: upcomingCard.event?.displayDate?.split(" ")[0] ?? ""
                        font.pointSize: Appearance.font.size.normal
                        font.weight: Font.DemiBold
                        color: upcomingCard.accentColor
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: upcomingCard.event?.displayDate?.split(" ")[1] ?? ""
                        font.pointSize: Appearance.font.size.smaller
                        color: upcomingCard.accentColor
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: upcomingCard.event?.name ?? ""
                    font.pointSize: Appearance.font.size.normal
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    text: upcomingCard.event?.localName ?? ""
                    font.pointSize: Appearance.font.size.smaller
                    color: upcomingCard.accentColor
                }
            }

            MaterialIcon {
                text: upcomingCard.isNational ? "flag" : "event"
                font.pointSize: Appearance.font.size.large
                color: upcomingCard.accentColor
            }
        }

        StateLayer {
            radius: Appearance.rounding.small
            color: upcomingCard.accentColor
            function onClicked(): void {
                upcomingCard.clicked();
            }
        }
    }
}
