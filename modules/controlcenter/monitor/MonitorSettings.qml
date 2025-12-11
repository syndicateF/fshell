pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    readonly property var monitor: Monitors.selectedMonitor
    readonly property var monitorData: Monitors.getMonitorData(monitor?.name ?? "")
    readonly property var availableResolutions: Monitors.getAvailableResolutions(monitor)
    readonly property var currentResolution: monitor ? { width: monitor.width, height: monitor.height } : null
    readonly property real currentRefreshRate: Monitors.getCurrentRefreshRate(monitor)

    StyledFlickable {
        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: mainLayout.height

        ColumnLayout {
            id: mainLayout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            // Header Icon - same style as Network/Bluetooth Settings
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "monitor"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            // Monitor name as title
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.monitor?.name ?? ""
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            // Monitor model as subtitle
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: (root.monitor?.model ?? root.monitor?.description ?? "") !== ""
                text: root.monitor?.model ?? root.monitor?.description ?? ""
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3outline
            }

            // Error message
            StyledRect {
                Layout.fillWidth: true
                visible: Monitors.applyError !== ""
                implicitHeight: errorRow.implicitHeight + Appearance.padding.small * 2

                radius: Appearance.rounding.small
                color: Colours.palette.m3errorContainer

                RowLayout {
                    id: errorRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.small
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "error"
                        color: Colours.palette.m3onErrorContainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Monitors.applyError
                        color: Colours.palette.m3onErrorContainer
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // =====================================================
            // Quick Actions Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Quick actions")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Monitor control options")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: quickActionsContent.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: quickActionsContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Check if this is the last active monitor
                    readonly property bool isLastActiveMonitor: {
                        if (root.monitor?.disabled) return false; // Already disabled, can enable
                        // Count active (non-disabled) monitors
                        let activeCount = 0;
                        for (let i = 0; i < Monitors.monitorCount; i++) {
                            const mon = Monitors.monitors.values[i];
                            if (!mon.disabled) activeCount++;
                        }
                        return activeCount <= 1;
                    }

                    // Enable/Disable row
                    RowLayout {
                        id: enableDisableRow
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        ActionButton {
                            Layout.fillWidth: true
                            icon: root.monitor?.disabled ? "desktop_windows" : "desktop_access_disabled"
                            label: root.monitor?.disabled ? qsTr("Enable") : qsTr("Disable")
                            accent: root.monitor?.disabled ? "Primary" : "Error"
                            enabled: root.monitor?.disabled || !quickActionsContent.isLastActiveMonitor
                            opacity: enabled ? 1 : 0.5

                            function onClicked(): void {
                                if (root.monitor?.disabled) {
                                    Monitors.enableMonitor(root.monitor);
                                } else {
                                    Monitors.disableMonitor(root.monitor);
                                }
                            }
                        }
                    }

                    // Warning when can't disable
                    StyledRect {
                        Layout.fillWidth: true
                        visible: !root.monitor?.disabled && quickActionsContent.isLastActiveMonitor
                        implicitHeight: cantDisableRow.implicitHeight + Appearance.padding.small * 2
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3errorContainer
                        
                        RowLayout {
                            id: cantDisableRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Appearance.padding.small
                            spacing: Appearance.spacing.small
                            
                            MaterialIcon {
                                text: "warning"
                                color: Colours.palette.m3onErrorContainer
                                font.pointSize: Appearance.font.size.normal
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Cannot disable the last active monitor. You need at least one active display to use the system.")
                                color: Colours.palette.m3onErrorContainer
                                font.pointSize: Appearance.font.size.smaller
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // DPMS Section
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }

                    // DPMS Info
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: dpmsIcon.implicitHeight + Appearance.padding.normal * 2
                            radius: Appearance.rounding.normal
                            color: root.monitorData?.dpmsStatus ? Colours.palette.m3primaryContainer : Colours.palette.m3errorContainer

                            MaterialIcon {
                                id: dpmsIcon
                                anchors.centerIn: parent
                                text: root.monitorData?.dpmsStatus ? "visibility" : "visibility_off"
                                color: root.monitorData?.dpmsStatus ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onErrorContainer
                                font.pointSize: Appearance.font.size.large
                            }

                            Behavior on color { CAnim {} }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: qsTr("Display Power (DPMS)")
                                font.weight: 500
                            }

                            StyledText {
                                text: root.monitorData?.dpmsStatus ? qsTr("Screen is on and active") : qsTr("Screen is off (power saving)")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outline
                            }
                        }
                    }

                    // DPMS Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        ActionButton {
                            Layout.fillWidth: true
                            icon: "visibility"
                            label: qsTr("Turn On")
                            accent: "Primary"
                            enabled: !(root.monitorData?.dpmsStatus ?? true)
                            opacity: enabled ? 1 : 0.5

                            function onClicked(): void {
                                Monitors.setDpms(root.monitor, true);
                            }
                        }

                        ActionButton {
                            Layout.fillWidth: true
                            icon: "visibility_off"
                            label: qsTr("Turn Off")
                            accent: "Error"
                            enabled: root.monitorData?.dpmsStatus ?? false
                            opacity: enabled ? 1 : 0.5

                            function onClicked(): void {
                                Monitors.setDpms(root.monitor, false);
                            }
                        }
                    }

                    // DPMS explanation
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("DPMS (Display Power Management Signaling) controls the power state of your monitor. Turning it off puts the display into sleep mode to save power. The monitor will wake up when you move your mouse or press a key.")
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // =====================================================
            // Display Mode Section (Mirror/Extend/Single)
            // Only show if there are multiple monitors
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                visible: Monitors.monitorCount > 1
                text: qsTr("Display mode")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                visible: Monitors.monitorCount > 1
                text: qsTr("Configure how this display works with others")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                visible: Monitors.monitorCount > 1
                implicitHeight: displayModeContent.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: displayModeContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Visual Preview of current mode
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        
                        // Preview container with subtle background
                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.5)
                            
                            // Mode preview illustration
                            Row {
                                anchors.centerIn: parent
                                spacing: {
                                    const mirrorOf = root.monitorData?.mirrorOf ?? "none";
                                    return (mirrorOf !== "none" && mirrorOf !== "") ? -20 : 15;
                                }
                                
                                // Primary monitor illustration
                                DisplayPreview {
                                    id: primaryPreview
                                    width: 80
                                    height: 60
                                    isPrimary: true
                                    label: {
                                        const mirrorOf = root.monitorData?.mirrorOf ?? "none";
                                        return (mirrorOf !== "none" && mirrorOf !== "") ? mirrorOf : "1";
                                    }
                                    showContent: true
                                    isMirrored: (root.monitorData?.mirrorOf ?? "none") !== "none" && (root.monitorData?.mirrorOf ?? "") !== ""
                                }
                                
                                // Secondary monitor illustration
                                DisplayPreview {
                                    id: secondaryPreview
                                    width: 80
                                    height: 60
                                    isPrimary: false
                                    label: {
                                        const mirrorOf = root.monitorData?.mirrorOf ?? "none";
                                        return (mirrorOf !== "none" && mirrorOf !== "") ? root.monitor?.name ?? "2" : "2";
                                    }
                                    showContent: true
                                    isMirrored: (root.monitorData?.mirrorOf ?? "none") !== "none" && (root.monitorData?.mirrorOf ?? "") !== ""
                                    opacity: 1
                                    
                                    // Animation when switching modes
                                    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                }
                            }
                            
                            // Mode label overlay
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 8
                                
                                width: modePreviewLabel.implicitWidth + 16
                                height: modePreviewLabel.implicitHeight + 6
                                radius: height / 2
                                color: {
                                    const mirrorOf = root.monitorData?.mirrorOf ?? "none";
                                    if (mirrorOf !== "none" && mirrorOf !== "") return Colours.palette.m3tertiaryContainer;
                                    return Colours.palette.m3secondaryContainer;
                                }
                                
                                StyledText {
                                    id: modePreviewLabel
                                    anchors.centerIn: parent
                                    text: {
                                        const mirrorOf = root.monitorData?.mirrorOf ?? "none";
                                        if (mirrorOf !== "none" && mirrorOf !== "") return qsTr("Mirror");
                                        return qsTr("Extended");
                                    }
                                    font.pointSize: Appearance.font.size.smaller
                                    font.weight: 500
                                    color: {
                                        const mirrorOf = root.monitorData?.mirrorOf ?? "none";
                                        if (mirrorOf !== "none" && mirrorOf !== "") return Colours.palette.m3onTertiaryContainer;
                                        return Colours.palette.m3onSecondaryContainer;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }

                    // Mode selection buttons
                    StyledText {
                        text: qsTr("Change mode")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    // Extend (Default) button
                    ModeButton {
                        Layout.fillWidth: true
                        icon: "expand"
                        label: qsTr("Extend")
                        description: qsTr("Use as separate display extending your desktop")
                        isActive: (root.monitorData?.mirrorOf ?? "none") === "none" || (root.monitorData?.mirrorOf ?? "") === ""

                        function onClicked(): void {
                            // Remove mirror, use as extended display
                            Monitors.enableMonitor(root.monitor);
                        }
                    }

                    // Mirror buttons - one for each other monitor
                    Repeater {
                        model: {
                            // Get list of other monitors to mirror to
                            let others = [];
                            for (let i = 0; i < Monitors.monitorCount; i++) {
                                const mon = Monitors.monitors.values[i];
                                if (mon && mon.name !== root.monitor?.name && !mon.disabled) {
                                    others.push(mon);
                                }
                            }
                            return others;
                        }

                        ModeButton {
                            required property var modelData

                            Layout.fillWidth: true
                            icon: "content_copy"
                            label: qsTr("Mirror to %1").arg(modelData.name)
                            description: qsTr("Show same content as %1").arg(modelData.name)
                            isActive: root.monitorData?.mirrorOf === modelData.name
                            accent: "Tertiary"

                            function onClicked(): void {
                                Monitors.mirrorTo(root.monitor, modelData);
                            }
                        }
                    }

                    // Info text
                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.small
                        text: qsTr("Mirror mode shows identical content on both displays. Resolution will match the target monitor. Extended mode lets you use displays independently.")
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3outline
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // =====================================================
            // Resolution Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Resolution")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Select display resolution")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: resolutionFlow.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Flow {
                    id: resolutionFlow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: root.availableResolutions ?? []

                        Chip {
                            required property var modelData

                            text: `${modelData.width}×${modelData.height}`
                            isSelected: root.currentResolution &&
                                root.currentResolution.width === modelData.width &&
                                root.currentResolution.height === modelData.height
                            isPending: Monitors.hasPendingResolution(root.monitor, modelData.width, modelData.height)

                            function onClicked(): void {
                                Monitors.setResolution(root.monitor, modelData.width, modelData.height);
                            }
                        }
                    }
                }
            }

            // =====================================================
            // Refresh Rate Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Refresh rate")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Select refresh rate in Hz")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: refreshRateFlow.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Flow {
                    id: refreshRateFlow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: Monitors.getAvailableRefreshRates(root.monitor, root.currentResolution?.width, root.currentResolution?.height) ?? []

                        Chip {
                            required property real modelData

                            text: `${modelData.toFixed(0)} Hz`
                            isSelected: Math.abs(root.currentRefreshRate - modelData) < 1
                            isPending: Monitors.hasPendingRefreshRate(root.monitor, modelData)

                            function onClicked(): void {
                                Monitors.setRefreshRate(root.monitor, modelData);
                            }
                        }
                    }
                }
            }

            // =====================================================
            // Scale Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Scale")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Display scaling factor")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: scaleContent.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: scaleContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Hyprland compatible scales - these are values that work well
                    // Based on common divisors that don't cause rendering issues
                    readonly property var hyprlandScales: [
                        0.5,      // 1/2
                        0.666667, // 2/3
                        0.75,     // 3/4
                        0.8,      // 4/5
                        1.0,      // 1/1
                        1.066667, // 16/15 (for 1080p on 4K-ish)
                        1.2,      // 6/5
                        1.25,     // 5/4
                        1.333333, // 4/3 - YOUR PREFERRED!
                        1.4,      // 7/5
                        1.5,      // 3/2
                        1.6,      // 8/5
                        1.666667, // 5/3
                        1.75,     // 7/4
                        1.8,      // 9/5
                        2.0,      // 2/1
                        2.25,     // 9/4
                        2.5,      // 5/2
                        2.666667, // 8/3
                        3.0       // 3/1
                    ]

                    // Find nearest Hyprland-compatible scale
                    function findNearestScale(target: real): real {
                        let nearest = hyprlandScales[0];
                        let minDiff = Math.abs(target - nearest);
                        
                        for (let i = 1; i < hyprlandScales.length; i++) {
                            const diff = Math.abs(target - hyprlandScales[i]);
                            if (diff < minDiff) {
                                minDiff = diff;
                                nearest = hyprlandScales[i];
                            }
                        }
                        return nearest;
                    }

                    // Get index of scale in array
                    function getScaleIndex(scale: real): int {
                        for (let i = 0; i < hyprlandScales.length; i++) {
                            if (Math.abs(hyprlandScales[i] - scale) < 0.001) return i;
                        }
                        return 4; // default to 1.0
                    }

                    // Format scale for display
                    function formatScale(scale: real): string {
                        // Show cleaner numbers where possible
                        if (Math.abs(scale - Math.round(scale)) < 0.001) {
                            return scale.toFixed(0);
                        } else if (Math.abs(scale * 4 - Math.round(scale * 4)) < 0.001) {
                            return scale.toFixed(2);
                        } else {
                            return scale.toFixed(2);
                        }
                    }

                    // Current scale display
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: scaleIcon.implicitHeight + Appearance.padding.normal * 2
                            radius: Appearance.rounding.normal
                            color: Colours.palette.m3secondaryContainer

                            MaterialIcon {
                                id: scaleIcon
                                anchors.centerIn: parent
                                text: "fit_screen"
                                color: Colours.palette.m3onSecondaryContainer
                                font.pointSize: Appearance.font.size.large
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: qsTr("Current Scale")
                                font.weight: 500
                            }

                            StyledText {
                                readonly property real currentScale: root.monitor?.scale ?? 1
                                readonly property real pendingScale: scaleContent.hyprlandScales[scaleSlider.value] ?? 1
                                readonly property bool hasPending: Monitors.hasPendingScale(root.monitor, pendingScale)
                                
                                text: `${scaleContent.formatScale(currentScale)}x` + (hasPending ? ` → ${scaleContent.formatScale(pendingScale)}x` : "")
                                font.pointSize: Appearance.font.size.small
                                color: hasPending ? Colours.palette.m3primary : Colours.palette.m3outline
                            }
                        }
                    }

                    // Scale slider - now uses index-based for Hyprland-compatible values
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: "0.5x"
                            font.pointSize: Appearance.font.size.smaller
                            color: Colours.palette.m3outline
                        }

                        StyledSlider {
                            id: scaleSlider
                            Layout.fillWidth: true

                            // Slider now uses INDEX into hyprlandScales array
                            from: 0
                            to: scaleContent.hyprlandScales.length - 1
                            stepSize: 1
                            value: scaleContent.getScaleIndex(root.monitor?.scale ?? 1)

                            readonly property real actualScale: scaleContent.hyprlandScales[Math.round(value)] ?? 1

                            onMoved: {
                                Monitors.setScale(root.monitor, actualScale);
                            }
                        }

                        StyledText {
                            text: "3x"
                            font.pointSize: Appearance.font.size.smaller
                            color: Colours.palette.m3outline
                        }
                    }

                    // Current slider value indicator
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: sliderValueRow.implicitHeight + Appearance.padding.small * 2
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3primaryContainer
                        
                        RowLayout {
                            id: sliderValueRow
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small
                            
                            MaterialIcon {
                                text: "straighten"
                                color: Colours.palette.m3onPrimaryContainer
                                font.pointSize: Appearance.font.size.normal
                            }
                            
                            StyledText {
                                text: qsTr("Selected: %1x").arg(scaleContent.formatScale(scaleSlider.actualScale))
                                color: Colours.palette.m3onPrimaryContainer
                                font.weight: 500
                            }
                            
                            StyledText {
                                visible: Math.abs(scaleSlider.actualScale - 1.333333) < 0.001
                                text: qsTr("(4:3 ratio - great for HiDPI!)")
                                color: Colours.palette.m3onPrimaryContainer
                                font.pointSize: Appearance.font.size.smaller
                            }
                        }
                    }

                    // Popular presets
                    StyledText {
                        Layout.topMargin: Appearance.spacing.small
                        text: qsTr("Popular presets")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3outline
                    }

                    Flow {
                        id: scaleFlow
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        Repeater {
                            // Popular scales with friendly names
                            model: [
                                { value: 1.0, label: "100%" },
                                { value: 1.25, label: "125%" },
                                { value: 1.333333, label: "133%" },
                                { value: 1.5, label: "150%" },
                                { value: 1.75, label: "175%" },
                                { value: 2.0, label: "200%" }
                            ]

                            Chip {
                                required property var modelData

                                text: modelData.label
                                isSelected: Math.abs((root.monitor?.scale ?? 1) - modelData.value) < 0.01
                                isPending: Monitors.hasPendingScale(root.monitor, modelData.value)

                                function onClicked(): void {
                                    Monitors.setScale(root.monitor, modelData.value);
                                    scaleSlider.value = scaleContent.getScaleIndex(modelData.value);
                                }
                            }
                        }
                    }

                    // Info about Hyprland scaling
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.small
                        implicitHeight: scaleInfoRow.implicitHeight + Appearance.padding.small * 2
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3tertiaryContainer
                        
                        RowLayout {
                            id: scaleInfoRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Appearance.padding.small
                            spacing: Appearance.spacing.small
                            
                            MaterialIcon {
                                text: "info"
                                color: Colours.palette.m3onTertiaryContainer
                                font.pointSize: Appearance.font.size.small
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Hyprland works best with specific scale values (fractions like 4/3, 3/2, etc). The slider only shows compatible values to avoid rendering issues.")
                                color: Colours.palette.m3onTertiaryContainer
                                font.pointSize: Appearance.font.size.smaller
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // =====================================================
            // Transform Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Transform")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Rotation and mirroring")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: transformFlow.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                Flow {
                    id: transformFlow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: Monitors.transformNames

                        Chip {
                            required property string modelData
                            required property int index

                            text: modelData
                            isSelected: (root.monitor?.transform ?? 0) === index
                            isPending: Monitors.hasPendingTransform(root.monitor, index)

                            function onClicked(): void {
                                Monitors.setTransform(root.monitor, index);
                            }
                        }
                    }
                }
            }

            // =====================================================
            // Monitor Capabilities Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Capabilities")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Detected display features")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: capColumn.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: capColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small

                    property var caps: Monitors.getMonitorCapabilities(root.monitor)

                    // Connection Type
                    CapabilityRow {
                        icon: "cable"
                        label: qsTr("Connection")
                        value: capColumn.caps.connectionType ?? "Unknown"
                        supported: true
                    }

                    // High Refresh Rate
                    CapabilityRow {
                        icon: "speed"
                        label: qsTr("High Refresh Rate")
                        value: capColumn.caps.isHighRefresh ? qsTr("Up to %1 Hz").arg(Math.round(capColumn.caps.maxRefreshRate ?? 60)) : qsTr("Standard (60 Hz)")
                        supported: capColumn.caps.isHighRefresh ?? false
                    }

                    // VRR/Adaptive Sync
                    CapabilityRow {
                        icon: "display_settings"
                        label: qsTr("VRR/Adaptive Sync")
                        value: capColumn.caps.vrrCapable ? qsTr("Likely supported") : qsTr("Not detected")
                        supported: capColumn.caps.vrrCapable ?? false
                        description: capColumn.caps.vrrReason ?? ""
                    }

                    // Resolution Modes
                    CapabilityRow {
                        icon: "aspect_ratio"
                        label: qsTr("Resolution Modes")
                        value: qsTr("%1 modes available").arg(capColumn.caps.modeCount ?? 0)
                        supported: (capColumn.caps.modeCount ?? 0) > 1
                    }
                }
            }

            // =====================================================
            // Display Info Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Display information")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Current display properties")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: infoColumn.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: infoColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small / 2

                    InfoRow { label: qsTr("Name"); value: root.monitor?.name ?? "-" }
                    InfoRow { label: qsTr("Description"); value: root.monitor?.description || "-" }
                    InfoRow { label: qsTr("Make"); value: root.monitorData?.make || "-" }
                    InfoRow { label: qsTr("Model"); value: root.monitorData?.model || "-" }
                    InfoRow { label: qsTr("Serial"); value: root.monitorData?.serial || qsTr("Not available") }
                    InfoRow { label: qsTr("Resolution"); value: `${root.monitor?.width ?? 0}×${root.monitor?.height ?? 0}` }
                    InfoRow { label: qsTr("Refresh Rate"); value: `${root.currentRefreshRate.toFixed(2)} Hz` }
                    InfoRow { label: qsTr("Scale"); value: `${(root.monitor?.scale ?? 1).toFixed(2)}x` }
                    InfoRow { label: qsTr("Transform"); value: Monitors.transformNames[root.monitor?.transform ?? 0] ?? "Normal" }
                    InfoRow { label: qsTr("Position"); value: `${root.monitor?.x ?? 0}, ${root.monitor?.y ?? 0}` }
                    InfoRow { label: qsTr("Physical Size"); value: `${root.monitorData?.physicalWidth ?? 0}×${root.monitorData?.physicalHeight ?? 0} mm` }
                    InfoRow { label: qsTr("DPMS Status"); value: root.monitorData?.dpmsStatus ? qsTr("On") : qsTr("Off"); valueColor: root.monitorData?.dpmsStatus ? Colours.palette.m3primary : Colours.palette.m3error }
                    InfoRow { label: qsTr("VRR (Global)"); value: Monitors.vrrModes[Monitors.globalVrr]?.name ?? "Off"; valueColor: Monitors.globalVrr > 0 ? Colours.palette.m3tertiary : Colours.palette.m3onSurface }
                }
            }

            // Bottom spacer
            Item { Layout.preferredHeight: Appearance.padding.large * 2 }
        }
    }

    // =====================================================
    // FAB Menu for quick actions
    // =====================================================
    ColumnLayout {
        anchors.right: fabRoot.right
        anchors.bottom: fabRoot.top
        anchors.bottomMargin: Appearance.padding.normal

        Repeater {
            id: fabMenu

            model: ListModel {
                ListElement {
                    name: "apply"
                    icon: "check"
                    action: "apply"
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

                readonly property bool isApply: modelData.action === "apply"
                readonly property bool isRevert: modelData.action === "revert"
                readonly property bool isReset: modelData.action === "reset"
                readonly property bool shouldShow: {
                    // Only show Apply/Revert when there are pending changes
                    if (isApply) return Monitors.hasPendingChanges();
                    if (isRevert) return Monitors.hasAnyPendingChanges(root.monitor);
                    // Reset to Default always visible
                    return true;
                }

                visible: shouldShow

                Layout.alignment: Qt.AlignRight

                implicitHeight: fabMenuItemInner.implicitHeight + Appearance.padding.larger * 2

                radius: Appearance.rounding.full
                color: isApply ? Colours.palette.m3primaryContainer : isReset ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer

                opacity: 0

                states: State {
                    name: "visible"
                    when: root.session.mon.fabMenuOpen

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
                    color: fabMenuItem.isApply ? Colours.palette.m3onPrimaryContainer : fabMenuItem.isReset ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer

                    function onClicked(): void {
                        root.session.mon.fabMenuOpen = false;

                        const action = fabMenuItem.modelData.action;
                        if (action === "apply") {
                            Monitors.applyConfig();
                        } else if (action === "revert") {
                            Monitors.clearPendingChanges(root.monitor);
                        } else if (action === "reset") {
                            Monitors.resetToDefault(root.monitor);
                        }
                    }
                }

                RowLayout {
                    id: fabMenuItemInner

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small
                    opacity: 0

                    MaterialIcon {
                        text: fabMenuItem.modelData.icon
                        color: fabMenuItem.isApply ? Colours.palette.m3onPrimaryContainer : fabMenuItem.isReset ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer
                    }

                    StyledText {
                        text: fabMenuItem.isApply ? qsTr("Apply") : fabMenuItem.isReset ? qsTr("Reset") : qsTr("Revert")
                        color: fabMenuItem.isApply ? Colours.palette.m3onPrimaryContainer : fabMenuItem.isReset ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer
                    }
                }
            }
        }
    }

    // FAB Button
    Item {
        id: fabRoot

        anchors.right: parent.right
        anchors.bottom: parent.bottom

        implicitWidth: 64
        implicitHeight: 64

        StyledRect {
            id: fabBg

            anchors.right: parent.right
            anchors.top: parent.top

            implicitWidth: 64
            implicitHeight: 64

            radius: Appearance.rounding.normal
            color: root.session.mon.fabMenuOpen ? Colours.palette.m3primary : Colours.palette.m3primaryContainer

            states: State {
                name: "expanded"
                when: root.session.mon.fabMenuOpen

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

                color: root.session.mon.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer

                function onClicked(): void {
                    root.session.mon.fabMenuOpen = !root.session.mon.fabMenuOpen;
                }
            }

            MaterialIcon {
                id: fab

                anchors.centerIn: parent
                animate: true
                text: root.session.mon.fabMenuOpen ? "close" : "more_vert"
                color: root.session.mon.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer
                font.pointSize: Appearance.font.size.large
                fill: 1
            }
        }
    }

    // =====================================================
    // Components
    // =====================================================

    component Chip: StyledRect {
        property string text
        property bool isSelected: false
        property bool isPending: false

        function onClicked(): void {}

        implicitWidth: chipText.implicitWidth + Appearance.padding.small * 2
        implicitHeight: chipText.implicitHeight + Appearance.padding.smaller * 2

        radius: Appearance.rounding.full
        color: isPending ? Colours.palette.m3primary : isSelected ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer
        border.width: isPending || isSelected ? 0 : 1
        border.color: Colours.palette.m3outline

        StateLayer {
            color: parent.isPending ? Colours.palette.m3onPrimary : parent.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

            function onClicked(): void {
                parent.onClicked();
            }
        }

        StyledText {
            id: chipText
            anchors.centerIn: parent
            text: parent.text
            font.pointSize: Appearance.font.size.small
            color: parent.isPending ? Colours.palette.m3onPrimary : parent.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        }
    }

    component InfoRow: RowLayout {
        property string label
        property string value
        property color valueColor: Colours.palette.m3onSurface

        Layout.fillWidth: true

        StyledText {
            text: label
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: value
            font.pointSize: Appearance.font.size.small
            color: valueColor
        }
    }

    component ActionButton: StyledRect {
        property string icon
        property string label
        property string accent: "Primary"

        function onClicked(): void {}

        implicitHeight: 48

        radius: Appearance.rounding.small
        color: Colours.palette[`m3${accent.toLowerCase()}Container`]

        StateLayer {
            color: Colours.palette[`m3on${accent}Container`]

            function onClicked(): void {
                parent.onClicked();
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: parent.parent.icon
                color: Colours.palette[`m3on${parent.parent.accent}Container`]
            }

            StyledText {
                text: parent.parent.label
                color: Colours.palette[`m3on${parent.parent.accent}Container`]
            }
        }
    }

    component FabAnim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }

    // Capability row with icon and support indicator
    component CapabilityRow: RowLayout {
        property string icon
        property string label
        property string value
        property bool supported: false
        property string description: ""

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        // Status icon
        MaterialIcon {
            text: supported ? "check_circle" : "cancel"
            color: supported ? Colours.palette.m3primary : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.normal
        }

        // Label and value
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: label
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.fillWidth: true
                visible: description !== ""
                text: description
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
            }
        }

        // Value
        StyledText {
            text: value
            font.pointSize: Appearance.font.size.small
            color: supported ? Colours.palette.m3primary : Colours.palette.m3outline
        }
    }

    // Mode button for display mode selection (Mirror/Extend)
    component ModeButton: StyledRect {
        id: modeBtn

        property string icon
        property string label
        property string description: ""
        property bool isActive: false
        property string accent: "Secondary"

        function onClicked(): void {}

        implicitHeight: modeBtnContent.implicitHeight + Appearance.padding.normal * 2

        radius: Appearance.rounding.small
        color: isActive ? Colours.palette[`m3${accent.toLowerCase()}Container`] : "transparent"
        border.width: isActive ? 0 : 1
        border.color: Colours.palette.m3outlineVariant

        StateLayer {
            id: modeBtnState
            color: isActive ? Colours.palette[`m3on${accent}Container`] : Colours.palette.m3onSurface

            function onClicked(): void {
                modeBtn.onClicked();
            }
        }

        RowLayout {
            id: modeBtnContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            // Active indicator
            MaterialIcon {
                text: modeBtn.isActive ? "radio_button_checked" : "radio_button_unchecked"
                color: modeBtn.isActive ? Colours.palette[`m3on${modeBtn.accent}Container`] : Colours.palette.m3outline
            }

            // Icon
            MaterialIcon {
                text: modeBtn.icon
                color: modeBtn.isActive ? Colours.palette[`m3on${modeBtn.accent}Container`] : Colours.palette.m3onSurface
            }

            // Text
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: modeBtn.label
                    color: modeBtn.isActive ? Colours.palette[`m3on${modeBtn.accent}Container`] : Colours.palette.m3onSurface
                }

                StyledText {
                    visible: modeBtn.description !== ""
                    text: modeBtn.description
                    font.pointSize: Appearance.font.size.smaller
                    color: modeBtn.isActive ? Colours.palette[`m3on${modeBtn.accent}Container`] : Colours.palette.m3outline
                    opacity: modeBtn.isActive ? 0.8 : 1
                }
            }
        }

        Behavior on color { CAnim {} }
    }

    // Display preview illustration for mode visualization
    component DisplayPreview: Item {
        id: displayPreviewItem
        
        property bool isPrimary: false
        property string label: "1"
        property bool showContent: true
        property bool isMirrored: false
        
        // Monitor frame
        Rectangle {
            id: monitorFrame
            anchors.fill: parent
            anchors.bottomMargin: 8
            
            radius: 4
            color: Colours.palette.m3surfaceContainerHigh
            border.width: 2
            border.color: displayPreviewItem.isPrimary ? Colours.palette.m3primary : Colours.palette.m3outline
            
            // Screen content area
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 2
                color: displayPreviewItem.isPrimary ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest
                
                // Content preview (fake windows/desktop)
                Column {
                    anchors.centerIn: parent
                    spacing: 3
                    visible: displayPreviewItem.showContent
                    
                    // Fake taskbar
                    Rectangle {
                        width: parent.parent.width - 12
                        height: 4
                        radius: 1
                        color: displayPreviewItem.isPrimary ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                        opacity: 0.6
                    }
                    
                    // Fake windows
                    Row {
                        spacing: 3
                        
                        Rectangle {
                            width: 20
                            height: 15
                            radius: 2
                            color: displayPreviewItem.isPrimary ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                            opacity: 0.4
                        }
                        
                        Rectangle {
                            width: 25
                            height: 18
                            radius: 2
                            color: displayPreviewItem.isPrimary ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                            opacity: 0.3
                        }
                    }
                }
                
                // Mirror indicator overlay
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Colours.palette.m3tertiary
                    opacity: displayPreviewItem.isMirrored ? 0.2 : 0
                    
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                
                // Mirror icon overlay
                MaterialIcon {
                    anchors.centerIn: parent
                    text: "content_copy"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3tertiary
                    opacity: displayPreviewItem.isMirrored ? 0.8 : 0
                    
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
        
        // Monitor stand
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 20
            height: 8
            radius: 2
            color: displayPreviewItem.isPrimary ? Colours.palette.m3primary : Colours.palette.m3outline
            opacity: 0.6
        }
        
        // Monitor base
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 30
            height: 3
            radius: 1
            color: displayPreviewItem.isPrimary ? Colours.palette.m3primary : Colours.palette.m3outline
            opacity: 0.6
        }
        
        // Label badge
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -4
            anchors.rightMargin: -4
            
            width: 18
            height: 18
            radius: width / 2
            color: displayPreviewItem.isPrimary ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest
            border.width: displayPreviewItem.isPrimary ? 0 : 1
            border.color: Colours.palette.m3outline
            
            StyledText {
                anchors.centerIn: parent
                text: displayPreviewItem.label.charAt(0).toUpperCase()
                font.pointSize: Appearance.font.size.smaller
                font.weight: 600
                color: displayPreviewItem.isPrimary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            }
        }
    }
}
