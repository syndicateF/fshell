pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Power Pane - Control Center pane for power management
Item {
    id: root

    required property Session session

    // Refresh power data when pane is created (Clean Architecture)
    Component.onCompleted: Power.refresh()

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

            // Header
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "electric_bolt"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Power Management")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Power.available ? qsTr("Control power profiles and CPU settings") : qsTr("x-power-daemon not available")
                color: Colours.palette.m3outline
            }

            // Status indicator
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                implicitHeight: statusRow.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Power.available ? Colours.palette.m3primaryContainer : Colours.palette.m3errorContainer

                RowLayout {
                    id: statusRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: Power.available ? "check_circle" : "error"
                        color: Power.available ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onErrorContainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Power.available ? qsTr("Power daemon connected") : qsTr("Daemon not running")
                        color: Power.available ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onErrorContainer
                    }
                }
            }

            // Safe Mode Warning
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small
                implicitHeight: safeModeRow.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.palette.m3errorContainer
                visible: Power.safeModeActive

                RowLayout {
                    id: safeModeRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "warning"
                        color: Colours.palette.m3onErrorContainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Safe mode active - writes disabled after repeated failures")
                        color: Colours.palette.m3onErrorContainer
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Last Error Banner
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small
                implicitHeight: errorRow.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.small
                color: Qt.alpha(Colours.palette.m3error, 0.15)
                visible: Power.lastError !== "" && !Power.safeModeActive

                RowLayout {
                    id: errorRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "error_outline"
                        color: Colours.palette.m3error
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Power.lastError
                        color: Colours.palette.m3error
                        font.pointSize: Appearance.font.size.small
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // ==================== Battery Section ====================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Battery")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available && Power.batteryAvailable
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: batteryColumn.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available && Power.batteryAvailable

                ColumnLayout {
                    id: batteryColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Health row
                    BatteryInfoRow {
                        label: qsTr("Health")
                        value: Power.batteryInfo.healthPercent >= 0 
                            ? Math.round(Power.batteryInfo.healthPercent) + "%" 
                            : "--"
                        icon: "favorite"
                        highlight: Power.batteryInfo.healthPercent > 80
                    }

                    // Cycles row
                    BatteryInfoRow {
                        label: qsTr("Cycles")
                        value: Power.batteryInfo.cycleCount >= 0 
                            ? Power.batteryInfo.cycleCount.toString() 
                            : "--"
                        icon: "autorenew"
                    }

                    // Manufacturer row
                    BatteryInfoRow {
                        label: qsTr("Manufacturer")
                        value: Power.batteryInfo.manufacturer || "--"
                        icon: "factory"
                    }

                    // Model row
                    BatteryInfoRow {
                        label: qsTr("Model")
                        value: Power.batteryInfo.model || "--"
                        icon: "memory"
                    }

                    // Technology row
                    BatteryInfoRow {
                        label: qsTr("Technology")
                        value: Power.batteryInfo.technology || "--"
                        icon: "science"
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.small
                        Layout.bottomMargin: Appearance.spacing.small
                        height: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.5
                    }

                    // Long Life Mode Toggle
                    RowLayout {
                        Layout.fillWidth: true
                        visible: Power.chargeTypeWritable
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: Power.chargeType === "Long_Life" ? "battery_saver" : "battery_full"
                            color: Power.chargeType === "Long_Life" ? Colours.palette.m3primary : Colours.palette.m3outline
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: qsTr("Long Life Mode")
                                font.weight: 500
                            }

                            StyledText {
                                text: Power.chargeType === "Long_Life" 
                                    ? qsTr("Enabled - Limits charge to ~80%") 
                                    : qsTr("Disabled - Full charge capacity")
                                color: Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.small
                            }
                        }

                        StyledSwitch {
                            checked: Power.chargeType === "Long_Life"
                            onClicked: Power.setChargeType(checked ? "Long_Life" : "Standard")
                            enabled: !Power._busy && !Power.safeModeActive
                        }
                    }
                }
            }

            // ==================== Platform Profile Section ====================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Platform Profile")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: profileColumn.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available

                ColumnLayout {
                    id: profileColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Custom mode indicator (read-only, when active)
                    StyledRect {
                        Layout.fillWidth: true
                        visible: Power.platformProfile === "custom"
                        implicitHeight: customLabel.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3tertiaryContainer

                        RowLayout {
                            id: customLabel
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "tune"
                                color: Colours.palette.m3onTertiaryContainer
                                font.pointSize: Appearance.font.size.normal
                            }

                            StyledText {
                                text: qsTr("Custom (modified by firmware/tools)")
                                color: Colours.palette.m3onTertiaryContainer
                                font.pointSize: Appearance.font.size.small
                            }
                        }
                    }

                    // Preset buttons (exclude "custom" - it's a status, not action)
                    Repeater {
                        model: Power.availableProfiles.filter(p => p !== "custom")

                        ProfileButton {
                            required property string modelData
                            profile: modelData
                            current: Power.platformProfile === modelData
                            onClicked: Power.setPlatformProfile(modelData)
                            enabled: !Power._busy && !Power.safeModeActive
                        }
                    }
                }
            }

            // Governor Section (only if more than 1 available)
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("CPU Governor")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available && Power.availableGovernors.length > 1
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: governorColumn.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available && Power.availableGovernors.length > 1

                ColumnLayout {
                    id: governorColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: qsTr("powersave = dynamic EPP control, performance = max perf")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: Power.availableGovernors

                        GovernorButton {
                            required property string modelData
                            governor: modelData
                            current: Power.cpuGovernor === modelData
                            onClicked: Power.setGovernor(modelData)
                            enabled: !Power._busy && !Power.safeModeActive
                        }
                    }
                }
            }

            // EPP Section (dimmed if governor is performance)
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Energy Performance") + (!Power.eppControllable ? qsTr(" (bypassed in performance mode)") : "")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available
                opacity: Power.eppControllable ? 1 : 0.5
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: eppColumn.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available
                opacity: Power.eppControllable ? 1 : 0.5

                ColumnLayout {
                    id: eppColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    Repeater {
                        model: Power.availableEpp

                        EppButton {
                            required property string modelData
                            epp: modelData
                            current: Power.epp === modelData
                            onClicked: Power.setEpp(modelData)
                            enabled: Power.eppControllable && !Power._busy && !Power.safeModeActive
                        }
                    }
                }
            }

            // CPU Boost Toggle
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.large
                implicitHeight: boostRow.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available

                RowLayout {
                    id: boostRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: Power.cpuBoostEnabled ? "speed" : "speed"
                        color: Power.cpuBoostEnabled ? Colours.palette.m3primary : Colours.palette.m3outline
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: qsTr("CPU Boost")
                            font.weight: 500
                        }

                        StyledText {
                            text: Power.cpuBoostEnabled ? qsTr("Enabled - Maximum performance") : qsTr("Disabled - Power saving")
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                        }
                    }

                    StyledSwitch {
                        checked: Power.cpuBoostEnabled
                        onClicked: Power.setCpuBoost(!Power.cpuBoostEnabled)
                        enabled: !Power._busy && !Power.safeModeActive
                    }
                }
            }

            // AMD GPU Profile Section (only if available)
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("AMD GPU Power Profile")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available && Power.amdGpuAvailable
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: gpuColumn.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available && Power.amdGpuAvailable

                ColumnLayout {
                    id: gpuColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Auto mode button (ID 0 = driver managed)
                    GpuButton {
                        gpuId: 0
                        gpuName: qsTr("Auto (Driver Managed)")
                        current: Power.amdGpuProfile === 0
                        onClicked: Power.setAmdGpuProfile(0)
                        enabled: !Power._busy && !Power.safeModeActive
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.small
                        Layout.bottomMargin: Appearance.spacing.small
                        height: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.5
                    }

                    // Dynamic profiles from hardware
                    Repeater {
                        model: Power.availableGpuProfiles

                        GpuButton {
                            required property var modelData
                            gpuId: modelData.id
                            gpuName: modelData.name
                            current: Power.amdGpuProfile === modelData.id
                            onClicked: Power.setAmdGpuProfile(modelData.id)
                            enabled: !Power._busy && !Power.safeModeActive
                        }
                    }
                }
            }

            // Bottom padding
            Item {
                Layout.preferredHeight: Appearance.spacing.large
            }
        }
    }

    // Profile button component
    component ProfileButton: Item {
        property string profile
        property bool current
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: profileBtnRow.implicitHeight + Appearance.padding.normal * 2

        StateLayer {
            radius: Appearance.rounding.small
            function onClicked(): void {
                parent.clicked();
            }
        }

        RowLayout {
            id: profileBtnRow
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: profile === "performance" ? "bolt" : 
                      profile === "balanced" ? "balance" : 
                      profile === "low-power" ? "eco" : "settings"
                color: current ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                text: profile.charAt(0).toUpperCase() + profile.slice(1).replace("-", " ")
                font.weight: current ? 600 : 400
                color: current ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            MaterialIcon {
                text: "check"
                visible: current
                color: Colours.palette.m3primary
            }
        }
    }

    // EPP button component
    component EppButton: Item {
        property string epp
        property bool current
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: eppBtnRow.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            radius: Appearance.rounding.small
            function onClicked(): void {
                parent.clicked();
            }
        }

        RowLayout {
            id: eppBtnRow
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: epp.replace("_", " ")
                font.pointSize: Appearance.font.size.small
                font.weight: current ? 600 : 400
                color: current ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            MaterialIcon {
                text: "check"
                visible: current
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3primary
            }
        }
    }

    // Governor button component
    component GovernorButton: Item {
        property string governor
        property bool current
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: govBtnRow.implicitHeight + Appearance.padding.normal * 2

        StateLayer {
            radius: Appearance.rounding.small
            function onClicked(): void {
                parent.clicked();
            }
        }

        RowLayout {
            id: govBtnRow
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: governor === "performance" ? "speed" : "eco"
                color: current ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                text: governor.charAt(0).toUpperCase() + governor.slice(1)
                font.weight: current ? 600 : 400
                color: current ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            MaterialIcon {
                text: "check"
                visible: current
                color: Colours.palette.m3primary
            }
        }
    }

    // GPU button component
    component GpuButton: Item {
        property int gpuId
        property string gpuName
        property bool current
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: gpuBtnRow.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            radius: Appearance.rounding.small
            function onClicked(): void {
                parent.clicked();
            }
        }

        RowLayout {
            id: gpuBtnRow
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: gpuName
                font.pointSize: Appearance.font.size.small
                font.weight: current ? 600 : 400
                color: current ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            MaterialIcon {
                text: "check"
                visible: current
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3primary
            }
        }
    }

    // Battery info row component
    component BatteryInfoRow: RowLayout {
        property string label
        property string value
        property string icon
        property bool highlight: false

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: icon
            color: highlight ? Colours.palette.m3primary : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.small
        }

        StyledText {
            text: label
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.small
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: value
            font.weight: 500
            color: highlight ? Colours.palette.m3primary : Colours.palette.m3onSurface
        }
    }
}
