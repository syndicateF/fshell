pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

/**
 * MediaBottomActions - Open app / Player selector / Quit buttons
 * 
 * Usage:
 *   MediaBottomActions {
 *       player: Players.active
 *       playerList: Players.list
 *       accentColor: MediaPalette.accent
 *       onPlayerSelected: player => Players.manualActive = player
 *       onRaiseRequested: visibilities.overview = false
 *   }
 */
StyledRect {
    id: root
    
    // ========== Properties ==========
    property MprisPlayer player: null
    property list<MprisPlayer> playerList: []
    property color accentColor: Colours.palette.m3primary
    
    // ========== Signals ==========
    signal playerSelected(MprisPlayer player)
    signal raiseRequested()
    
    Layout.alignment: Qt.AlignHCenter
    implicitWidth: bottomRow.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: bottomRow.implicitHeight + Appearance.padding.small * 2
    
    RowLayout {
        id: bottomRow
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        // Open in app
        IconButton {
            type: IconButton.Text
            icon: "open_in_new"
            font.pointSize: Appearance.font.size.normal
            padding: Appearance.padding.small
            disabled: !root.player?.canRaise
            onClicked: {
                root.player?.raise();
                root.raiseRequested();
            }
        }

        // Player selector
        SplitButton {
            id: playerSelector
            disabled: !root.playerList.length
            active: menuItems.find(m => m.modelData === root.player) ?? menuItems[0]
            menu.onItemSelected: item => root.playerSelected(item.modelData)
            menuItems: playerListVariants.instances
            fallbackIcon: "music_off"
            fallbackText: qsTr("No players")
            label.Layout.maximumWidth: 80
            label.elide: Text.ElideRight
            label.font.pointSize: Appearance.font.size.small
            stateLayer.disabled: false
            menuOnTop: true
            colour: root.accentColor

            Variants {
                id: playerListVariants
                model: root.playerList

                MenuItem {
                    required property MprisPlayer modelData
                    icon: modelData === root.player ? "check" : ""
                    text: Players.getIdentity(modelData)
                    activeIcon: "play_circle"
                }
            }
        }

        // Quit player
        IconButton {
            type: IconButton.Text
            icon: "close"
            font.pointSize: Appearance.font.size.normal
            padding: Appearance.padding.small
            disabled: !root.player?.canQuit
            onClicked: root.player?.quit()
        }
    }
}
