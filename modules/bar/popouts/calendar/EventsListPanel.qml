pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import "."  // Import EventCard from same directory

// EventsListPanel - Full events list for Panel 1
// Shows month or year events with tab toggle
ColumnLayout {
    id: root

    // Required: popout width for proper sizing
    required property real panelWidth

    // Signal emitted when user clicks back button
    signal backRequested()

    Layout.preferredWidth: panelWidth
    Layout.fillHeight: true
    spacing: Appearance.spacing.small

    // Toggle between month and all year view
    property bool showAllYear: false

    // Header with centered horizontal icon+text tabs
    Item {
        Layout.fillWidth: true
        implicitHeight: 44

        // Back button (left)
        StyledRect {
            id: backButton
            x: Appearance.padding.small
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 28
            implicitHeight: 28
            radius: Appearance.rounding.full
            color: "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                text: "arrow_back"
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurface
            }

            StateLayer {
                radius: Appearance.rounding.full
                function onClicked(): void {
                    root.backRequested();
                }
            }
        }

        // Centered tabs container
        Row {
            id: tabsRow
            anchors.centerIn: parent
            spacing: Appearance.spacing.large * 3

            // This Month tab
            Item {
                id: monthTab
                width: monthTabRow.implicitWidth
                height: monthTabRow.implicitHeight

                Row {
                    id: monthTabRow
                    spacing: Appearance.spacing.smaller

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "calendar_today"
                        font.pointSize: Appearance.font.size.normal
                        color: !root.showAllYear ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                        Behavior on color {
                            ColorAnimation { duration: Appearance.anim.durations.small }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.locale().monthName(new Date().getMonth(), Locale.ShortFormat)
                        font.pointSize: Appearance.font.size.small
                        font.weight: !root.showAllYear ? Font.Medium : Font.Normal
                        color: !root.showAllYear ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                        Behavior on color {
                            ColorAnimation { duration: Appearance.anim.durations.small }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showAllYear = false
                }
            }

            // All Year tab
            Item {
                id: yearTab
                width: yearTabRow.implicitWidth
                height: yearTabRow.implicitHeight

                Row {
                    id: yearTabRow
                    spacing: Appearance.spacing.smaller

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "event_note"
                        font.pointSize: Appearance.font.size.normal
                        color: root.showAllYear ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                        Behavior on color {
                            ColorAnimation { duration: Appearance.anim.durations.small }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: new Date().getFullYear().toString()
                        font.pointSize: Appearance.font.size.small
                        font.weight: root.showAllYear ? Font.Medium : Font.Normal
                        color: root.showAllYear ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                        Behavior on color {
                            ColorAnimation { duration: Appearance.anim.durations.small }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showAllYear = true
                }
            }
        }

        // Full-width separator line (background)
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        // Sliding underline indicator (overlaps separator)
        Rectangle {
            id: underlineIndicator
            height: 2
            radius: 1
            color: Colours.palette.m3primary
            anchors.bottom: parent.bottom

            // Animate position and width
            x: root.showAllYear ? yearTab.x + tabsRow.x : monthTab.x + tabsRow.x
            width: root.showAllYear ? yearTab.width : monthTab.width

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.anim.durations.small
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: Appearance.anim.durations.small
                    easing.type: Easing.OutCubic
                }
            }
        }
    }


    // Events list (scrollable)
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
                model: root.showAllYear ? Holidays.allEvents : Holidays.thisMonthEvents

                EventCard {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.padding.small
                    Layout.rightMargin: Appearance.padding.small
                    eventData: modelData
                    showCountdown: false  // No countdown in list view
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
