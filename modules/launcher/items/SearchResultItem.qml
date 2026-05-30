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

    required property DesktopEntry modelData
    required property int index
    required property bool isSelected
    required property string searchQuery

    signal clicked()
    signal hovered()

    readonly property int horizontalMargin: 10
    readonly property int buttonPadding: Appearance.padding.normal
    readonly property int iconSize: 32

    implicitWidth: parent?.width ?? 400
    implicitHeight: contentRow.implicitHeight + buttonPadding * 2

    // ═══════════════════════════════════════════════════════════════
    // FUZZY MATCH HIGHLIGHTING
    // ═══════════════════════════════════════════════════════════════
    function highlightFuzzyMatch(content: string, query: string): string {
        if (!query || query.length === 0 || !content)
            return escapeHtml(content);

        const contentLower = content.toLowerCase();
        const queryLower = query.toLowerCase();
        let result = "";
        let lastIndex = 0;
        let qIndex = 0;

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

    // ═══════════════════════════════════════════════════════════════
    // BACKGROUND
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: bgRect

        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin
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
            CAnim {
                duration: Appearance.anim.durations.small
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MOUSE INTERACTION
    // ═══════════════════════════════════════════════════════════════
    MouseArea {
        id: mouseArea

        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered()
        onClicked: root.clicked()
    }

    // ═══════════════════════════════════════════════════════════════
    // CONTENT ROW
    // ═══════════════════════════════════════════════════════════════
    Row {
        id: contentRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.horizontalMargin + root.buttonPadding
        anchors.rightMargin: root.horizontalMargin + root.buttonPadding
        anchors.verticalCenter: parent.verticalCenter

        spacing: Appearance.spacing.normal

        // App icon
        IconImage {
            id: appIcon

            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: root.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

        // App name + description
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - appIcon.width - parent.spacing - enterHint.width - parent.spacing

            // App name with fuzzy highlights
            Text {
                id: nameText

                width: parent.width
                textFormat: Text.StyledText
                text: root.highlightFuzzyMatch(root.modelData?.name ?? "", root.searchQuery)
                font.pointSize: Appearance.font.size.smaller
                font.family: Appearance.font.family.sans
                font.hintingPreference: Font.PreferDefaultHinting
                font.variableAxes: ({ "wght": 450, "wdth": 100 })
                color: Colours.palette.m3onSurface
                renderType: Text.NativeRendering
                elide: Text.ElideRight
            }

            // App description/comment (shown if available)
            Text {
                visible: text !== ""
                width: parent.width
                text: root.modelData?.comment ?? root.modelData?.genericName ?? ""
                font.pointSize: Appearance.font.size.small
                font.family: Appearance.font.family.sans
                color: Colours.palette.m3onSurfaceVariant
                renderType: Text.NativeRendering
                elide: Text.ElideRight
                opacity: 0.7
            }
        }

        // Enter key hint (visible on selected)
        MaterialIcon {
            id: enterHint

            anchors.verticalCenter: parent.verticalCenter
            visible: root.isSelected
            text: "keyboard_return"
            font.pointSize: 10
            color: Colours.palette.m3onPrimaryContainer
            opacity: visible ? 0.7 : 0

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.small
                }
            }
        }
    }
}
