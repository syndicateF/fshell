pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import "calendar"  // Import modular components

// CalendarPopout - Horizontal Slide Design
// Container only - content delegated to child components
Item {
    id: rootWrapper

    required property Item wrapper

    // Font-based width for DPI scaling
    readonly property real popoutWidth: Appearance.font.size.normal * 21
    implicitWidth: popoutWidth
    implicitHeight: mainContent.implicitHeight

    // Toggle between main view and events list
    property bool eventsListMode: false

    // Refresh weather/holidays when popout opens
    // UI emits reason, backend decides based on policy
    onVisibleChanged: {
        if (visible) {
            Weather.triggerRefresh("popout");
            Holidays.triggerRefresh("popout");
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
            // PANEL 0: Main Content
            // ═══════════════════════════════════════════════════
            Item {
                id: mainPanel
                Layout.preferredWidth: rootWrapper.popoutWidth
                Layout.preferredHeight: mainContent.implicitHeight

                ColumnLayout {
                    id: mainContent
                    anchors.fill: parent
                    spacing: Appearance.spacing.small

                    // Weather section
                    WeatherHero {
                        Layout.fillWidth: true
                    }

                    // 7-day week strip
                    CalendarStrip {
                        Layout.fillWidth: true
                    }

                    // Upcoming events + action button
                    UpcomingEvents {
                        Layout.fillWidth: true
                        onOpenEventsListRequested: {
                            rootWrapper.eventsListMode = true;
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════
            // PANEL 1: Events List
            // ═══════════════════════════════════════════════════
            EventsListPanel {
                panelWidth: rootWrapper.popoutWidth
                onBackRequested: {
                    rootWrapper.eventsListMode = false;
                }
            }
        }
    }
}
