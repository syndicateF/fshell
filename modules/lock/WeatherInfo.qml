pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Lock Weather Widget - Option B: Horizontal Split Style
// Icon left, Temp+description middle, Details right
// NO polling - uses cached Weather data from service
RowLayout {
    id: root

    required property int rootHeight

    anchors.fill: parent
    anchors.margins: Appearance.padding.large
    spacing: Appearance.spacing.large

    // ═══════════════════════════════════════════════════
    // LEFT: Large icon in box
    // ═══════════════════════════════════════════════════
    StyledRect {
        implicitWidth: Appearance.font.size.extraLarge * 2.5
        implicitHeight: implicitWidth
        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainerHigh

        MaterialIcon {
            anchors.centerIn: parent
            animate: true
            text: Weather.icon
            font.pointSize: Appearance.font.size.extraLarge
            color: Weather.hasError ? Colours.palette.m3error : Colours.palette.m3tertiary
        }
    }

    // ═══════════════════════════════════════════════════
    // MIDDLE: Temp + description
    // ═══════════════════════════════════════════════════
    ColumnLayout {
        Layout.fillWidth: true
        spacing: -Appearance.spacing.smaller

        StyledText {
            animate: true
            text: Weather.hasData ? Weather.temp : (Weather.loading ? "..." : "--")
            font.pointSize: Appearance.font.size.extraLarge * 1.5
            font.family: Appearance.font.family.clock
            font.weight: Font.Bold
            color: Colours.palette.m3onSurface
        }

        StyledText {
            animate: true
            text: Weather.hasData ? Weather.displayDescription : (Weather.hasError ? qsTr("Offline") : qsTr("Loading..."))
            font.pointSize: Appearance.font.size.normal
            font.family: Appearance.font.family.mono
            font.weight: Font.Medium
            color: Colours.palette.m3tertiary
        }
    }

    // ═══════════════════════════════════════════════════
    // RIGHT: Details column (humidity, feels like, location)
    // ═══════════════════════════════════════════════════
    ColumnLayout {
        visible: Weather.hasData
        spacing: Appearance.spacing.smaller

        // Humidity
        RowLayout {
            spacing: Appearance.spacing.smaller
            MaterialIcon {
                text: "water_drop"
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
            }
            StyledText {
                text: Weather.humidity + "%"
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
            }
        }

        // Feels like
        RowLayout {
            spacing: Appearance.spacing.smaller
            MaterialIcon {
                text: "thermostat"
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
            }
            StyledText {
                text: Weather.feelsLike
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
            }
        }

        RowLayout {
            spacing: Appearance.spacing.smaller
            MaterialIcon {
                text: "location_on"
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
            }
            StyledText {
                animate: true
                text: Weather.city
                font.pointSize: Appearance.font.size.small
                font.family: Appearance.font.family.mono
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }
    }

    // NO POLLING TIMER - uses cached data from Weather service
}
