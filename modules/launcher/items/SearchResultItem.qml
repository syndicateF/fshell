pragma ComponentBehavior: Bound

import "../services"
import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property var modelData
    required property int index
    required property bool isSelected
    required property string searchQuery

    signal clicked()
    signal hovered()

    readonly property int horizontalMargin: 6
    readonly property int buttonPadding:    14
    readonly property int iconSize:         40

    readonly property string primaryCategory: {
        const cats = root.modelData?.categories;
        if (!cats) return "";
        if (typeof cats === "string") {
            const parts = cats.split(";").filter(s => s.trim().length > 0);
            return parts.length > 0 ? parts[0] : "";
        }
        if (Array.isArray(cats) && cats.length > 0) return cats[0];
        return "";
    }

    implicitWidth:  parent?.width ?? 400
    implicitHeight: contentRow.implicitHeight + buttonPadding * 2

    function highlightFuzzyMatch(content: string, query: string): string {
        if (!query || query.length === 0 || !content)
            return escapeHtml(content);

        const contentLower = content.toLowerCase();
        const queryLower   = query.toLowerCase();
        let result    = "";
        let lastIndex = 0;
        let qIndex    = 0;

        for (let i = 0; i < content.length && qIndex < queryLower.length; i++) {
            if (contentLower[i] === queryLower[qIndex]) {
                if (i > lastIndex)
                    result += escapeHtml(content.slice(lastIndex, i));
                result += `<b><font color="${Colours.palette.m3primary}">${escapeHtml(content[i])}</font></b>`;
                lastIndex = i + 1;
                qIndex++;
            }
        }

        if (lastIndex < content.length)
            result += escapeHtml(content.slice(lastIndex));

        return result;
    }

    function escapeHtml(text: string): string {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    Rectangle {
        id: bgRect

        anchors.fill:        parent
        anchors.leftMargin:  root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin

        radius: Appearance.rounding.normal
        color: {
            if (mouseArea.pressed)
                return Colours.palette.m3primaryContainer;
            if (root.isSelected || mouseArea.containsMouse)
                return Colours.tPalette.m3primaryContainer;
            return "transparent";
        }

        Behavior on color {
            CAnim { duration: Appearance.anim.durations.small }
        }
    }

    Rectangle {
        anchors.bottom:      parent.bottom
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.leftMargin:  root.horizontalMargin + root.buttonPadding
        anchors.rightMargin: root.horizontalMargin + root.buttonPadding
        height:  1
        color:   Colours.palette.m3outlineVariant
        opacity: 0.2
    }

    MouseArea {
        id: mouseArea

        anchors.fill:        parent
        anchors.leftMargin:  root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
        hoverEnabled:  true
        cursorShape:   Qt.PointingHandCursor

        onEntered: root.hovered()
        onClicked: root.clicked()
    }

    Row {
        id: contentRow

        anchors.left:         parent.left
        anchors.right:        parent.right
        anchors.leftMargin:   root.horizontalMargin + root.buttonPadding
        anchors.rightMargin:  root.horizontalMargin + root.buttonPadding
        anchors.verticalCenter: parent.verticalCenter

        spacing: Appearance.spacing.normal

        IconImage {
            id: appIcon

            source:       Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: root.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            readonly property real hintReserved: root.index < 9
                ? shortcutHint.implicitWidth + parent.spacing
                : 0

            width: parent.width
                   - appIcon.implicitWidth - parent.spacing
                   - hintReserved

            Text {
                id: nameText

                width:       parent.width
                textFormat:  Text.StyledText
                text:        root.highlightFuzzyMatch(root.modelData?.name ?? "", root.searchQuery)
                font.pointSize:       Appearance.font.size.smaller
                font.family:          Appearance.font.family.sans
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes:    ({ "wght": 450, "wdth": 100 })
                color:       Colours.palette.m3onSurface
                renderType:  Text.NativeRendering
                elide:       Text.ElideRight
            }

            Text {
                id: subtitleText

                visible: text !== ""
                width:   parent.width
                text: {
                    const cat  = root.primaryCategory;
                    const desc = root.modelData?.comment ?? root.modelData?.genericName ?? "";
                    if (cat && desc) return cat + " - " + desc;
                    return cat || desc;
                }
                font.pointSize: Appearance.font.size.small
                font.family:    Appearance.font.family.sans
                color:          Colours.palette.m3onSurfaceVariant
                renderType:     Text.NativeRendering
                elide:          Text.ElideRight
                opacity:        0.75
            }
        }

        Text {
            id: shortcutHint

            anchors.verticalCenter: parent.verticalCenter

            visible: root.index < 9

            text: root.index < 9 ? "Ctrl + " + (root.index + 1) : ""

            font.pointSize: Appearance.font.size.small
            font.family:    Appearance.font.family.sans

            color:   root.isSelected
                         ? Colours.palette.m3onPrimaryContainer
                         : Colours.palette.m3onSurfaceVariant
            opacity: root.isSelected ? 0.85 : 0.55

            Behavior on opacity {
                Anim { duration: Appearance.anim.durations.small }
            }
        }
    }
}
