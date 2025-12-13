pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property Session session
    property int selectedZone: -1

    function getContrastColor(hexColor: string): color {
        if (!hexColor || hexColor.length < 7) return "#FFFFFF";
        var r = parseInt(hexColor.substring(1, 3), 16);
        var g = parseInt(hexColor.substring(3, 5), 16);
        var b = parseInt(hexColor.substring(5, 7), 16);
        var luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        return luminance > 0.5 ? "#000000" : "#FFFFFF";
    }

    StyledFlickable {
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        contentHeight: mainCol.height

        ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            // Header Icon
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "keyboard"
                font.pointSize: Appearance.font.size.extraLarge * 3
                color: Colours.palette.m3tertiary
            }

            // Title
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("RGB Keyboard")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            // Subtitle
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("4-Zone Lighting Control")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }

            // Not Available / Connecting State
            ColumnLayout {
                width: mainCol.width
                Layout.topMargin: 20
                visible: !Hardware.hasRgbKeyboard
                spacing: 10

                // Show different icon based on state
                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: Hardware.rgbServerState === 1 ? "sync" : "warning"
                    font.pointSize: 40
                    color: Hardware.rgbServerState === 1 ? Colours.palette.m3primary : Colours.palette.m3error
                    
                    // Spin animation when connecting
                    RotationAnimation on rotation {
                        running: Hardware.rgbServerState === 1
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Hardware.rgbServerState === 1 
                        ? qsTr("Connecting to OpenRGB...") 
                        : qsTr("RGB keyboard not detected")
                    color: Hardware.rgbServerState === 1 ? Colours.palette.m3primary : Colours.palette.m3error
                }
                
                // Retry info when connecting
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Hardware.rgbServerState === 1
                    text: qsTr("Retrying connection...")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                }
                
                // Manual refresh button when disconnected
                TextButton {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Hardware.rgbServerState === 0
                    text: qsTr("Retry Connection")
                    onClicked: Hardware.refreshRgb()
                }
            }

            // ========== MAIN CONTENT ==========
            ColumnLayout {
                width: mainCol.width
                visible: Hardware.hasRgbKeyboard
                spacing: Appearance.spacing.normal

                // Toggle Card - RGB ON/OFF
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: toggleContent.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    RowLayout {
                        id: toggleContent
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large

                        MaterialIcon {
                            text: "keyboard"
                            font.pointSize: Appearance.font.size.large
                            color: Colours.palette.m3onSurface
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("RGB Lighting")
                            font.pointSize: Appearance.font.size.larger
                            font.weight: 500
                            color: Colours.palette.m3onSurface
                        }

                        StyledSwitch {
                            checked: Hardware.rgbEnabled
                            onClicked: Hardware.toggleRgb()
                        }
                    }
                }

                // ========== MODE SELECTION (GRID) ==========
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Mode")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    opacity: Hardware.rgbEnabled ? 1 : 0.5
                }

                // Mode Grid - 2 columns
                Grid {
                    Layout.fillWidth: true
                    columns: 2
                    spacing: Appearance.spacing.small
                    opacity: Hardware.rgbEnabled ? 1 : 0.5

                    Repeater {
                        model: Hardware.rgbModes

                        StyledRect {
                            width: (mainCol.width - Appearance.spacing.small) / 2
                            height: 56
                            radius: Appearance.rounding.normal
                            color: Hardware.rgbCurrentMode === modelData ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
                            required property string modelData

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                spacing: Appearance.spacing.normal

                                MaterialIcon {
                                    text: {
                                        switch (modelData) {
                                            case "Direct": return "palette";
                                            case "Breathing": return "air";
                                            case "Rainbow Wave": return "waves";
                                            case "Spectrum Cycle": return "colorize";
                                            default: return "light_mode";
                                        }
                                    }
                                    font.pointSize: Appearance.font.size.large
                                    color: Hardware.rgbCurrentMode === modelData ? 
                                           Colours.palette.m3onPrimaryContainer : 
                                           Colours.palette.m3onSurface
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData
                                    font.pointSize: Appearance.font.size.normal
                                    elide: Text.ElideRight
                                    color: Hardware.rgbCurrentMode === modelData ? 
                                           Colours.palette.m3onPrimaryContainer : 
                                           Colours.palette.m3onSurface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Hardware.rgbEnabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hardware.setRgbMode(modelData)
                            }
                        }
                    }
                }

                // ========== SPEED SLIDER (for animated modes) ==========
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Animation Speed") + " - " + Math.round(speedSlider.value) + "%"
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    visible: Hardware.rgbModeSupportsSpeed && Hardware.rgbEnabled
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: speedContent.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    visible: Hardware.rgbModeSupportsSpeed && Hardware.rgbEnabled

                    RowLayout {
                        id: speedContent
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "slow_motion_video"
                            font.pointSize: Appearance.font.size.large
                            color: Colours.palette.m3onSurface
                        }

                        StyledSlider {
                            id: speedSlider
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            from: 0
                            to: 100
                            value: Hardware.rgbSpeed
                            onMoved: Hardware.setRgbSpeed(Math.round(value))
                        }

                        MaterialIcon {
                            text: "speed"
                            font.pointSize: Appearance.font.size.large
                            color: Colours.palette.m3onSurface
                        }
                    }
                }

                // ========== BREATHING COLOR (for Breathing mode) ==========
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Breathing Color")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    visible: Hardware.rgbCurrentMode === "Breathing" && Hardware.rgbEnabled
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: breathingColorContent.height + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    visible: Hardware.rgbCurrentMode === "Breathing" && Hardware.rgbEnabled

                    ColumnLayout {
                        id: breathingColorContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Appearance.padding.large
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.spacing.normal

                        // Color picker grid
                        Flow {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            Repeater {
                                model: ["#FF0000", "#FF4400", "#FF8800", "#FFBB00", "#FFFF00",
                                        "#88FF00", "#00FF00", "#00FF88", "#00FFFF", "#0088FF",
                                        "#0000FF", "#4400FF", "#8800FF", "#FF00FF", "#FF0088",
                                        "#FFFFFF"]

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: Appearance.rounding.small
                                    color: modelData
                                    border.width: Hardware.rgbBreathingColor.toUpperCase() === modelData ? 3 : 1
                                    border.color: Hardware.rgbBreathingColor.toUpperCase() === modelData ? Colours.palette.m3primary : Colours.palette.m3outline
                                    required property string modelData

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Hardware.setRgbBreathingColor(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                // ========== ZONE COLORS (for Direct mode) ==========
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Zone Colors")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    visible: Hardware.rgbModeIsZoned
                    opacity: Hardware.rgbEnabled ? 1 : 0.5
                }

                // Zone Colors Grid - 4 columns
                Grid {
                    Layout.fillWidth: true
                    columns: 4
                    spacing: Appearance.spacing.small
                    visible: Hardware.rgbModeIsZoned
                    opacity: Hardware.rgbEnabled ? 1 : 0.5

                    Repeater {
                        model: [
                            { zone: 0, name: "Left", fallback: "#FF0000" },
                            { zone: 1, name: "L-Mid", fallback: "#00FF00" },
                            { zone: 2, name: "R-Mid", fallback: "#0000FF" },
                            { zone: 3, name: "Right", fallback: "#FF00FF" }
                        ]

                        Rectangle {
                            width: (mainCol.width - Appearance.spacing.small * 3) / 4
                            height: 56
                            radius: Appearance.rounding.normal
                            color: Hardware.rgbColors[modelData.zone] || modelData.fallback
                            border.width: root.selectedZone === modelData.zone ? 3 : 0
                            border.color: Colours.palette.m3primary
                            required property var modelData

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.name
                                font.weight: 600
                                font.pointSize: Appearance.font.size.normal
                                color: root.getContrastColor(parent.color.toString())
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Hardware.rgbEnabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.selectedZone === modelData.zone) {
                                        root.selectedZone = -1;
                                    } else {
                                        root.selectedZone = modelData.zone;
                                    }
                                }
                            }
                        }
                    }
                }

                // Zone Color Picker (when zone selected)
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: zoneColorPickerContent.height + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    visible: root.selectedZone >= 0 && Hardware.rgbEnabled && Hardware.rgbModeIsZoned

                    ColumnLayout {
                        id: zoneColorPickerContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Appearance.padding.large
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: qsTr("Pick color for Zone %1").arg(root.selectedZone + 1)
                            font.weight: 500
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            Repeater {
                                model: ["#FF0000", "#FF4400", "#FF8800", "#FFBB00", "#FFFF00",
                                        "#88FF00", "#00FF00", "#00FF88", "#00FFFF", "#0088FF",
                                        "#0000FF", "#4400FF", "#8800FF", "#FF00FF", "#FF0088",
                                        "#FFFFFF"]

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: Appearance.rounding.small
                                    color: modelData
                                    border.width: 1
                                    border.color: Colours.palette.m3outline
                                    required property string modelData

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Hardware.setRgbColor(root.selectedZone, modelData);
                                            root.selectedZone = -1; // Deselect after picking
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ========== PRESETS ==========
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Quick Presets")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    opacity: Hardware.rgbEnabled ? 1 : 0.5
                }

                Grid {
                    Layout.fillWidth: true
                    columns: 3
                    spacing: Appearance.spacing.small
                    opacity: Hardware.rgbEnabled ? 1 : 0.5

                    Repeater {
                        model: Hardware.rgbPresets

                        StyledRect {
                            width: (mainCol.width - Appearance.spacing.small * 2) / 3
                            height: 60
                            radius: Appearance.rounding.normal
                            color: Colours.tPalette.m3surfaceContainer
                            required property var modelData
                            required property int index

                            Column {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.smaller

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2

                                    Repeater {
                                        model: 4

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 4
                                            required property int index
                                            color: {
                                                var c = modelData.colors;
                                                return c && c[index] ? c[index] : "#888";
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.name || "Preset"
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSurface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Hardware.rgbEnabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hardware.setRgbPreset(index)
                            }
                        }
                    }
                }

                // Bottom padding for FAB
                Item { Layout.preferredHeight: 80 }
            }
        }
    }

    // =====================================================
    // FAB Menu for quick actions (like Monitor)
    // =====================================================
    ColumnLayout {
        anchors.right: fabRoot.right
        anchors.bottom: fabRoot.top
        anchors.bottomMargin: Appearance.padding.normal
        visible: Hardware.hasRgbKeyboard

        Repeater {
            id: fabMenu

            model: ListModel {
                ListElement {
                    name: "save"
                    icon: "save"
                    action: "save"
                }
                ListElement {
                    name: "revert"
                    icon: "undo"
                    action: "revert"
                }
                ListElement {
                    name: "reset"
                    icon: "restart_alt"
                    action: "reset"
                }
            }

            StyledClippingRect {
                id: fabMenuItem

                required property var modelData
                required property int index

                readonly property bool isRevert: modelData.action === "revert"
                readonly property bool isReset: modelData.action === "reset"
                readonly property bool isSave: modelData.action === "save"
                
                // Save and Revert only visible when there are changes
                visible: isReset || ((isRevert || isSave) && Hardware.rgbHasChanges)

                Layout.alignment: Qt.AlignRight

                implicitHeight: fabMenuItemInner.implicitHeight + Appearance.padding.larger * 2

                radius: Appearance.rounding.full
                color: isSave ? Colours.palette.m3primaryContainer : 
                       (isReset ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer)

                opacity: 0

                states: State {
                    name: "visible"
                    when: root.session.hw.fabMenuOpen

                    PropertyChanges {
                        fabMenuItem.implicitWidth: fabMenuItemInner.implicitWidth + Appearance.padding.large * 2
                        fabMenuItem.opacity: 1
                        fabMenuItemInner.opacity: 1
                    }
                }

                transitions: [
                    Transition {
                        to: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: (fabMenu.count - 1 - fabMenuItem.index) * Appearance.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                FabAnim {
                                    property: "implicitWidth"
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                                FabAnim {
                                    property: "opacity"
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    },
                    Transition {
                        from: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: fabMenuItem.index * Appearance.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                FabAnim {
                                    property: "implicitWidth"
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                                FabAnim {
                                    property: "opacity"
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    }
                ]

                StateLayer {
                    color: fabMenuItem.isSave ? Colours.palette.m3onPrimaryContainer :
                           (fabMenuItem.isReset ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer)

                    function onClicked(): void {
                        root.session.hw.fabMenuOpen = false;

                        const action = fabMenuItem.modelData.action;
                        if (action === "save") {
                            Hardware.saveRgbState();
                            fabRoot.showSavedStatus();
                        } else if (action === "revert") {
                            Hardware.revertRgbChanges();
                            fabRoot.showRevertedStatus();
                        } else if (action === "reset") {
                            Hardware.resetRgbToDefault();
                        }
                    }
                }

                RowLayout {
                    id: fabMenuItemInner

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.normal
                    opacity: 0

                    MaterialIcon {
                        text: fabMenuItem.modelData.icon
                        color: fabMenuItem.isSave ? Colours.palette.m3onPrimaryContainer :
                               (fabMenuItem.isReset ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer)
                        fill: 1
                    }

                    StyledText {
                        animate: true
                        text: fabMenuItem.isSave ? qsTr("Save") : 
                              (fabMenuItem.isReset ? qsTr("Reset") : qsTr("Revert"))
                        color: fabMenuItem.isSave ? Colours.palette.m3onPrimaryContainer :
                               (fabMenuItem.isReset ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer)
                        font.capitalization: Font.Capitalize
                        Layout.preferredWidth: implicitWidth
                    }
                }
            }
        }
    }

    // FAB Button with Status Display
    Item {
        id: fabRoot

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: Hardware.hasRgbKeyboard

        implicitWidth: 64
        implicitHeight: 64

        // FAB Status States
        property int fabStatus: 0  // 0=normal, 1=busy, 2=connecting, 3=saved, 4=reverted
        property string fabStatusText: ""

        // Timer to reset status back to normal
        Timer {
            id: fabStatusResetTimer
            interval: 2000
            onTriggered: fabRoot.fabStatus = 0
        }

        // Watch for busy state changes
        Connections {
            target: Hardware
            function onRgbBusyChanged() {
                if (Hardware.rgbBusy && !root.session.hw.fabMenuOpen) {
                    fabRoot.fabStatus = 1;
                    fabRoot.fabStatusText = qsTr("Applying...");
                    fabStatusResetTimer.restart();
                }
            }
            function onRgbServerStateChanged() {
                if (Hardware.rgbServerState === 1 && !root.session.hw.fabMenuOpen) {
                    fabRoot.fabStatus = 2;
                    fabRoot.fabStatusText = qsTr("Connecting...");
                    fabStatusResetTimer.stop();
                } else if (Hardware.rgbServerState === 2 && fabRoot.fabStatus === 2) {
                    fabRoot.fabStatus = 0;
                }
            }
        }

        // Function to show saved/reverted status
        function showSavedStatus() {
            fabStatus = 3;
            fabStatusText = qsTr("Saved!");
            fabStatusResetTimer.restart();
        }
        function showRevertedStatus() {
            fabStatus = 4;
            fabStatusText = qsTr("Reverted!");
            fabStatusResetTimer.restart();
        }

        StyledRect {
            id: fabBg

            anchors.right: parent.right
            anchors.top: parent.top

            // Expand width when showing status text
            readonly property bool showingStatus: fabRoot.fabStatus > 0 && !root.session.hw.fabMenuOpen
            readonly property real expandedWidth: fabStatusRow.implicitWidth + Appearance.padding.large * 2

            implicitWidth: showingStatus ? Math.max(64, expandedWidth) : 64
            implicitHeight: 64

            radius: showingStatus ? Appearance.rounding.full : Appearance.rounding.normal
            color: {
                if (root.session.hw.fabMenuOpen) return Colours.palette.m3primary;
                switch (fabRoot.fabStatus) {
                    case 1: return Colours.palette.m3tertiaryContainer;  // Busy/Applying
                    case 2: return Colours.palette.m3secondaryContainer; // Connecting
                    case 3: return Colours.palette.m3primaryContainer;   // Saved
                    case 4: return Colours.palette.m3secondaryContainer; // Reverted
                    default: return Colours.palette.m3primaryContainer;
                }
            }

            Behavior on implicitWidth {
                FabAnim {
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
            }
            Behavior on radius { FabAnim {} }
            Behavior on color { ColorAnimation { duration: Appearance.anim.durations.normal } }

            states: State {
                name: "expanded"
                when: root.session.hw.fabMenuOpen

                PropertyChanges {
                    fabBg.implicitWidth: 48
                    fabBg.implicitHeight: 48
                    fabBg.radius: 48 / 2
                    fab.font.pointSize: Appearance.font.size.larger
                }
            }

            transitions: Transition {
                FabAnim {
                    properties: "implicitWidth,implicitHeight"
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
                FabAnim {
                    properties: "radius,font.pointSize"
                }
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: fabState.containsMouse && !fabState.pressed ? 4 : 3
            }

            StateLayer {
                id: fabState

                color: {
                    if (root.session.hw.fabMenuOpen) return Colours.palette.m3onPrimary;
                    switch (fabRoot.fabStatus) {
                        case 1: return Colours.palette.m3onTertiaryContainer;
                        case 2: return Colours.palette.m3onSecondaryContainer;
                        case 3: return Colours.palette.m3onPrimaryContainer;
                        case 4: return Colours.palette.m3onSecondaryContainer;
                        default: return Colours.palette.m3onPrimaryContainer;
                    }
                }

                function onClicked(): void {
                    if (fabRoot.fabStatus > 0 && !root.session.hw.fabMenuOpen) {
                        // If showing status, clicking resets to normal
                        fabRoot.fabStatus = 0;
                        fabStatusResetTimer.stop();
                    } else {
                        root.session.hw.fabMenuOpen = !root.session.hw.fabMenuOpen;
                    }
                }
            }

            // Status content (icon + text when showing status)
            Row {
                id: fabStatusRow
                anchors.centerIn: parent
                spacing: Appearance.spacing.small
                visible: fabBg.showingStatus

                CircularIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    visible: fabRoot.fabStatus === 1 || fabRoot.fabStatus === 2
                }

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: fabRoot.fabStatus === 3 ? "check_circle" : "undo"
                    visible: fabRoot.fabStatus === 3 || fabRoot.fabStatus === 4
                    color: fabRoot.fabStatus === 3 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSecondaryContainer
                    font.pointSize: Appearance.font.size.large
                    fill: 1
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: fabRoot.fabStatusText
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                    color: {
                        switch (fabRoot.fabStatus) {
                            case 1: return Colours.palette.m3onTertiaryContainer;
                            case 2: return Colours.palette.m3onSecondaryContainer;
                            case 3: return Colours.palette.m3onPrimaryContainer;
                            case 4: return Colours.palette.m3onSecondaryContainer;
                            default: return Colours.palette.m3onPrimaryContainer;
                        }
                    }
                }
            }

            // Normal FAB icon (when not showing status)
            MaterialIcon {
                id: fab

                anchors.centerIn: parent
                animate: true
                visible: !fabBg.showingStatus
                text: root.session.hw.fabMenuOpen ? "close" : "more_vert"
                color: root.session.hw.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer
                font.pointSize: Appearance.font.size.large
                fill: 1
            }
        }
    }

    component FabAnim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
