import "../services"
import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property Schemes.Scheme modelData
    required property int index
    required property PersistentProperties visibilities
    required property bool isSelected

    signal clicked()
    signal hovered()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
        onEntered: root.hovered()
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        anchors.topMargin: Appearance.padding.small
        anchors.bottomMargin: Appearance.padding.small
        spacing: Appearance.spacing.normal

        // Color preview circle
        StyledRect {
            id: preview

            anchors.verticalCenter: parent.verticalCenter

            border.width: 1
            border.color: Qt.alpha(`#${root.modelData?.colours?.outline}`, 0.5)

            color: `#${root.modelData?.colours?.surface}`
            radius: Appearance.rounding.full
            implicitWidth: 24
            implicitHeight: 24

            Item {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right

                implicitWidth: parent.implicitWidth / 2
                clip: true

                StyledRect {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right

                    implicitWidth: preview.implicitWidth
                    color: `#${root.modelData?.colours?.primary}`
                    radius: Appearance.rounding.full
                }
            }
        }

        Text {
            text: `${root.modelData?.name ?? ""} ${root.modelData?.flavour ?? ""}`
            // EXACT same style as ActiveWindow title
            font.pixelSize: 15
            font.family: Appearance.font.family.sans
            font.hintingPreference: Font.PreferDefaultHinting
            font.variableAxes: ({ "wght": 450, "wdth": 100 })
            color: root.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            width: parent.width - preview.width - parent.spacing - (current.visible ? current.width + Appearance.spacing.normal : 0)

            anchors.verticalCenter: parent.verticalCenter
        }

        MaterialIcon {
            id: current

            visible: `${root.modelData?.name} ${root.modelData?.flavour}` === Schemes.currentScheme
            text: "check"
            color: root.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
            font.pointSize: 16

            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
