import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Props props
    required property var visibilities

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        // Tab bar
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            TabButton {
                text: qsTr("Notifications")
                icon: "notifications"
                active: true
                badge: Notifs.list.reduce((acc, n) => n.closed ? acc : acc + 1, 0)
            }
        }

        // Content area
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainerLow

            // Notifications panel
            NotifDock {
                visible: true
                props: root.props
                visibilities: root.visibilities
            }
        }

        StyledRect {
            Layout.topMargin: Appearance.padding.large - layout.spacing
            Layout.fillWidth: true
            implicitHeight: 1

            color: Colours.tPalette.m3outlineVariant
        }
    }
}
