pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

// Dashboard Icons - 3 icons (Dash, Media, Performance) for popouts
// Uses HOVER to show popouts (like StatusIcons)
StyledRect {
    id: root

    required property Item bar
    required property PersistentProperties visibilities
    required property var popouts

    readonly property alias items: iconsColumn

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding
    
    clip: true
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: iconsColumn.implicitHeight + Config.border.thickness * 2

    ColumnLayout {
        id: iconsColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.border.thickness

        spacing: Appearance.spacing.smaller / 2

        WrappedLoader {
            name: "dash"
            active: true

            sourceComponent: MaterialIcon {
                text: "dashboard"
                color: root.popouts.currentName === "dash" ? 
                       Colours.palette.m3primary : Colours.palette.m3secondary
            }
        }

        WrappedLoader {
            name: "media"
            active: true

            sourceComponent: MaterialIcon {
                text: "music_note"
                color: root.popouts.currentName === "media" ? 
                       Colours.palette.m3primary : Colours.palette.m3secondary
            }
        }

        WrappedLoader {
            name: "performance"
            active: true

            sourceComponent: MaterialIcon {
                text: "monitoring"
                color: root.popouts.currentName === "performance" ? 
                       Colours.palette.m3primary : Colours.palette.m3secondary
            }
        }
    }

    component WrappedLoader: Loader {
        required property string name

        Layout.alignment: Qt.AlignHCenter
        asynchronous: true
        visible: active
    }
}
