import qs.components
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
    }
}
