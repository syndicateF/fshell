pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// CalendarPopout - Timeline design with Glassmorphism schedule cards
// Follows same pattern as Bluetooth.qml and PowerProfile.qml
Item {
    id: rootWrapper

    required property Item wrapper

    readonly property real maxPopoutHeight: 550
    readonly property real contentHeight: root.implicitHeight

    implicitWidth: root.implicitWidth
    implicitHeight: Math.min(contentHeight, maxPopoutHeight)

    // Services now use reactive FileView with inotify-based watching
    // No manual reload needed - data updates automatically

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: root.implicitWidth
        contentHeight: root.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: flickable.contentHeight > flickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        }

        ColumnLayout {
            id: root
            width: flickable.width

            // Forward wrapper from parent
            readonly property Item wrapper: rootWrapper.wrapper

            // Toggle for THIS MONTH expanded view
            property bool showMonthEvents: false

            // Calendar state
            property date currentDate: new Date()
            readonly property int currentMonth: currentDate.getMonth()
            readonly property int currentYear: currentDate.getFullYear()
            readonly property int todayDate: new Date().getDate()
            readonly property int todayMonth: new Date().getMonth()
            readonly property int todayYear: new Date().getFullYear()

            spacing: Appearance.spacing.small

            // ═══════════════════════════════════════════════════
            // iOS Drag Handle (slides up when month expanded)
            // ═══════════════════════════════════════════════════
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 48
                implicitHeight: root.showMonthEvents ? 0 : 16
                clip: true


                Behavior on implicitHeight {
                    NumberAnimation { duration: 350; easing.type: Easing.OutBack }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 36
                    height: 4
                    radius: 2
                    color: Colours.palette.m3outlineVariant
                }

                StateLayer {
                    radius: Appearance.rounding.small
                    function onClicked(): void {
                        root.wrapper.detach("calendar");
                    }
                }
            }

    // ═══════════════════════════════════════════════════
    // WEATHER HERO - Weather-focused with month/date info
    // ═══════════════════════════════════════════════════
    StyledRect {
        id: heroSection
        Layout.fillWidth: true
        implicitWidth: 280
        implicitHeight: root.showMonthEvents ? 0 : (heroContent.height + Appearance.padding.normal * 2)
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainerHigh
        clip: true



        Behavior on implicitHeight {
            NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }

        ColumnLayout {
            id: heroContent
            width: parent.width - Appearance.padding.normal * 2
            x: Appearance.padding.normal
            y: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            // Month and Date header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    text: Qt.locale().monthName(root.currentMonth) + " " + root.currentYear
                    font.pointSize: Appearance.font.size.normal
                    font.weight: Font.DemiBold
                    color: Colours.palette.m3primary
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: Qt.formatDate(root.currentDate, "dddd, d")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Main weather row
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                // Weather icon (large)
                MaterialIcon {
                    animate: true
                    text: Weather.icon
                    font.pointSize: 36
                    color: Weather.hasError ? Colours.palette.m3error : Colours.palette.m3tertiary
                }

                // Temperature and description
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

                Item { Layout.fillWidth: true }

                // Humidity
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

                Rectangle {
                    width: 1
                    height: 12
                    color: Colours.palette.m3outlineVariant
                }

                // Feels like
                Row {
                    spacing: 4

                    MaterialIcon {
                        text: "thermostat"
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                    }

                    StyledText {
                        text: Weather.feelsLike
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                    }
                }
            }
        }

        // Weather reload moved to rootWrapper.Component.onCompleted
    }

    // NOTE: Offline banner removed - was confusing because it showed on 
    // helper failures at startup, not actual network issues. 
    // Data is displayed from cache regardless.

    // ═══════════════════════════════════════════════════
    // WEEK VIEW STRIP (slides up when month expanded)
    // ═══════════════════════════════════════════════════
    RowLayout {
        id: weekSection
        Layout.fillWidth: true
        implicitHeight: root.showMonthEvents ? 0 : undefined
        spacing: 4
        clip: true



        Behavior on implicitHeight {
            NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }

        Repeater {
            model: 7

            StyledRect {
                id: dayItem
                required property int index

                readonly property int dayOffset: index - 3
                readonly property date dayDate: {
                    const d = new Date();
                    d.setDate(d.getDate() + dayOffset);
                    return d;
                }
                readonly property int dayNum: dayDate.getDate()
                readonly property bool isToday: dayOffset === 0
                readonly property bool isHoliday: Holidays.hasEvent(dayDate)
                readonly property bool isSunday: dayDate.getDay() === 0
                
                // Opacity decreases with distance from today (1.0 → 0.5)
                readonly property real distanceOpacity: 1.0 - (Math.abs(dayOffset) * 0.15)

                Layout.fillWidth: true
                implicitHeight: 52
                radius: Appearance.rounding.small
                color: isToday ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh
                // Background always full opacity

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    // Apply opacity to text only, not background
                    opacity: dayItem.isToday ? 1.0 : dayItem.distanceOpacity

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const d = new Date();
                            d.setDate(d.getDate() + dayItem.dayOffset);
                            return Qt.locale().dayName(d.getDay()).substring(0, 1);
                        }
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

                    // Holiday dot indicator
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        visible: dayItem.isHoliday
                        width: 4
                        height: 4
                        radius: 2
                        color: dayItem.isToday ? Colours.palette.m3onPrimary : Colours.palette.m3tertiary
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    // SCHEDULE SECTION - Glassmorphism cards
    // ═══════════════════════════════════════════════════
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        StyledText {
            text: qsTr("TODAY")
            font.pointSize: Appearance.font.size.smaller
            font.weight: Font.Medium
            font.letterSpacing: 2
            color: Colours.palette.m3outline
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }
    }

    // Schedule cards container - dynamic from Planify + Holidays (slides up when month expanded)
    ColumnLayout {
        id: scheduleSection
        Layout.fillWidth: true
        implicitHeight: root.showMonthEvents ? 0 : undefined
        spacing: Appearance.spacing.small
        clip: true



        Behavior on implicitHeight {
            NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }

        // Planify reload moved to rootWrapper.Component.onCompleted

        // Today's holiday card (if any)
        StyledRect {
            id: holidayCard
            readonly property var todayEvent: Holidays.getTodayEvent()
            readonly property var eventMeta: Holidays.getEventMeta(todayEvent)
            
            visible: todayEvent !== null
            Layout.fillWidth: true
            implicitHeight: visible ? 52 : 0
            radius: Appearance.rounding.small
            color: Qt.alpha(holidayCard.eventMeta?.color ?? Colours.palette.m3outline, 0.2)
            border.width: 1
            border.color: Qt.alpha(holidayCard.eventMeta?.color ?? Colours.palette.m3outline, 0.3)

            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.padding.small
                spacing: Appearance.spacing.normal

                Rectangle {
                    width: 4
                    Layout.fillHeight: true
                    radius: 2
                    color: holidayCard.eventMeta?.color ?? Colours.palette.m3outline
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: holidayCard.todayEvent?.name ?? ""
                        font.pointSize: Appearance.font.size.normal
                        font.weight: Font.Medium
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    StyledText {
                        text: holidayCard.todayEvent?.isNationalHoliday ? qsTr("National Holiday") : qsTr("Observance")
                        font.pointSize: Appearance.font.size.smaller
                        color: holidayCard.eventMeta?.color ?? Colours.palette.m3outline
                    }
                }

                MaterialIcon {
                    text: holidayCard.eventMeta?.icon ?? "event"
                    font.pointSize: Appearance.font.size.large
                    color: holidayCard.eventMeta?.color ?? Colours.palette.m3outline
                }
            }
        }

        // Dynamic task cards from Planify
        Repeater {
            model: Planify.todayTasks.length > 0 ? Planify.todayTasks : [null]

            StyledRect {
                id: taskCard
                required property var modelData
                required property int index

                readonly property bool isEmpty: modelData === null
                readonly property var priorityColors: [
                    Colours.palette.m3outline,      // Priority 1 (low)
                    Colours.palette.m3primary,      // Priority 2 
                    Colours.palette.m3tertiary,     // Priority 3
                    Colours.palette.m3error         // Priority 4 (high)
                ]

                Layout.fillWidth: true
                implicitHeight: 52
                radius: Appearance.rounding.small
                color: Colours.palette.m3surfaceContainerHigh
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3onSurface, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.small
                    spacing: Appearance.spacing.normal

                    Rectangle {
                        width: 4
                        Layout.fillHeight: true
                        radius: 2
                        color: taskCard.isEmpty 
                            ? Colours.palette.m3primary 
                            : taskCard.priorityColors[Math.min((taskCard.modelData?.priority ?? 1) - 1, 3)]
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: taskCard.isEmpty ? qsTr("No upcoming tasks") : taskCard.modelData.content
                            font.pointSize: Appearance.font.size.normal
                            font.weight: Font.Medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        StyledText {
                            visible: taskCard.isEmpty || taskCard.modelData?.dueDate
                            text: taskCard.isEmpty 
                                ? qsTr("Enjoy your day!") 
                                : (taskCard.modelData?.isToday ? qsTr("Today") : taskCard.modelData?.dueDate ?? "")
                            font.pointSize: Appearance.font.size.smaller
                            color: Colours.palette.m3outline
                        }
                    }

                    MaterialIcon {
                        text: taskCard.isEmpty ? "event_available" : "task_alt"
                        font.pointSize: Appearance.font.size.large
                        color: taskCard.isEmpty 
                            ? Colours.palette.m3primary 
                            : taskCard.priorityColors[Math.min((taskCard.modelData?.priority ?? 1) - 1, 3)]
                    }
                }
            }
        }

        // Add event button (placeholder)
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Appearance.rounding.small
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3primary, 0.3)

            RowLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.smaller

                MaterialIcon {
                    text: "add"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3primary
                }

                StyledText {
                    text: qsTr("Open Calendar")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3primary
                }
            }

            StateLayer {
                radius: Appearance.rounding.small
                color: Colours.palette.m3primary
                function onClicked(): void {
                    Quickshell.execDetached(["app2unit", "--", "io.github.alainm23.planify"]);
                }
            }
        }

        // ═══════════════════════════════════════════════════
        // THIS MONTH TOGGLE BUTTON (always visible)
        // ═══════════════════════════════════════════════════
        RowLayout {
            id: monthToggleHeader
            visible: Holidays.thisMonthEvents.length > 0
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.normal
            spacing: Appearance.spacing.small

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colours.palette.m3outlineVariant
            }

            // Toggle button - always visible
            StyledRect {
                implicitWidth: monthToggleRow.implicitWidth + Appearance.padding.normal
                implicitHeight: monthToggleRow.implicitHeight + Appearance.padding.smaller
                radius: Appearance.rounding.full
                color: root.showMonthEvents ? Qt.alpha(Colours.palette.m3primary, 0.15) : "transparent"
                border.width: 1
                border.color: root.showMonthEvents 
                    ? Colours.palette.m3primary 
                    : Qt.alpha(Colours.palette.m3outline, 0.3)

                Row {
                    id: monthToggleRow
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: root.showMonthEvents 
                            ? qsTr("HIDE") 
                            : `${Holidays.thisMonthEvents.length} ${qsTr("HOLIDAYS")}`
                        font.pointSize: Appearance.font.size.smaller
                        font.weight: Font.Medium
                        font.letterSpacing: 1
                        color: root.showMonthEvents ? Colours.palette.m3primary : Colours.palette.m3outline
                    }

                    MaterialIcon {
                        text: "expand_more"
                        font.pointSize: Appearance.font.size.small
                        color: root.showMonthEvents ? Colours.palette.m3primary : Colours.palette.m3outline
                        rotation: root.showMonthEvents ? 180 : 0

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                StateLayer {
                    radius: Appearance.rounding.full
                    color: root.showMonthEvents ? Colours.palette.m3primary : Colours.palette.m3outline
                    function onClicked(): void {
                        root.showMonthEvents = !root.showMonthEvents
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colours.palette.m3outlineVariant
            }
        }

        // ═══════════════════════════════════════════════════
        // THIS MONTH EVENTS (collapsible with gradient scroll)
        // ═══════════════════════════════════════════════════
        Item {
            id: monthEventsContainer
            Layout.fillWidth: true
            visible: Holidays.thisMonthEvents.length > 0
            implicitHeight: root.showMonthEvents ? Math.min(monthEventsFlickable.contentHeight, 280) : 0
            clip: true

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            // Scrollable events list
            Flickable {
                id: monthEventsFlickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: monthEventsColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds // No overscroll!

                ColumnLayout {
                    id: monthEventsColumn
                    width: parent.width
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: Holidays.thisMonthEvents

                        StyledRect {
                            id: monthHolidayItem
                            required property var modelData
                            required property int index

                            readonly property bool isNational: modelData?.isNationalHoliday ?? false
                            readonly property color accentColor: isNational ? Colours.palette.m3primary : Colours.palette.m3outline

                            Layout.fillWidth: true
                            implicitHeight: 48
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
                                    color: monthHolidayItem.accentColor
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: monthHolidayItem.modelData?.name ?? ""
                                        font.pointSize: Appearance.font.size.normal
                                        font.weight: Font.Medium
                                        color: Colours.palette.m3onSurface
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }

                                    StyledText {
                                        text: `${monthHolidayItem.modelData?.dayName ?? ""} ${monthHolidayItem.modelData?.displayDate ?? ""}`
                                        font.pointSize: Appearance.font.size.smaller
                                        color: monthHolidayItem.accentColor
                                    }
                                }

                                MaterialIcon {
                                    text: monthHolidayItem.modelData?.isToday ? "today" : (monthHolidayItem.isNational ? "flag" : "event")
                                    font.pointSize: Appearance.font.size.large
                                    color: monthHolidayItem.accentColor
                                }
                            }
                        }
                    }
                }
            }

            // Top gradient overlay (fade effect)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20
                visible: monthEventsFlickable.contentY > 0
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Colours.palette.m3surface }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Bottom gradient overlay (fade effect)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20
                visible: monthEventsFlickable.contentY < (monthEventsFlickable.contentHeight - monthEventsFlickable.height)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Colours.palette.m3surface }
                }
            }
        }
        }  // Extra brace for schedule cards container
    }  // ColumnLayout root
    }  // Flickable
}  // Item rootWrapper
