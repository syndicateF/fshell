import qs.components
import qs.components.controls
import qs.services
import qs.config
import Caelestia
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property StyledTextField search
    required property bool isSelected

    readonly property string math: search.text

    function onClicked(): void {
        Quickshell.execDetached(["wl-copy", Qalculator.eval(math, false)]);
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.smaller

        spacing: Appearance.spacing.smaller

        MaterialIcon {
            text: "function"
            font.pointSize: Appearance.font.size.normal
            color: root.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            id: result

            color: {
                if (text.includes("error: ") || text.includes("warning: "))
                    return Colours.palette.m3error;
                if (!root.math)
                    return root.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant;
                return root.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface;
            }

            text: root.math.length > 0 ? Qalculator.eval(root.math) : qsTr("Type expression")
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.smaller
            font.weight: root.isSelected ? Font.Medium : Font.Normal

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        MaterialIcon {
            text: "content_copy"
            font.pointSize: Appearance.font.size.smaller
            color: Colours.palette.m3tertiary
            Layout.alignment: Qt.AlignVCenter
            visible: root.math.length > 0

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.onClicked()
            }
        }

        MaterialIcon {
            text: "open_in_new"
            font.pointSize: Appearance.font.size.smaller
            color: Colours.palette.m3secondary
            Layout.alignment: Qt.AlignVCenter
            visible: root.math.length > 0

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["app2unit", "--", ...Config.general.apps.terminal, "fish", "-C", `exec qalc -i '${root.math}'`])
            }
        }
    }
}
