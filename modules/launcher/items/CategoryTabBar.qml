pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import qs.services
import qs.utils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var    categories:     []
    property string activeCategory: ""

    signal categoryClicked(string categoryId)
    signal addGroupClicked()

    implicitHeight: 68
    implicitWidth:  parent ? parent.width : 640

    Rectangle {
        anchors.top:         parent.top
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.leftMargin:  Appearance.padding.large
        anchors.rightMargin: Appearance.padding.large
        height:  1
        color:   Colours.palette.m3outlineVariant
        opacity: 0.3
    }

    Flickable {
        id: flickable
        anchors.fill:    parent
        anchors.topMargin: 1
        contentWidth:    tabRow.implicitWidth
        contentHeight:   height
        boundsBehavior:  Flickable.StopAtBounds
        clip:            true
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        Row {
            id: tabRow
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, (flickable.width - implicitWidth) / 2)
            spacing: 0

            Repeater {
                model: root.categories
                delegate: TabItem {
                    required property var modelData
                    tabId:     modelData.id
                    tabName:   modelData.name
                    tabIcon:   modelData.icon || "folder"
                    isActive:  root.activeCategory === modelData.id
                    onTapped:  root.categoryClicked(modelData.id)
                }
            }

            TabItem {
                tabId:    "__add__"
                tabName:  qsTr("Add group")
                tabIcon:  "create_new_folder"
                isActive: false
                isAdd:    true
                onTapped: root.addGroupClicked()
            }
        }
    }

    Rectangle {
        anchors.left:   parent.left
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width:  32
        visible: flickable.contentX > 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Colours.palette.m3surface }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width:  32
        visible: flickable.contentX < flickable.contentWidth - flickable.width - 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Colours.palette.m3surface }
        }
    }

    component TabItem: Item {
        id: tab

        property string tabId:   ""
        property string tabName: ""
        property string tabIcon: "folder"
        property bool   isActive: false
        property bool   isAdd:    false

        signal tapped()

        implicitWidth:  90
        implicitHeight: root.height

        Rectangle {
            anchors.fill:    parent
            anchors.margins: Appearance.padding.smaller
            radius:          Appearance.rounding.normal
            color: tab.isActive
                ? Colours.tPalette.m3surfaceVariant
                : (tabMouse.containsMouse ? Colours.tPalette.m3surfaceVariant : "transparent")
            opacity: tab.isActive ? 1 : (tabMouse.containsMouse ? 0.65 : 0)
            Behavior on opacity { Anim { duration: Appearance.anim.durations.small } }
        }

        MouseArea {
            id: tabMouse
            anchors.fill:  parent
            hoverEnabled:  true
            cursorShape:   Qt.PointingHandCursor
            onClicked:     tab.tapped()
        }

        Column {
            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           tab.tabIcon
                font.pointSize: Appearance.font.size.large
                color: tab.isActive
                    ? (tab.isAdd ? Colours.palette.m3tertiary : Colours.palette.m3primary)
                    : Colours.palette.m3onSurfaceVariant
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           tab.tabName
                font.pointSize: Appearance.font.size.smaller
                font.family:    Appearance.font.family.sans
                color: tab.isActive
                    ? (tab.isAdd ? Colours.palette.m3tertiary : Colours.palette.m3primary)
                    : Colours.palette.m3onSurfaceVariant
                elide:          Text.ElideRight
                width:          tab.implicitWidth - Appearance.padding.small * 2
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
