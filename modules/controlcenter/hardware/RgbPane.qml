pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "LegionKeyboardLayout.js" as KbLayout

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
    
    // Color picker popup state
    property int activeZone: -1  // -1 = no zone selected
    
    // State hygiene: auto-close popup on effect/available changes
    Connections {
        target: LegionRgb
        function onEffectChanged() {
            if (!["static", "breath"].includes(LegionRgb.effect)) {
                colorPickerPopup.close();
            }
        }
        function onAvailableChanged() {
            if (!LegionRgb.available) {
                colorPickerPopup.close();
            }
        }
    }

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

            // Keyboard visual - click zones to select
            StyledText {
                text: qsTr("Click on a zone to change its color")
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
                visible: LegionRgb.available && ["static", "breath"].includes(LegionRgb.effect)
            }

            KeyboardVisual {
                id: keyboardVisual
                Layout.fillWidth: true
                implicitHeight: childrenRect.height + padding * 2
                visible: LegionRgb.available && ["static", "breath"].includes(LegionRgb.effect)
                onZoneClicked: (zone) => {
                    root.activeZone = zone;
                    colorPickerPopup.open();
                }
            }

            // ==== COLOR PICKER POPUP is defined at root level (Popup component) ====

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
        visible: opacity > 0 || saveDialogCloseAnim.running
        opacity: root.showSaveDialog ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: Appearance.anim.durations.normal }
        }

        MouseArea { anchors.fill: parent; onClicked: root.showSaveDialog = false }

        StyledRect {
            anchors.centerIn: parent
            width: 300
            implicitHeight: dlgCol.implicitHeight + Appearance.padding.large * 2
            radius: Appearance.rounding.large
            color: Colours.palette.m3surface
            scale: root.showSaveDialog ? 1 : 0.8
            
            Behavior on scale {
                NumberAnimation {
                    id: saveDialogCloseAnim
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.OutBack
                }
            }

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

    // Key cap component using Layout system
    component KeyCap: Rectangle {
        id: kc
        property string shape: "normal"  // normal, fn, tab, caps, shift, control, space, expand, numpad
        property int zone: 0
        property string label: ""
        property real baseWidth: 32
        property real baseHeight: 28
        
        // Width multipliers based on key shape
        readonly property var widthMultiplier: ({
            "normal": 1.0, "fn": 0.85, "deletes": 0.9, "nf": 0.8,
            "tick": 0.7, "tab": 1.18, "caps": 1.65,
            "shifts": 2.19, "control": 1.1, "expand": 1.0,  
            "numpad": 0.8, "numwide": 2.0, "numtall": 0.8, "arrowspacers": 12.15,
            "backspace": 1.45, "slash": 1.0, "enter": 1.65, "shift": 2.30,
            "arrowaligns": 1.05, "spaces": 5.35
        })
        
        // Height multipliers
        readonly property var heightMultiplier: ({
        "fn": 0.7, "deletes": 0.7, "nf": 0.7
        })
        
        signal clicked()
        
        // Keys with zone < 0 are layout spacers (invisible, non-clickable)
        property bool isSpacerKey: zone < 0
        
        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: baseWidth * (widthMultiplier[shape] || 1.0)
        Layout.preferredHeight: baseHeight * (heightMultiplier[shape] || 1.0)
        
        // For absolute positioning (outside Layout)
        implicitWidth: baseWidth * (widthMultiplier[shape] || 1.0)
        implicitHeight: baseHeight * (heightMultiplier[shape] || 1.0)
        width: implicitWidth
        height: implicitHeight
        
        color: isSpacerKey ? "transparent" : (LegionRgb.colors.length > zone ? "#" + LegionRgb.colors[zone] : "#808080")
        radius: Math.max(2, kc.baseWidth * 0.1)
        
        Text {
            visible: !kc.isSpacerKey
            anchors.centerIn: parent
            text: kc.label
            color: Qt.lighter(kc.color, 2.5)
            font.pixelSize: Math.max(7, kc.baseWidth * (kc.shape === "fn" ? 0.25 : 0.32))
            font.weight: Font.Medium
        }
        
        MouseArea {
            visible: !kc.isSpacerKey
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: kc.clicked()
            Rectangle {
                anchors.fill: parent
                radius: kc.radius
                color: parent.containsMouse ? "#40ffffff" : "transparent"
            }
        }
    }

    // Keyboard visual using ColumnLayout + RowLayout pattern with JS data
    component KeyboardVisual: Rectangle {
        id: kbVisual
        signal zoneClicked(int zone)
        radius: Appearance.rounding.normal
        color: "#1a1a2e"
        border.width: 2
        border.color: Colours.palette.m3outline
        
        // Simple fixed sizing - larger keys
        readonly property real keyUnit: 38
        readonly property real keyHeight: 38
        
        property real keySpacing: 4
        property real rowSpacing: 4
        property real padding: 12
        
        // Calculate size based on content
        implicitWidth: mainKeyboardContent.implicitWidth + numpadContent.implicitWidth + (padding * 2) + keySpacing * 4
        implicitHeight: (keyHeight * 6) + (rowSpacing * 5) + (padding * 2)

        RowLayout {
            anchors.centerIn: parent
            spacing: kbVisual.keySpacing
            
            // Main keyboard block - uses JS layout data
            ColumnLayout {
                id: mainKeyboardContent
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                spacing: kbVisual.rowSpacing
                
                Repeater {
                    model: KbLayout.layout.mainBlock
                    
                    delegate: RowLayout {
                        required property var modelData
                        spacing: kbVisual.keySpacing
                        
                        Repeater {
                            model: modelData
                            delegate: KeyCap {
                                required property var modelData
                                shape: modelData.shape
                                zone: modelData.zone
                                label: modelData.label
                                baseWidth: kbVisual.keyUnit
                                baseHeight: kbVisual.keyHeight
                                onClicked: kbVisual.zoneClicked(zone)
                            }
                        }
                    }
                }
            }
            
            // Numpad block - GridLayout with Repeater from JS data
            GridLayout {
                id: numpadContent
                Layout.alignment: Qt.AlignTop
                columns: 4
                rowSpacing: kbVisual.rowSpacing
                columnSpacing: kbVisual.keySpacing
                
                // Flatten numpad rows for GridLayout
                Repeater {
                    id: numpadRepeater
                    model: {
                        var items = [];
                        for (var i = 0; i < KbLayout.layout.numpad.length; i++) {
                            var row = KbLayout.layout.numpad[i];
                            for (var j = 0; j < row.length; j++) {
                                items.push(row[j]);
                            }
                        }
                        return items;
                    }
                    delegate: KeyCap {
                        required property var modelData
                        shape: modelData.shape
                        zone: modelData.zone
                        label: modelData.label
                        baseWidth: kbVisual.keyUnit
                        baseHeight: kbVisual.keyHeight
                        // numtall spans 2 rows, numwide spans 2 columns
                        Layout.rowSpan: modelData.shape === "numtall" ? 2 : 1
                        Layout.columnSpan: modelData.shape === "numwide" ? 2 : 1
                        Layout.fillHeight: modelData.shape === "numtall"
                        Layout.fillWidth: modelData.shape === "numwide"
                        onClicked: kbVisual.zoneClicked(zone)
                    }
                }
            }
        }
    }
    
    // ==================== COLOR PICKER POPUP (Real Popup) ====================
    Popup {
        id: colorPickerPopup
        
        // Center in parent (root)
        anchors.centerIn: parent
        width: Math.min(500, parent.width * 0.9)
        padding: Appearance.padding.large
        
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        // Enter animation (scale + opacity)
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0; to: 1
                    duration: Appearance.anim.durations.normal
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.8; to: 1
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.OutBack
                }
            }
        }
        
        // Exit animation (scale + opacity)
        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1; to: 0
                    duration: Appearance.anim.durations.normal
                }
                NumberAnimation {
                    property: "scale"
                    from: 1; to: 0.8
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.InBack
                }
            }
        }
        
        // Dim background
        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.5)
        }
        
        // Popup content background - same as FileDialog
        background: Rectangle {
            // color: Colours.tPalette.m3surface
            color: Colours.palette.m3surfaceContainerHigh
            radius: Appearance.rounding.normal
        }
        
        // State
        property var throttleTimer: null
        property int snapshotZone: -1
        property var previewSnapshot: null
        
        onOpened: {
            snapshotZone = root.activeZone;
            previewSnapshot = {
                effect: LegionRgb.effect,
                colors: LegionRgb.colors.slice(),
                brightness: LegionRgb.brightness,
                speed: LegionRgb.speed,
                direction: LegionRgb.direction
            };
        }
        
        onClosed: {
            if (throttleTimer) {
                throttleTimer.destroy();
                throttleTimer = null;
            }
            root.activeZone = -1;
        }
        
        function cancelPreview() {
            if (previewSnapshot) {
                LegionRgb.applyFullState(previewSnapshot);
            }
            close();
        }
        
        function applyChanges() {
            LegionRgb.applyFullState({
                effect: LegionRgb.effect,
                colors: LegionRgb.colors.slice(),
                brightness: LegionRgb.brightness,
                speed: LegionRgb.speed,
                direction: LegionRgb.direction
            });
            close();
        }
        
        function applyColorThrottled(color: string) {
            if (snapshotZone < 0) return;
            if (throttleTimer) throttleTimer.destroy();
            
            throttleTimer = Qt.createQmlObject(`
                import QtQuick
                Timer {
                    interval: 80
                    repeat: false
                    running: true
                    property string pendingColor: "${color}"
                    property int targetZone: ${snapshotZone}
                    onTriggered: {
                        LegionRgb.previewZoneColor(targetZone, pendingColor);
                        destroy();
                    }
                }
            `, colorPickerPopup);
        }
        
        function applyColorImmediate(color: string) {
            if (throttleTimer) {
                throttleTimer.destroy();
                throttleTimer = null;
            }
            if (snapshotZone >= 0) {
                LegionRgb.previewZoneColor(snapshotZone, color);
            }
        }
        
        // Popup content - EXACT reference match
        contentItem: ColumnLayout {
            spacing: 0
            
            // ===== MAIN PICKER AREA (exact reference layout) =====
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                // LEFT SECTION: Color grid + Less button
                ColumnLayout {
                    spacing: 8
                    
                    // Color grid (10×8 - grays on TOP like reference)
                    Grid {
                        columns: 10
                        spacing: 5
                        
                        Repeater {
                            // EXACT reference pattern: grays on row 1, then hue columns
                            model: [
                                // Row 1: Grays (black to white) - AT TOP like reference
                                "212121", "424242", "616161", "757575", "9e9e9e", "bdbdbd", "e0e0e0", "eeeeee", "f5f5f5", "ffffff",
                                // Row 2: Browns/dark neutrals
                                "4e342e", "5d4037", "6d4c41", "795548", "8d6e63", "a1887f", "bcaaa4", "d7ccc8", "efebe9", "fafafa",
                                // Row 3: Reds/Pinks
                                "b71c1c", "c62828", "d32f2f", "e53935", "ef5350", "e57373", "ef9a9a", "ffcdd2", "ffebee", "fce4ec",
                                // Row 4: Oranges/Ambers
                                "e65100", "ef6c00", "f57c00", "fb8c00", "ffa726", "ffb74d", "ffcc80", "ffe0b2", "fff3e0", "fff8e1",
                                // Row 5: Yellows/Limes
                                "f9a825", "fbc02d", "fdd835", "ffeb3b", "ffee58", "fff176", "fff59d", "fff9c4", "fffde7", "f0f4c3",
                                // Row 6: Greens
                                "1b5e20", "2e7d32", "388e3c", "43a047", "66bb6a", "81c784", "a5d6a7", "c8e6c9", "e8f5e9", "f1f8e9",
                                // Row 7: Cyans/Teals
                                "006064", "00838f", "0097a7", "00acc1", "26c6da", "4dd0e1", "80deea", "b2ebf2", "e0f7fa", "e0f2f1",
                                // Row 8: Blues/Purples
                                "1a237e", "283593", "303f9f", "3949ab", "5c6bc0", "7986cb", "9fa8da", "c5cae9", "e8eaf6", "ede7f6"
                            ]
                            
                            Rectangle {
                                required property string modelData
                                required property int index
                                property bool isSelected: {
                                    if (root.activeZone < 0 || LegionRgb.colors.length <= root.activeZone) return false;
                                    return LegionRgb.colors[root.activeZone].toLowerCase() === modelData.toLowerCase();
                                }
                                
                                width: 20
                                height: 20
                                radius: 4
                                color: "#" + modelData
                                
                                // Checkmark (like reference)
                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: {
                                        // Dark text for light colors
                                        const lightColors = ["ffffff", "f5f5f5", "eeeeee", "e0e0e0", "fafafa", "efebe9", "d7ccc8", "ffebee", "fff3e0", "fffde7", "e8f5e9", "e0f7fa", "e8eaf6", "fce4ec", "fff8e1", "f0f4c3", "f1f8e9", "e0f2f1", "ede7f6", "c5cae9", "c8e6c9", "b2ebf2", "fff9c4", "ffe0b2", "ffcdd2", "bcaaa4"];
                                        return lightColors.includes(parent.modelData) ? "#333333" : "#ffffff";
                                    }
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    visible: parent.isSelected
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: colorPickerPopup.applyColorImmediate(parent.modelData)
                                }
                            }
                        }
                    }
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 6
                        color: "transparent"
                        border.width: 1
                        border.color: Colours.palette.m3outline
                    
                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                const names = ["Zone 1 - Left", "Zone 2 - Left Center", "Zone 3 - Right Center", "Zone 4 - Right"];
                                return root.activeZone >= 0 ? names[root.activeZone] : "Select Zone";
                            }
                            font.pointSize: Appearance.font.size.normal
                            horizontalAlignment: Text.AlignHCenter
                            anchors.centerIn: parent

                        }

                    }
                }
                
                // RIGHT SECTION: SV Picker + Hue bar
                ColumnLayout {
                    spacing: 8
                    
                    RowLayout {
                        spacing: 8
                        
                        // SV Picker (square)
                        Item {
                            id: svPicker
                            Layout.preferredWidth: 195
                            Layout.preferredHeight: 195
                            
                            property real currentHue: 0.12  // Default yellow-ish
                            property real currentSat: 0.8
                            property real currentVal: 0.9
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: Qt.hsva(svPicker.currentHue, 1, 1, 1)
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#ffffff" }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: "#000000" }
                                }
                            }
                            
                            // Selector circle
                            Rectangle {
                                width: 16; height: 16; radius: 8
                                color: "transparent"
                                border.width: 2; border.color: "white"
                                x: svPicker.currentSat * (parent.width - width)
                                y: (1 - svPicker.currentVal) * (parent.height - height)
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                
                                function updateColor(mouse) {
                                    svPicker.currentSat = Math.max(0, Math.min(1, mouse.x / width));
                                    svPicker.currentVal = Math.max(0, Math.min(1, 1 - mouse.y / height));
                                    const c = Qt.hsva(svPicker.currentHue, svPicker.currentSat, svPicker.currentVal, 1);
                                    colorPickerPopup.applyColorThrottled(c.toString().slice(1, 7));
                                }
                                
                                onPressed: (mouse) => updateColor(mouse)
                                onPositionChanged: (mouse) => { if (pressed) updateColor(mouse); }
                                onReleased: (mouse) => {
                                    updateColor(mouse);
                                    const c = Qt.hsva(svPicker.currentHue, svPicker.currentSat, svPicker.currentVal, 1);
                                    colorPickerPopup.applyColorImmediate(c.toString().slice(1, 7));
                                }
                            }
                        }
                        
                        // Hue bar (vertical, thin)
                        Rectangle {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 195
                            radius: 8
                            
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "#ff0000" }
                                GradientStop { position: 0.17; color: "#ffff00" }
                                GradientStop { position: 0.33; color: "#00ff00" }
                                GradientStop { position: 0.5; color: "#00ffff" }
                                GradientStop { position: 0.67; color: "#0000ff" }
                                GradientStop { position: 0.83; color: "#ff00ff" }
                                GradientStop { position: 1.0; color: "#ff0000" }
                            }
                            
                            // Hue selector (oval/pill)
                            Rectangle {
                                width: parent.width + 4
                                height: 8
                                x: -2
                                y: svPicker.currentHue * (parent.height - height)
                                color: "transparent"
                                border.width: 2; border.color: "white"
                                radius: 4
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                
                                function updateHue(mouse) {
                                    svPicker.currentHue = Math.max(0, Math.min(1, mouse.y / height));
                                    const c = Qt.hsva(svPicker.currentHue, svPicker.currentSat, svPicker.currentVal, 1);
                                    colorPickerPopup.applyColorThrottled(c.toString().slice(1, 7));
                                }
                                
                                onPressed: (mouse) => updateHue(mouse)
                                onPositionChanged: (mouse) => { if (pressed) updateHue(mouse); }
                                onReleased: (mouse) => {
                                    updateHue(mouse);
                                    const c = Qt.hsva(svPicker.currentHue, svPicker.currentSat, svPicker.currentVal, 1);
                                    colorPickerPopup.applyColorImmediate(c.toString().slice(1, 7));
                                }
                            }
                        }
                    }
                    
                    // Cancel + Choose buttons (like reference)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 6
                            color: "transparent"
                            border.width: 1
                            border.color: Colours.palette.m3outline
                            
                            StyledText {
                                anchors.centerIn: parent
                                text: qsTr("Cancel")
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: colorPickerPopup.cancelPreview()
                            }
                        }
                        
                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 6
                            color: Colours.palette.m3primary  // Blue like reference
                            
                            StyledText {
                                anchors.centerIn: parent
                                text: qsTr("Choose")
                                color: Colours.palette.m3onPrimary
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: colorPickerPopup.applyChanges()
                            }
                        }
                    }
                }
            }
        }

    }
}