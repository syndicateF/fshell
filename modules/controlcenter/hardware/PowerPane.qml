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

    // Power data is managed by singleton service (no refresh needed here)

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

                    // Charge Type Selection (Dynamic)
                    GridLayout {
                        Layout.fillWidth: true
                        visible: Power.chargeTypeWritable && Power.availableChargeTypes.length > 0
                        columns: 2
                        rowSpacing: Appearance.spacing.smaller
                        columnSpacing: Appearance.spacing.smaller

                        Repeater {
                            model: Power.availableChargeTypes

                            ChargeTypeButton {
                                required property string modelData
                                required property int index

                                value: modelData
                                isActive: Power.chargeType === modelData
                                enabled: !Power._busy && !Power.safeModeActive

                                onClicked: Power.setChargeType(modelData)
                            }
                        }
                    }
                }
            }

            // ==================== Power Source & Temperature ====================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Power Status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available && Power.acAdapterAvailable
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: powerStatusCol.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Power.powerSource === "ac" ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
                visible: Power.available && Power.acAdapterAvailable

                ColumnLayout {
                    id: powerStatusCol
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Source row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: Power.powerSource === "ac" ? "power" : "battery_std"
                            color: Power.powerSource === "ac" ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.large
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: Power.powerSource === "ac" ? qsTr("AC Power") : qsTr("Battery")
                                font.weight: 500
                                color: Power.powerSource === "ac" ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            }

                            StyledText {
                                text: {
                                    let s = Power.batteryCapacity + "%";
                                    if (Power.batteryStatus !== "Unknown") s += " · " + Power.batteryStatus;
                                    return s;
                                }
                                font.pointSize: Appearance.font.size.small
                                color: Power.powerSource === "ac" ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                            }
                        }
                    }

                    // Temperature row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.large
                        visible: Power.cpuTempAvailable || Power.gpuTempAvailable

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Colours.palette.m3outlineVariant
                            opacity: 0.5
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.large
                        visible: Power.cpuTempAvailable || Power.gpuTempAvailable

                        // CPU Temp
                        RowLayout {
                            visible: Power.cpuTempAvailable
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "memory"
                                font.pointSize: Appearance.font.size.small
                                color: Power.cpuTemp > 80 ? Colours.palette.m3error : Colours.palette.m3outline
                            }

                            StyledText {
                                text: qsTr("CPU")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outline
                            }

                            StyledText {
                                text: Power.cpuTemp >= 0 ? Power.cpuTemp.toFixed(1) + "°C" : "--"
                                font.pointSize: Appearance.font.size.small
                                font.weight: 500
                                color: Power.cpuTemp > 80 ? Colours.palette.m3error : Colours.palette.m3onSurface
                            }
                        }

                        // GPU Temp
                        RowLayout {
                            visible: Power.gpuTempAvailable
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "gpu_alert"
                                font.pointSize: Appearance.font.size.small
                                color: Power.gpuTemp > 85 ? Colours.palette.m3error : Colours.palette.m3outline
                            }

                            StyledText {
                                text: qsTr("GPU")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outline
                            }

                            StyledText {
                                text: Power.gpuTemp >= 0 ? Power.gpuTemp.toFixed(1) + "°C" : "--"
                                font.pointSize: Appearance.font.size.small
                                font.weight: 500
                                color: Power.gpuTemp > 85 ? Colours.palette.m3error : Colours.palette.m3onSurface
                            }
                        }
                    }
                }
            }

            // ==================== Auto AC/Battery Switch ====================
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.large
                implicitHeight: autoSwitchRow.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available && Power.acAdapterAvailable

                RowLayout {
                    id: autoSwitchRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "swap_horiz"
                        color: Power.autoSwitchEnabled ? Colours.palette.m3primary : Colours.palette.m3outline
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: qsTr("Auto Profile Switch")
                            font.weight: 500
                        }

                        StyledText {
                            text: qsTr("Switch profiles when plugging/unplugging charger")
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    StyledSwitch {
                        checked: Power.autoSwitchEnabled
                        onClicked: Power.setAutoSwitch(!Power.autoSwitchEnabled)
                    }
                }
            }

            // AC/Battery Profile Configuration (visible when auto-switch enabled)
            StyledRect {
                id: autoSwitchConfig
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small
                implicitHeight: presetConfigCol.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available && Power.acAdapterAvailable && Power.autoSwitchEnabled

                ColumnLayout {
                    id: presetConfigCol
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // ---- AC Section ----
                    RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: "power"
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: qsTr("When Charging (AC)")
                            font.pointSize: Appearance.font.size.small
                            font.weight: 500
                            color: Colours.palette.m3primary
                        }
                    }

                    // AC: Platform Profile
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller
                        visible: Power.availableProfiles.length > 0

                        Repeater {
                            model: Power.availableProfiles.filter(p => p !== "custom")

                            MiniSelectButton {
                                required property string modelData
                                label: modelData.charAt(0).toUpperCase() + modelData.slice(1).replace("-", " ")
                                current: Power.acPresetProfile === modelData
                                onClicked: Power.setAcProfile(modelData, Power.acPresetGovernor, Power.acPresetEpp, Power.acPresetBoost, Power.acPresetGpu)
                            }
                        }
                    }

                    // AC: Governor
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller
                        visible: Power.availableGovernors.length > 1

                        Repeater {
                            model: Power.availableGovernors

                            MiniSelectButton {
                                required property string modelData
                                label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                current: Power.acPresetGovernor === modelData
                                onClicked: Power.setAcProfile(Power.acPresetProfile, modelData, Power.acPresetEpp, Power.acPresetBoost, Power.acPresetGpu)
                            }
                        }
                    }

                    // AC: EPP
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller
                        visible: Power.eppAvailable && Power.availableEpp.length > 0

                        Repeater {
                            model: Power.availableEpp

                            MiniSelectButton {
                                required property string modelData
                                label: modelData.replace(/_/g, " ")
                                current: Power.acPresetEpp === modelData
                                onClicked: Power.setAcProfile(Power.acPresetProfile, Power.acPresetGovernor, modelData, Power.acPresetBoost, Power.acPresetGpu)
                            }
                        }
                    }

                    // AC: Boost toggle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("CPU Boost")
                            font.pointSize: Appearance.font.size.small
                            Layout.fillWidth: true
                        }

                        StyledSwitch {
                            checked: Power.acPresetBoost
                            onClicked: Power.setAcProfile(Power.acPresetProfile, Power.acPresetGovernor, Power.acPresetEpp, !Power.acPresetBoost, Power.acPresetGpu)
                        }
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

                    // ---- Battery Section ----
                    RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: "battery_std"
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3outline
                        }

                        StyledText {
                            text: qsTr("When on Battery")
                            font.pointSize: Appearance.font.size.small
                            font.weight: 500
                            color: Colours.palette.m3outline
                        }
                    }

                    // Battery: Platform Profile
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller
                        visible: Power.availableProfiles.length > 0

                        Repeater {
                            model: Power.availableProfiles.filter(p => p !== "custom")

                            MiniSelectButton {
                                required property string modelData
                                label: modelData.charAt(0).toUpperCase() + modelData.slice(1).replace("-", " ")
                                current: Power.batteryPresetProfile === modelData
                                onClicked: Power.setBatteryProfile(modelData, Power.batteryPresetGovernor, Power.batteryPresetEpp, Power.batteryPresetBoost, Power.batteryPresetGpu)
                            }
                        }
                    }

                    // Battery: Governor
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller
                        visible: Power.availableGovernors.length > 1

                        Repeater {
                            model: Power.availableGovernors

                            MiniSelectButton {
                                required property string modelData
                                label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                current: Power.batteryPresetGovernor === modelData
                                onClicked: Power.setBatteryProfile(Power.batteryPresetProfile, modelData, Power.batteryPresetEpp, Power.batteryPresetBoost, Power.batteryPresetGpu)
                            }
                        }
                    }

                    // Battery: EPP
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller
                        visible: Power.eppAvailable && Power.availableEpp.length > 0

                        Repeater {
                            model: Power.availableEpp

                            MiniSelectButton {
                                required property string modelData
                                label: modelData.replace(/_/g, " ")
                                current: Power.batteryPresetEpp === modelData
                                onClicked: Power.setBatteryProfile(Power.batteryPresetProfile, Power.batteryPresetGovernor, modelData, Power.batteryPresetBoost, Power.batteryPresetGpu)
                            }
                        }
                    }

                    // Battery: Boost toggle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("CPU Boost")
                            font.pointSize: Appearance.font.size.small
                            Layout.fillWidth: true
                        }

                        StyledSwitch {
                            checked: Power.batteryPresetBoost
                            onClicked: Power.setBatteryProfile(Power.batteryPresetProfile, Power.batteryPresetGovernor, Power.batteryPresetEpp, !Power.batteryPresetBoost, Power.batteryPresetGpu)
                        }
                    }
                }
            }

            // ==================== Lenovo Features ====================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Lenovo Features")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available && (Power.fanModeAvailable || Power.cameraPowerAvailable || Power.usbChargingAvailable || Power.fnLockAvailable)
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: lenovoCol.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available && (Power.fanModeAvailable || Power.cameraPowerAvailable || Power.usbChargingAvailable || Power.fnLockAvailable)

                ColumnLayout {
                    id: lenovoCol
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Fan Mode (special: multi-value selector)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small
                        visible: Power.fanModeAvailable

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            MaterialIcon {
                                text: "air"
                                color: Power.fanMode > 0 ? Colours.palette.m3primary : Colours.palette.m3outline
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Fan Mode")
                                font.weight: 500
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.smaller

                            FanModeButton {
                                mode: 0
                                label: qsTr("Auto")
                                icon: "hdr_auto"
                                current: Power.fanMode === 0
                                onClicked: Power.setFanMode(0)
                            }

                            FanModeButton {
                                mode: 1
                                label: qsTr("Max")
                                icon: "speed"
                                current: Power.fanMode === 1
                                onClicked: Power.setFanMode(1)
                            }

                            FanModeButton {
                                mode: 4
                                label: qsTr("Dust")
                                icon: "cleaning_services"
                                current: Power.fanMode === 4
                                onClicked: Power.setFanMode(4)
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.5
                        visible: Power.fanModeAvailable && (Power.cameraPowerAvailable || Power.usbChargingAvailable || Power.fnLockAvailable)
                    }

                    // Camera Power
                    ToggleRow {
                        visible: Power.cameraPowerAvailable
                        icon: Power.cameraPower ? "videocam" : "videocam_off"
                        label: qsTr("Camera")
                        subtitle: Power.cameraPower ? qsTr("Enabled") : qsTr("Disabled")
                        checked: Power.cameraPower
                        onToggled: Power.setCameraPower(!Power.cameraPower)
                    }

                    // USB Charging
                    ToggleRow {
                        visible: Power.usbChargingAvailable
                        icon: "usb"
                        label: qsTr("Always-on USB Charging")
                        subtitle: Power.usbCharging ? qsTr("Charge devices when laptop is off") : qsTr("Disabled")
                        checked: Power.usbCharging
                        onToggled: Power.setUsbCharging(!Power.usbCharging)
                    }

                    // Fn Lock
                    ToggleRow {
                        visible: Power.fnLockAvailable
                        icon: "keyboard"
                        label: qsTr("Fn Lock")
                        subtitle: Power.fnLock ? qsTr("Function keys primary") : qsTr("Media keys primary")
                        checked: Power.fnLock
                        onToggled: Power.setFnLock(!Power.fnLock)
                    }
                }
            }

            // ==================== Platform Profile Section ====================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Platform Profile")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available && Power.availableProfiles && Power.availableProfiles.length > 0
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: profileColumn.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available && Power.availableProfiles && Power.availableProfiles.length > 0

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

            // EPP Section - COMPLETELY HIDDEN if EPP not available (passive pstate mode)
            // Dimmed if controllable but governor is performance
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Energy Performance") + (!Power.eppControllable ? qsTr(" (bypassed in performance mode)") : "")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
                visible: Power.available && Power.eppAvailable && Power.eppControllable
                opacity: Power.eppControllable ? 1 : 0.5
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: eppColumn.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer
                visible: Power.available && Power.eppAvailable && Power.eppControllable
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

    // Reusable toggle row for Lenovo features
    component ToggleRow: RowLayout {
        property string icon
        property string label
        property string subtitle
        property bool checked
        signal toggled()

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: icon
            color: checked ? Colours.palette.m3primary : Colours.palette.m3outline
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: label
                font.weight: 500
            }

            StyledText {
                text: subtitle
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }
        }

        StyledSwitch {
            checked: parent.checked
            onClicked: parent.toggled()
            enabled: !Power._busy && !Power.safeModeActive
        }
    }

    // Fan mode button
    component FanModeButton: StyledRect {
        id: fmBtn

        required property int mode
        required property string label
        required property string icon
        property bool current: false

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 36
        radius: Appearance.rounding.small
        color: current ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh

        StateLayer {
            color: fmBtn.current ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            disabled: !fmBtn.enabled
            function onClicked(): void {
                fmBtn.clicked();
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                text: fmBtn.icon
                font.pointSize: Appearance.font.size.smaller
                color: fmBtn.current ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                fill: fmBtn.current ? 1 : 0
            }

            StyledText {
                text: fmBtn.label
                font.pointSize: Appearance.font.size.smaller
                color: fmBtn.current ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
            }
        }
    }

    // Generic mini select button for per-setting selectors (no business logic)
    component MiniSelectButton: StyledRect {
        id: msBtn

        required property string label
        property bool current: false

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 30
        radius: Appearance.rounding.small
        color: current ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainerHigh

        StateLayer {
            color: msBtn.current ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
            disabled: !msBtn.enabled
            function onClicked(): void {
                msBtn.clicked();
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: msBtn.label
            font.pointSize: Appearance.font.size.smaller
            color: msBtn.current ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
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

    // Charge Type Button (Dynamic)
    component ChargeTypeButton: StyledRect {
        id: ctBtn

        required property string value
        property bool isActive: false

        signal clicked()

        readonly property string displayText: {
            let s = value.replace(/_/g, " ");
            return s.charAt(0).toUpperCase() + s.slice(1);
        }

        readonly property string icon: {
            const v = value.toLowerCase();
            if (v.includes("standard") || v.includes("normal")) return "battery_full";
            if (v.includes("long") || v.includes("life") || v.includes("saver") || v.includes("conservation")) return "battery_saver";
            if (v.includes("express") || v.includes("rapid") || v.includes("fast")) return "bolt";
            return "battery_std";
        }

        Layout.fillWidth: true
        implicitHeight: 36
        radius: Appearance.rounding.small
        color: isActive 
            ? Colours.palette.m3tertiaryContainer 
            : Colours.palette.m3surfaceContainerHigh

        StateLayer {
            color: ctBtn.isActive 
                ? Colours.palette.m3onTertiaryContainer 
                : Colours.palette.m3onSurface
            disabled: !ctBtn.enabled

            function onClicked(): void {
                ctBtn.clicked();
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                text: ctBtn.icon
                font.pointSize: Appearance.font.size.smaller
                color: ctBtn.isActive 
                    ? Colours.palette.m3onTertiaryContainer 
                    : Colours.palette.m3onSurfaceVariant
                fill: ctBtn.isActive ? 1 : 0
            }

            StyledText {
                text: ctBtn.displayText
                font.pointSize: Appearance.font.size.smaller
                color: ctBtn.isActive 
                    ? Colours.palette.m3onTertiaryContainer 
                    : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
