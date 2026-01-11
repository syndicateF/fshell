pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

/**
 * RGB Pane - RGB Keyboard control panel
 * 
 * Pure subscriber - all logic in LegionRgb service
 */
Item {
    id: root

    // Save dialog state
    property bool showSaveDialog: false
    property string presetName: ""

    StyledFlickable {
        anchors.fill: parent
        anchors.margins: Appearance.padding.large * 2
        flickableDirection: Flickable.VerticalFlick
        contentHeight: content.height

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            // ==================== HEADER ====================
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "keyboard"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("RGB Keyboard")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: LegionRgb.available ? qsTr("Legion RGB keyboard control") : qsTr("Keyboard not connected")
                color: Colours.palette.m3outline
            }

            // Status
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                implicitHeight: statusRow.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: LegionRgb.available ? Colours.palette.m3primaryContainer : Colours.palette.m3errorContainer

                RowLayout {
                    id: statusRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: LegionRgb.available ? "check_circle" : "error"
                        color: LegionRgb.available ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onErrorContainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: LegionRgb.available ? qsTr("Keyboard connected") : qsTr("Keyboard not detected")
                        color: LegionRgb.available ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onErrorContainer
                    }
                }
            }

            // ==================== PRESETS ====================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Presets")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: LegionRgb.available
            }

            // Save preset button
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Appearance.rounding.small
                color: Colours.palette.m3primaryContainer
                visible: LegionRgb.available && !LegionRgb.busy

                StateLayer {
                    radius: parent.radius
                    function onClicked(): void { root.showSaveDialog = true; }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small
                    MaterialIcon { text: "add"; color: Colours.palette.m3onPrimaryContainer }
                    StyledText { text: qsTr("Save current as preset"); color: Colours.palette.m3onPrimaryContainer; font.weight: Font.Medium }
                }
            }

            // Preset list
            Repeater {
                model: LegionRgb.presets
                PresetItem {
                    required property var modelData
                    Layout.fillWidth: true
                    preset: modelData
                    visible: LegionRgb.available
                }
            }

            // No presets
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainer
                visible: LegionRgb.available && LegionRgb.presets.length === 0

                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("No saved presets yet")
                    color: Colours.palette.m3outline
                }
            }

            // ==================== EFFECT ====================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Effect")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: LegionRgb.available
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: effectGrid.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: LegionRgb.available

                GridLayout {
                    id: effectGrid
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    columns: 3
                    rowSpacing: Appearance.spacing.smaller
                    columnSpacing: Appearance.spacing.smaller

                    Repeater {
                        model: [
                            { effect: "static", icon: "palette", label: qsTr("Static") },
                            { effect: "breath", icon: "air", label: qsTr("Breath") },
                            { effect: "wave", icon: "waves", label: qsTr("Wave") },
                            { effect: "hue", icon: "gradient", label: qsTr("Cycle") },
                            { effect: "off", icon: "brightness_low", label: qsTr("Off") }
                        ]

                        EffectChip {
                            required property var modelData
                            Layout.fillWidth: true
                            icon: modelData.icon
                            label: modelData.label
                            isActive: LegionRgb.effect === modelData.effect
                            enabled: !LegionRgb.busy
                            onClicked: LegionRgb.switchEffect(modelData.effect)
                        }
                    }
                }
            }

            // ==================== ZONES (static/breath) ====================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Keyboard Zones")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: LegionRgb.available && ["static", "breath"].includes(LegionRgb.effect)
            }

            Repeater {
                model: [
                    { index: 0, name: qsTr("Zone 1 - Left") },
                    { index: 1, name: qsTr("Zone 2 - Left Center") },
                    { index: 2, name: qsTr("Zone 3 - Right Center") },
                    { index: 3, name: qsTr("Zone 4 - Right") }
                ]

                ZoneColorPicker {
                    required property var modelData
                    Layout.fillWidth: true
                    zoneIndex: modelData.index
                    zoneName: modelData.name
                    visible: LegionRgb.available && ["static", "breath"].includes(LegionRgb.effect)
                }
            }

            // Quick paste
            QuickPasteSection {
                Layout.fillWidth: true
                visible: LegionRgb.available && ["static", "breath"].includes(LegionRgb.effect)
            }

            // ==================== SETTINGS ====================
            // Direction (wave)
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Direction")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: LegionRgb.available && LegionRgb.effect === "wave"
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: dirRow.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: LegionRgb.available && LegionRgb.effect === "wave"

                RowLayout {
                    id: dirRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    SettingChip {
                        Layout.fillWidth: true
                        label: "← Left to Right"
                        isActive: LegionRgb.direction === "ltr"
                        onClicked: LegionRgb.setDirection("ltr")
                    }
                    SettingChip {
                        Layout.fillWidth: true
                        label: "Right to Left →"
                        isActive: LegionRgb.direction === "rtl"
                        onClicked: LegionRgb.setDirection("rtl")
                    }
                }
            }

            // Speed
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Speed: %1").arg(LegionRgb.speed)
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: LegionRgb.available && ["breath", "wave", "hue"].includes(LegionRgb.effect)
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: speedRow.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: LegionRgb.available && ["breath", "wave", "hue"].includes(LegionRgb.effect)

                RowLayout {
                    id: speedRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText { text: qsTr("Slow"); font.pointSize: Appearance.font.size.small; color: Colours.palette.m3outline }
                    Repeater {
                        model: [1, 2, 3, 4]
                        SettingChip {
                            required property int modelData
                            Layout.fillWidth: true
                            label: modelData.toString()
                            isActive: LegionRgb.speed === modelData
                            onClicked: LegionRgb.setSpeed(modelData)
                        }
                    }
                    StyledText { text: qsTr("Fast"); font.pointSize: Appearance.font.size.small; color: Colours.palette.m3outline }
                }
            }

            // Brightness
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Brightness")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: LegionRgb.available && !["off", "unknown"].includes(LegionRgb.effect)
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: brightRow.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: LegionRgb.available && !["off", "unknown"].includes(LegionRgb.effect)

                RowLayout {
                    id: brightRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    SettingChip {
                        Layout.fillWidth: true
                        icon: "brightness_low"
                        label: qsTr("Low")
                        isActive: LegionRgb.brightness === 1
                        onClicked: LegionRgb.setBrightness(1)
                    }
                    SettingChip {
                        Layout.fillWidth: true
                        icon: "brightness_high"
                        label: qsTr("High")
                        isActive: LegionRgb.brightness === 2
                        onClicked: LegionRgb.setBrightness(2)
                    }
                }
            }

            // Error
            StyledRect {
                visible: LegionRgb.lastError !== ""
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                implicitHeight: errRow.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.small
                color: Colours.palette.m3errorContainer

                RowLayout {
                    id: errRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.small
                    MaterialIcon { text: "error_outline"; color: Colours.palette.m3onErrorContainer; font.pointSize: Appearance.font.size.small }
                    StyledText { Layout.fillWidth: true; text: LegionRgb.lastError; color: Colours.palette.m3onErrorContainer; font.pointSize: Appearance.font.size.small; wrapMode: Text.WordWrap }
                }
            }

            Item { Layout.preferredHeight: Appearance.spacing.large }
        }
    }

    // ==================== SAVE DIALOG ====================
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        visible: root.showSaveDialog

        MouseArea { anchors.fill: parent; onClicked: root.showSaveDialog = false }

        StyledRect {
            anchors.centerIn: parent
            width: 300
            implicitHeight: dlgCol.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.large
            color: Colours.palette.m3surface

            ColumnLayout {
                id: dlgCol
                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText { text: qsTr("Save Preset"); font.pointSize: Appearance.font.size.large; font.weight: Font.Bold }
                StyledText { text: qsTr("Enter a name:"); color: Colours.palette.m3outline }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: 2
                    border.color: Colours.palette.m3primary

                    TextInput {
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        text: root.presetName
                        onTextChanged: root.presetName = text
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurface
                        clip: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal
                    Item { Layout.fillWidth: true }

                    StyledRect {
                        implicitWidth: 80; implicitHeight: 36
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3surfaceContainerHigh
                        StateLayer { radius: parent.radius; function onClicked(): void { root.showSaveDialog = false; root.presetName = ""; } }
                        StyledText { anchors.centerIn: parent; text: qsTr("Cancel") }
                    }

                    StyledRect {
                        implicitWidth: 80; implicitHeight: 36
                        radius: Appearance.rounding.small
                        color: root.presetName.trim() ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh
                        StateLayer {
                            radius: parent.radius
                            enabled: root.presetName.trim()
                            function onClicked(): void {
                                if (root.presetName.trim()) {
                                    LegionRgb.savePreset(root.presetName.trim());
                                    root.showSaveDialog = false;
                                    root.presetName = "";
                                }
                            }
                        }
                        StyledText { anchors.centerIn: parent; text: qsTr("Save"); color: root.presetName.trim() ? Colours.palette.m3onPrimary : Colours.palette.m3outline }
                    }
                }
            }
        }
    }

    // ==================== INLINE COMPONENTS ====================

    component EffectChip: StyledRect {
        id: effectChip
        required property string icon
        required property string label
        required property bool isActive
        signal clicked()

        implicitHeight: ecContent.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: isActive ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

        StateLayer { radius: parent.radius; function onClicked(): void { effectChip.clicked(); } }

        RowLayout {
            id: ecContent
            anchors.centerIn: parent
            spacing: Appearance.spacing.smaller
            MaterialIcon { text: effectChip.icon; font.pointSize: Appearance.font.size.small; color: effectChip.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface }
            StyledText { text: effectChip.label; font.pointSize: Appearance.font.size.smaller; font.weight: effectChip.isActive ? Font.Medium : Font.Normal; color: effectChip.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface }
        }
    }

    component SettingChip: StyledRect {
        id: settingChip
        property string icon: ""
        required property string label
        required property bool isActive
        signal clicked()

        implicitHeight: scContent.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: isActive ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

        StateLayer { radius: parent.radius; function onClicked(): void { settingChip.clicked(); } }

        RowLayout {
            id: scContent
            anchors.centerIn: parent
            spacing: Appearance.spacing.smaller
            MaterialIcon { visible: settingChip.icon; text: settingChip.icon; font.pointSize: Appearance.font.size.normal; color: settingChip.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface }
            StyledText { text: settingChip.label; font.pointSize: Appearance.font.size.small; font.weight: settingChip.isActive ? Font.Medium : Font.Normal; color: settingChip.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface }
        }
    }

    component ZoneColorPicker: StyledRect {
        id: zonePicker
        required property int zoneIndex
        required property string zoneName

        implicitHeight: zpCol.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: zpCol
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.smaller

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal
                StyledText { text: zonePicker.zoneName; font.pointSize: Appearance.font.size.small; font.weight: Font.Medium }
                Rectangle { width: 20; height: 20; radius: 10; color: "#" + (LegionRgb.colors.length > zonePicker.zoneIndex ? LegionRgb.colors[zonePicker.zoneIndex] : "ff5500"); border.width: 2; border.color: Colours.palette.m3outline }

                Rectangle {
                    Layout.preferredWidth: 80; height: 24
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: 1; border.color: hexIn.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 4; spacing: 2
                        StyledText { text: "#"; font.pointSize: Appearance.font.size.smaller; color: Colours.palette.m3outline }
                        TextInput {
                            id: hexIn
                            Layout.fillWidth: true
                            text: LegionRgb.colors.length > zonePicker.zoneIndex ? LegionRgb.colors[zonePicker.zoneIndex].toUpperCase() : "FF5500"
                            font.pointSize: Appearance.font.size.smaller; font.capitalization: Font.AllUppercase
                            color: Colours.palette.m3onSurface; maximumLength: 6
                            validator: RegularExpressionValidator { regularExpression: /[0-9A-Fa-f]{0,6}/ }
                            onEditingFinished: if (text.length === 6) LegionRgb.setZoneColor(zonePicker.zoneIndex, text.toLowerCase())
                            Keys.onReturnPressed: if (text.length === 6) { LegionRgb.setZoneColor(zonePicker.zoneIndex, text.toLowerCase()); focus = false; }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: Appearance.spacing.smaller
                Repeater {
                    model: LegionRgb.colorPresets
                    Rectangle {
                        required property string modelData
                        width: 24; height: 24; radius: 12
                        color: "#" + modelData
                        border.width: (LegionRgb.colors.length > zonePicker.zoneIndex && LegionRgb.colors[zonePicker.zoneIndex] === modelData) ? 3 : 1
                        border.color: (LegionRgb.colors.length > zonePicker.zoneIndex && LegionRgb.colors[zonePicker.zoneIndex] === modelData) ? Colours.palette.m3primary : Colours.palette.m3outline
                        StateLayer { radius: parent.radius; function onClicked(): void { LegionRgb.setZoneColor(zonePicker.zoneIndex, modelData); } }
                    }
                }
            }
        }
    }

    component QuickPasteSection: StyledRect {
        Layout.topMargin: Appearance.spacing.small
        implicitHeight: qpCol.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: qpCol
            anchors.fill: parent; anchors.margins: Appearance.padding.normal; spacing: Appearance.spacing.small

            StyledText { text: qsTr("Quick Paste (4 hex colors)"); font.pointSize: Appearance.font.size.small; color: Colours.palette.m3outline }

            RowLayout {
                Layout.fillWidth: true; spacing: Appearance.spacing.small

                Rectangle {
                    Layout.fillWidth: true; height: 32
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: 1; border.color: pasteIn.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline

                    TextInput {
                        id: pasteIn
                        anchors.fill: parent; anchors.margins: Appearance.padding.small
                        font.pointSize: Appearance.font.size.normal; font.capitalization: Font.AllUppercase
                        color: Colours.palette.m3onSurface; clip: true
                        Text { anchors.fill: parent; text: "F72585 7209B7 3A0CA3 4361EE"; font: parent.font; color: Colours.palette.m3outline; visible: !parent.text && !parent.activeFocus }
                        Keys.onReturnPressed: applyPaste()
                    }
                }

                StyledRect {
                    implicitWidth: applyLbl.implicitWidth + Appearance.padding.normal * 2; implicitHeight: 32
                    radius: Appearance.rounding.small; color: Colours.palette.m3primary
                    StateLayer { radius: parent.radius; function onClicked(): void { applyPaste(); } }
                    StyledText { id: applyLbl; anchors.centerIn: parent; text: qsTr("Apply"); color: Colours.palette.m3onPrimary; font.weight: Font.Medium }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: Appearance.spacing.small
                QuickBtn { label: qsTr("All Same"); onClicked: { const c = LegionRgb.colors[0] || "ff5500"; LegionRgb.applyColors4([c, c, c, c]); } }
                QuickBtn { label: qsTr("Rainbow"); onClicked: LegionRgb.applyColors4(["ff0000", "ffff00", "00ff00", "0000ff"]) }
                QuickBtn { label: qsTr("White"); onClicked: LegionRgb.applyColors4(["ffffff", "ffffff", "ffffff", "ffffff"]) }
            }
        }

        function applyPaste(): void {
            const input = pasteIn.text.trim().toUpperCase();
            const colors = input.split(/\s+/);
            if (colors.length >= 1 && colors.length <= 4 && colors.every(c => /^[0-9A-F]{6}$/.test(c))) {
                while (colors.length < 4) colors.push(colors[colors.length - 1]);
                LegionRgb.applyColors4(colors.map(c => c.toLowerCase()));
                pasteIn.text = "";
            }
        }
    }

    component QuickBtn: StyledRect {
        id: qb
        required property string label
        signal clicked()
        implicitWidth: qbLbl.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: qbLbl.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.small; color: Colours.palette.m3surfaceContainerHigh
        StateLayer { radius: parent.radius; function onClicked(): void { qb.clicked(); } }
        StyledText { id: qbLbl; anchors.centerIn: parent; text: qb.label; font.pointSize: Appearance.font.size.smaller }
    }

    component PresetItem: StyledRect {
        id: presetItem
        required property var preset
        implicitHeight: piRow.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.small; color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: piRow
            anchors.fill: parent; anchors.margins: Appearance.padding.normal; spacing: Appearance.spacing.normal

            RowLayout {
                spacing: 2
                Repeater {
                    model: presetItem.preset.state.colors || []
                    Rectangle { required property string modelData; width: 12; height: 12; radius: 6; color: "#" + modelData; border.width: 1; border.color: Colours.palette.m3outline }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                StyledText { text: presetItem.preset.name; font.weight: Font.Medium }
                StyledText { text: presetItem.preset.state.effect; font.pointSize: Appearance.font.size.smaller; color: Colours.palette.m3outline }
            }

            StyledRect {
                implicitWidth: 60; implicitHeight: 28; radius: Appearance.rounding.small; color: Colours.palette.m3primary
                StateLayer { radius: parent.radius; function onClicked(): void { LegionRgb.applyPreset(presetItem.preset); } }
                StyledText { anchors.centerIn: parent; text: qsTr("Apply"); font.pointSize: Appearance.font.size.smaller; color: Colours.palette.m3onPrimary }
            }

            StyledRect {
                implicitWidth: 28; implicitHeight: 28; radius: Appearance.rounding.small; color: Colours.palette.m3errorContainer
                StateLayer { radius: parent.radius; function onClicked(): void { LegionRgb.deletePreset(presetItem.preset.id); } }
                MaterialIcon { anchors.centerIn: parent; text: "delete"; font.pointSize: Appearance.font.size.small; color: Colours.palette.m3onErrorContainer }
            }
        }
    }
}
