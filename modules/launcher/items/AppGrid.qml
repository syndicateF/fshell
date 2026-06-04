pragma ComponentBehavior: Bound

import "../services"
import qs.components
import qs.components.controls
import qs.config
import qs.services
import Quickshell
import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property var appList

    signal appLaunched(var app)

    property string _activeId:  "home"
    property var    _activeApps: []

    property var _tabs: []

    property bool _showAddDialog:    false
    property bool _showRenameDialog: false
    property bool _showDeleteDialog: false
    property string _editGroupId:    ""
    property string _editGroupName:  ""

    function _rebuildTabs() {
        const xdgCats = XdgCategories.buildAutoCategories(root.appList);
        const customGroups = GroupsConfig.groups.map(g => ({
            id:     g.id,
            name:   g.name,
            icon:   g.icon,
            custom: true
        }));
        const homeTab = { id: "home", name: qsTr("Library Home"), icon: "home", custom: false };
        const xdgTabs = xdgCats.map(c => Object.assign({}, c, { custom: false }));
        root._tabs = [homeTab].concat(xdgTabs).concat(customGroups);
        root._refreshApps();
    }

function _refreshApps() {
    const id = root._activeId;
    if (id !== "home" && GroupsConfig.groups.some(g => g.id === id)) {
        const groupAppIds = GroupsConfig.getAppsForGroup(id);
        root._activeApps = root.appList.filter(a => a && groupAppIds.includes(a.id));
    } else {
        root._activeApps = XdgCategories.filterApps(root.appList, id).filter(Boolean);  // ← tambah .filter(Boolean)
    }
}

    function _currentTab() {
        return root._tabs.find(t => t.id === root._activeId) || root._tabs[0] || null;
    }

    onAppListChanged: _rebuildTabs()
    Component.onCompleted: _rebuildTabs()

    Connections {
        target: GroupsConfig
        function onGroupsChanged() { root._rebuildTabs(); }
    }

    Item {
        id: headerRow
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: 56

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:  parent.left
            anchors.leftMargin: Appearance.padding.large
            text: root._currentTab()?.name ?? ""
            font.pointSize: Appearance.font.size.large
            font.bold:      true
            font.family:    Appearance.font.family.sans
            color:          Colours.palette.m3onSurface
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Appearance.padding.large
            spacing: Appearance.spacing.small
            visible: root._currentTab()?.custom === true

            MaterialIcon {
                text: "edit"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root._editGroupId   = root._activeId;
                        root._editGroupName = root._currentTab()?.name ?? "";
                        root._showRenameDialog = true;
                    }
                }
            }

            MaterialIcon {
                text: "delete"
                color: Colours.palette.m3error
                font.pointSize: Appearance.font.size.normal
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root._editGroupId = root._activeId;
                        root._showDeleteDialog = true;
                    }
                }
            }
        }
    }

    GridView {
        id: grid
        anchors.top:    headerRow.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: tabBar.top
        anchors.topMargin:    Appearance.padding.small
        anchors.leftMargin:   Appearance.padding.normal
        anchors.rightMargin:  Appearance.padding.normal
        anchors.bottomMargin: Appearance.padding.small

        clip:           true
        readonly property int columnCount: Math.floor(width / 96) || 1
        cellWidth:  Math.floor(width / columnCount)
        cellHeight: 110
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel {
            values: root._activeApps
        }

delegate: GridItemDelegate {
    isSelected: grid.currentIndex === index
    onClicked: {
        grid.currentIndex = index;
        if (modelData) root.appLaunched(modelData);
    }
    onHovered: grid.currentIndex = index
}

        Item {
            anchors.centerIn: parent
            visible: grid.count === 0

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "folder_open"
                    font.pointSize: Appearance.font.size.large * 2
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.5
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No apps in this group")
                    font.pointSize: Appearance.font.size.normal
                    font.family:    Appearance.font.family.sans
                    color:          Colours.palette.m3onSurfaceVariant
                    opacity:        0.7
                }
            }
        }
    }

    CategoryTabBar {
        id: tabBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right

        categories:     root._tabs
        activeCategory: root._activeId

        onCategoryClicked: categoryId => {
            root._activeId = categoryId;
            root._refreshApps();
        }
        onAddGroupClicked: {
            root._editGroupName = "";
            root._showAddDialog = true;
        }
    }

    Item {
        anchors.fill: parent
        visible:      root._showAddDialog
        z:            100

        Rectangle {
            anchors.fill: parent
            color:        Qt.rgba(0, 0, 0, 0.5)
            MouseArea { anchors.fill: parent; onClicked: root._showAddDialog = false }
        }

        Rectangle {
            anchors.centerIn: parent
            width:  320
            height: dialogAddCol.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.large
            color:  Colours.palette.m3surfaceContainer

            Column {
                id: dialogAddCol
                anchors {
                    left:   parent.left
                    right:  parent.right
                    top:    parent.top
                    margins: Appearance.padding.large
                }
                spacing: Appearance.spacing.normal

                Text {
                    text: qsTr("New Group")
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurface
                }

                StyledTextField {
                    id: addGroupField
                    width: parent.width
                    placeholderText: qsTr("Group name…")
                    text: root._editGroupName
                    onTextChanged: root._editGroupName = text
                    Keys.onReturnPressed: _confirmAdd()
                    Keys.onEscapePressed: root._showAddDialog = false
                    Component.onCompleted: if (root._showAddDialog) forceActiveFocus()
                }

                Text {
                    text: qsTr("Icon")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                    font.family: Appearance.font.family.sans
                }

                property string _pickedIcon: "folder"

                Row {
                    spacing: Appearance.spacing.small
                    Repeater {
                        model: ["folder", "code", "public", "sports_esports", "palette", "build", "school", "movie", "description", "computer"]
                        delegate: Item {
                            required property string modelData
                            width: 36; height: 36
                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.small
                                color: dialogAddCol._pickedIcon === modelData
                                    ? Colours.tPalette.m3primaryContainer
                                    : (iconPickHover.containsMouse ? Colours.tPalette.m3surfaceVariant : "transparent")
                                Behavior on color { CAnim { duration: Appearance.anim.durations.small } }
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                text: modelData
                                font.pointSize: Appearance.font.size.large
                                color: dialogAddCol._pickedIcon === modelData
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3onSurfaceVariant
                            }
                            MouseArea {
                                id: iconPickHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dialogAddCol._pickedIcon = modelData
                            }
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    // Cancel
                    Item {
                        width: cancelText.implicitWidth + Appearance.padding.normal * 2
                        height: cancelText.implicitHeight + Appearance.padding.small * 2
                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.normal
                            color: cancelHover.containsMouse ? Colours.tPalette.m3surfaceVariant : "transparent"
                        }
                        Text {
                            id: cancelText
                            anchors.centerIn: parent
                            text: qsTr("Cancel")
                            font.pointSize: Appearance.font.size.normal
                            font.family: Appearance.font.family.sans
                            color: Colours.palette.m3onSurfaceVariant
                        }
                        MouseArea {
                            id: cancelHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._showAddDialog = false
                        }
                    }

                    Item {
                        width: confirmText.implicitWidth + Appearance.padding.normal * 2
                        height: confirmText.implicitHeight + Appearance.padding.small * 2
                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.normal
                            color: confirmHover.containsMouse ? Colours.tPalette.m3primaryContainer : Colours.palette.m3primary
                            Behavior on color { CAnim { duration: Appearance.anim.durations.small } }
                        }
                        Text {
                            id: confirmText
                            anchors.centerIn: parent
                            text: qsTr("Create")
                            font.pointSize: Appearance.font.size.normal
                            font.family:    Appearance.font.family.sans
                            color:          Colours.palette.m3onPrimary
                        }
                        MouseArea {
                            id: confirmHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._confirmAdd()
                        }
                    }
                }
            }
        }

        onVisibleChanged: if (visible) addGroupField.forceActiveFocus()
    }

    function _confirmAdd() {
        if (root._editGroupName.trim() === "") return;
        const newId = GroupsConfig.addGroup(root._editGroupName, dialogAddCol._pickedIcon ?? "folder");
        root._showAddDialog  = false;
        root._editGroupName  = "";
        root._activeId       = newId;
        root._refreshApps();
    }

    Item {
        anchors.fill: parent
        visible:      root._showRenameDialog
        z:            100

        Rectangle {
            anchors.fill: parent
            color:        Qt.rgba(0, 0, 0, 0.5)
            MouseArea { anchors.fill: parent; onClicked: root._showRenameDialog = false }
        }

        Rectangle {
            anchors.centerIn: parent
            width:  300
            height: renameCol.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.large
            color:  Colours.palette.m3surfaceContainer

            Column {
                id: renameCol
                anchors {
                    left: parent.left; right: parent.right; top: parent.top
                    margins: Appearance.padding.large
                }
                spacing: Appearance.spacing.normal

                Text {
                    text: qsTr("Rename Group")
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurface
                }

                StyledTextField {
                    id: renameField
                    width: parent.width
                    text: root._editGroupName
                    onTextChanged: root._editGroupName = text
                    Keys.onReturnPressed: root._confirmRename()
                    Keys.onEscapePressed: root._showRenameDialog = false
                }

                Row {
                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    Item {
                        width: cancelRenameText.implicitWidth + Appearance.padding.normal * 2
                        height: cancelRenameText.implicitHeight + Appearance.padding.small * 2
                        Text {
                            id: cancelRenameText
                            anchors.centerIn: parent
                            text: qsTr("Cancel")
                            font.pointSize: Appearance.font.size.normal
                            font.family: Appearance.font.family.sans
                            color: Colours.palette.m3onSurfaceVariant
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root._showRenameDialog = false
                        }
                    }

                    Item {
                        width: saveText.implicitWidth + Appearance.padding.normal * 2
                        height: saveText.implicitHeight + Appearance.padding.small * 2
                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.normal
                            color: Colours.palette.m3primary
                        }
                        Text {
                            id: saveText
                            anchors.centerIn: parent
                            text: qsTr("Save")
                            font.pointSize: Appearance.font.size.normal
                            font.family: Appearance.font.family.sans
                            color: Colours.palette.m3onPrimary
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root._confirmRename()
                        }
                    }
                }
            }
        }

        onVisibleChanged: if (visible) renameField.forceActiveFocus()
    }

    function _confirmRename() {
        if (root._editGroupName.trim() === "") return;
        GroupsConfig.renameGroup(root._editGroupId, root._editGroupName);
        root._showRenameDialog = false;
    }

    Item {
        anchors.fill: parent
        visible:      root._showDeleteDialog
        z:            100

        Rectangle {
            anchors.fill: parent
            color:        Qt.rgba(0, 0, 0, 0.5)
            MouseArea { anchors.fill: parent; onClicked: root._showDeleteDialog = false }
        }

        Rectangle {
            anchors.centerIn: parent
            width:  280
            height: deleteCol.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.large
            color:  Colours.palette.m3surfaceContainer

            Column {
                id: deleteCol
                anchors {
                    left: parent.left; right: parent.right; top: parent.top
                    margins: Appearance.padding.large
                }
                spacing: Appearance.spacing.normal

                Text {
                    text: qsTr("Delete Group?")
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurface
                }
                Text {
                    width: parent.width
                    text: qsTr("This will only remove the group, not the apps inside it.")
                    font.pointSize: Appearance.font.size.small
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.Wrap
                }

                Row {
                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    Item {
                        width: cancelDelText.implicitWidth + Appearance.padding.normal * 2
                        height: cancelDelText.implicitHeight + Appearance.padding.small * 2
                        Text {
                            id: cancelDelText
                            anchors.centerIn: parent
                            text: qsTr("Cancel")
                            font.pointSize: Appearance.font.size.normal
                            font.family: Appearance.font.family.sans
                            color: Colours.palette.m3onSurfaceVariant
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root._showDeleteDialog = false
                        }
                    }

                    Item {
                        width: deleteText.implicitWidth + Appearance.padding.normal * 2
                        height: deleteText.implicitHeight + Appearance.padding.small * 2
                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.normal
                            color: Colours.palette.m3error
                        }
                        Text {
                            id: deleteText
                            anchors.centerIn: parent
                            text: qsTr("Delete")
                            font.pointSize: Appearance.font.size.normal
                            font.family: Appearance.font.family.sans
                            color: Colours.palette.m3onError
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                GroupsConfig.removeGroup(root._editGroupId);
                                root._activeId = "home";
                                root._showDeleteDialog = false;
                                root._refreshApps();
                            }
                        }
                    }
                }
            }
        }
    }
}
