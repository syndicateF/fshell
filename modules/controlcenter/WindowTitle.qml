import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

StyledRect {
    id: root

    required property ShellScreen screen
    required property Session session

    implicitHeight: text.implicitHeight + Appearance.padding.large * 2
    color: Colours.tPalette.m3surfaceContainer

    StyledText {
        id: text

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        text: qsTr("Caelestia Settings - %1").arg(root.session.active)
        font.capitalization: Font.Capitalize
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    Item {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Appearance.padding.normal

        implicitWidth: implicitHeight
        implicitHeight: closeIcon.implicitHeight + Appearance.padding.normal

        StateLayer {
            radius: Appearance.rounding.full

            function onClicked(): void {
                QsWindow.window.destroy();
            }
        }

        MaterialIcon {
            id: closeIcon

            anchors.centerIn: parent
            text: "close"
        }
    }
}
