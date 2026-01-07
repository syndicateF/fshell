pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// WeatherHero - Weather display section for CalendarPopout
// Shows date, temperature, description, location, humidity
StyledRect {
    id: root

    Layout.fillWidth: true
    implicitHeight: heroContent.height + Appearance.padding.normal * 2
    radius: Appearance.rounding.small
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: heroContent
        width: parent.width - Appearance.padding.normal * 2
        x: Appearance.padding.normal
        y: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        // Date header row: Day name (left) | Month + Date + Year (right)
        RowLayout {
            Layout.fillWidth: true
            
            // Day name (e.g., "Monday")
            StyledText {
                text: Qt.formatDate(new Date(), "dddd")
                font.pointSize: Appearance.font.size.small
                font.weight: Font.Medium
                color: Colours.palette.m3onSurfaceVariant
            }
            
            Item { Layout.fillWidth: true }
            
            // Month + Date + Year (e.g., "January 6, 2026")
            StyledText {
                text: Qt.formatDate(new Date(), "MMMM d, yyyy")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
            }
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
        }
    }
}
