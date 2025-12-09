import qs.components
import qs.components.filedialog
import qs.services
import qs.config
import "dash"
import Quickshell
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    property PersistentProperties visibilities: null
    property PersistentProperties state: null
    property var facePicker: null

    // Fallback state for when state is null (e.g., from popout)
    readonly property QtObject effectiveState: state ?? fallbackState

    QtObject {
        id: fallbackState
        property date currentDate: new Date()
        property int currentTab: 0
    }

    rowSpacing: Appearance.spacing.normal
    columnSpacing: Appearance.spacing.normal

    Rect {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: user.implicitWidth
        Layout.preferredHeight: user.implicitHeight

        User {
            id: user

            visibilities: root.visibilities
            state: root.effectiveState
            facePicker: root.facePicker
        }
    }

    Rect {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Config.overview.sizes.weatherWidth
        Layout.fillHeight: true

        Weather {}
    }

    Rect {
        Layout.row: 1
        Layout.preferredWidth: dateTime.implicitWidth
        Layout.fillHeight: true

        DateTime {
            id: dateTime
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: calendar.implicitHeight

        Calendar {
            id: calendar

            state: root.effectiveState
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        Resources {
            id: resources
        }
    }

    Rect {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 2
        Layout.preferredWidth: media.implicitWidth
        Layout.fillHeight: true

        Media {
            id: media
        }
    }

    component Rect: StyledRect {
        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer
    }
}
