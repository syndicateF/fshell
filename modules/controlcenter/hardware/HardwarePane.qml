pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.config
import qs.services
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent
    spacing: 0

    // Enable hardware monitoring when this pane is visible
    Component.onCompleted: Hardware.monitoringActive = true
    Component.onDestruction: Hardware.monitoringActive = false

    // Left panel - Overview/Quick Stats
    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 380
        Layout.fillHeight: true

        StyledFlickable {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

            flickableDirection: Flickable.VerticalFlick
            contentHeight: overviewLayout.height

            ColumnLayout {
                id: overviewLayout

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Appearance.spacing.normal

                // Header Row - matching Network/Bluetooth/Monitor style
                RowLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Hardware")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }

                    Item { Layout.fillWidth: true }

                    // Power Profile Toggle - cycles through modes (icon only)
                    ToggleButton {
                        visible: Hardware.hasPowerProfiles
                        toggled: Hardware.powerProfile !== "balanced"
                        icon: Hardware.powerProfile === "performance" ? "bolt" :
                              Hardware.powerProfile === "power-saver" ? "eco" : "balance"
                        accent: Hardware.powerProfile === "performance" ? "Error" :
                                Hardware.powerProfile === "power-saver" ? "Tertiary" : "Primary"

                        function onClicked(): void {
                            // Cycle: balanced -> performance -> power-saver -> balanced
                            if (Hardware.powerProfile === "balanced")
                                Hardware.setPowerProfile("performance");
                            else if (Hardware.powerProfile === "performance")
                                Hardware.setPowerProfile("power-saver");
                            else
                                Hardware.setPowerProfile("balanced");
                        }
                    }

                    // Fn Lock Toggle (on/off label only)
                    ToggleButton {
                        visible: Hardware.hasFnLock
                        toggled: Hardware.fnLock
                        icon: "keyboard"
                        label: Hardware.fnLock ? qsTr("On") : qsTr("Off")
                        accent: Hardware.fnLock ? "Primary" : "Secondary"

                        function onClicked(): void {
                            Hardware.setFnLock(!Hardware.fnLock);
                        }
                    }

                    // System Info Toggle - Settings button style (like Network/Bluetooth/Monitor)
                    ToggleButton {
                        toggled: root.session.hw.showSysInfo
                        icon: "info"
                        accent: "Primary"

                        function onClicked(): void {
                            root.session.hw.showSysInfo = !root.session.hw.showSysInfo;
                        }
                    }
                }

                // CPU Overview Card
                HardwareCard {
                    Layout.fillWidth: true
                    icon: "developer_board"
                    title: "CPU"
                    subtitle: Hardware.cpuModel
                    isSelected: root.session.hw.view === "cpu" && !root.session.hw.showSysInfo
                    onClicked: { root.session.hw.view = "cpu"; root.session.hw.showSysInfo = false; }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.large

                            StatItem {
                                label: qsTr("Temp")
                                value: Hardware.cpuTemp.toFixed(0) + "°C"
                                icon: "thermostat"
                                color: Hardware.cpuTemp > 80 ? Colours.palette.m3error : 
                                       Hardware.cpuTemp > 60 ? Colours.palette.m3tertiary : 
                                       Colours.palette.m3primary
                            }

                            StatItem {
                                label: qsTr("Usage")
                                value: Hardware.cpuUsage + "%"
                                icon: "speed"
                                color: Colours.palette.m3primary
                            }

                            StatItem {
                                label: qsTr("Freq")
                                value: (Hardware.cpuFreqCurrent / 1000).toFixed(1) + " GHz"
                                icon: "bolt"
                                color: Colours.palette.m3secondary
                            }
                        }

                        ProgressBar {
                            Layout.fillWidth: true
                            value: Hardware.cpuUsage / 100
                            barColor: Colours.palette.m3primary
                        }
                    }
                }

                // GPU Overview Card
                HardwareCard {
                    Layout.fillWidth: true
                    icon: "videogame_asset"
                    title: "GPU"
                    subtitle: Hardware.gpuModel
                    isSelected: root.session.hw.view === "gpu" && !root.session.hw.showSysInfo
                    onClicked: { root.session.hw.view = "gpu"; root.session.hw.showSysInfo = false; }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.large

                            StatItem {
                                label: qsTr("Temp")
                                value: Hardware.gpuTemp + "°C"
                                icon: "thermostat"
                                color: Hardware.gpuTemp > 80 ? Colours.palette.m3error : 
                                       Hardware.gpuTemp > 60 ? Colours.palette.m3tertiary : 
                                       Colours.palette.m3primary
                            }

                            StatItem {
                                label: qsTr("Usage")
                                value: Hardware.gpuUsage + "%"
                                icon: "speed"
                                color: Colours.palette.m3primary
                            }

                            StatItem {
                                label: qsTr("Power")
                                value: Hardware.gpuPowerDraw.toFixed(0) + "W"
                                icon: "bolt"
                                color: Colours.palette.m3secondary
                            }
                        }

                        ProgressBar {
                            Layout.fillWidth: true
                            value: Hardware.gpuUsage / 100
                            barColor: Colours.palette.m3tertiary
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Appearance.spacing.small

                            StyledText {
                                text: qsTr("VRAM")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: Hardware.gpuMemoryUsed + " / " + Hardware.gpuMemoryTotal + " MiB"
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        ProgressBar {
                            Layout.fillWidth: true
                            value: Hardware.gpuMemoryUsed / Math.max(1, Hardware.gpuMemoryTotal)
                            barColor: Colours.palette.m3secondary
                            barHeight: 6
                        }

                        // GPU Priority Switch
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Appearance.spacing.small
                            visible: Hardware.hasGpuPriority
                            spacing: Appearance.spacing.normal

                            MaterialIcon {
                                text: "swap_horiz"
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                text: qsTr("GPU Priority")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: Hardware.gpuPriority === "nvidia" ? "NVIDIA" : "Integrated"
                                font.pointSize: Appearance.font.size.small
                                font.weight: 500
                                color: Hardware.gpuPriority === "nvidia" ? Colours.palette.m3primary : Colours.palette.m3tertiary
                            }

                            StyledSwitch {
                                checked: Hardware.gpuPriority === "nvidia"
                                onClicked: Hardware.toggleGpuPriority()
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: Hardware.hasGpuPriority
                            text: qsTr("⚠ Requires logout to apply")
                            font.pointSize: Appearance.font.size.smaller
                            color: Colours.palette.m3outline
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // Battery Card
                HardwareCard {
                    Layout.fillWidth: true
                    icon: Hardware.batteryCharging ? "battery_charging_full" : 
                          Hardware.batteryPercent > 80 ? "battery_full" :
                          Hardware.batteryPercent > 50 ? "battery_3_bar" :
                          Hardware.batteryPercent > 20 ? "battery_2_bar" : "battery_alert"
                    title: qsTr("Battery")
                    subtitle: Hardware.batteryStatus
                    isSelected: root.session.hw.view === "battery" && !root.session.hw.showSysInfo
                    onClicked: { root.session.hw.view = "battery"; root.session.hw.showSysInfo = false; }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.large

                            StatItem {
                                label: qsTr("Level")
                                value: Hardware.batteryPercent + "%"
                                icon: "battery_std"
                                color: Hardware.batteryPercent < 20 ? Colours.palette.m3error : Colours.palette.m3primary
                            }

                            StatItem {
                                label: qsTr("Health")
                                value: Hardware.batteryHealth.toFixed(0) + "%"
                                icon: "favorite"
                                color: Hardware.batteryHealth > 80 ? Colours.palette.m3primary : Colours.palette.m3tertiary
                            }

                            StatItem {
                                label: qsTr("Cycles")
                                value: Hardware.batteryCycleCount.toString()
                                icon: "loop"
                                color: Colours.palette.m3secondary
                            }
                        }

                        ProgressBar {
                            Layout.fillWidth: true
                            value: Hardware.batteryPercent / 100
                            barColor: Hardware.batteryPercent < 20 ? Colours.palette.m3error :
                                   Hardware.batteryCharging ? Colours.palette.m3primary : Colours.palette.m3secondary
                        }
                    }
                }

                // GPU Mode Card
                HardwareCard {
                    Layout.fillWidth: true
                    icon: "swap_horiz"
                    title: qsTr("GPU Switching")
                    subtitle: Hardware.gpuMode === "nvidia" ? qsTr("NVIDIA Only") :
                              Hardware.gpuMode === "integrated" ? qsTr("Integrated") : qsTr("Hybrid")
                    isSelected: root.session.hw.view === "gpumode" && !root.session.hw.showSysInfo
                    onClicked: { root.session.hw.view = "gpumode"; root.session.hw.showSysInfo = false; }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: Hardware.currentRenderGpu || qsTr("Unknown render GPU")
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideMiddle
                        }

                        StyledText {
                            visible: Hardware.gpuProcesses.length > 0
                            text: qsTr("%1 process(es) using GPU").arg(Hardware.gpuProcesses.length)
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3primary
                        }
                    }
                }

                // RGB Keyboard Card
                HardwareCard {
                    Layout.fillWidth: true
                    icon: "keyboard"
                    title: qsTr("RGB Keyboard")
                    subtitle: Hardware.rgbCurrentMode.charAt(0).toUpperCase() + 
                              Hardware.rgbCurrentMode.slice(1).replace(/_/g, " ")
                    isSelected: root.session.hw.view === "rgb" && !root.session.hw.showSysInfo
                    onClicked: { root.session.hw.view = "rgb"; root.session.hw.showSysInfo = false; }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        Row {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            spacing: 2

                            Repeater {
                                model: Hardware.rgbColors

                                Rectangle {
                                    required property string modelData
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: modelData || "#333333"
                                }
                            }
                        }

                        StyledText {
                            text: {
                                const name = Hardware.rgbDeviceName || qsTr("Legion 4-Zone RGB");
                                const words = name.split(" ");
                                return words.length >= 3 ? words.slice(0, 3).join(" ") : name;
                            }
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: parent.width
                        }
                    }
                }

                // Quick Profiles Card
                HardwareCard {
                    Layout.fillWidth: true
                    icon: "tune"
                    title: qsTr("Quick Profiles")
                    subtitle: qsTr("One-click optimization")
                    isSelected: root.session.hw.view === "profiles" && !root.session.hw.showSysInfo
                    onClicked: { root.session.hw.view = "profiles"; root.session.hw.showSysInfo = false; }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        Repeater {
                            model: Hardware.appProfiles.slice(0, 4)

                            StyledRect {
                                required property var modelData
                                implicitWidth: profileLabel.implicitWidth + Appearance.padding.small * 2
                                implicitHeight: profileLabel.implicitHeight + 4
                                radius: Appearance.rounding.small
                                color: Colours.palette.m3surfaceContainerHighest

                                StyledText {
                                    id: profileLabel
                                    anchors.centerIn: parent
                                    text: modelData.icon + " " + modelData.name
                                    font.pointSize: Appearance.font.size.small
                                }
                            }
                        }
                    }
                }
            }
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    // Right panel - Details
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2
            radius: rightBorder.innerRadius
            color: "transparent"

            // Horizontal sliding panes - like Network/Bluetooth/Monitor
            Item {
                id: horizontalPanes
                
                anchors.fill: parent
                clip: true
                
                // 0 = Normal Views, 1 = SysInfo
                property int activePane: root.session.hw.showSysInfo ? 1 : 0
                
                RowLayout {
                    id: paneRow
                    
                    spacing: 0
                    x: -horizontalPanes.activePane * horizontalPanes.width
                    
                    Behavior on x {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                    
                    // Pane 0: Normal hardware views (CPU, GPU, Battery, etc.)
                    Item {
                        Layout.preferredWidth: horizontalPanes.width
                        Layout.preferredHeight: horizontalPanes.height

                        Item {
                            id: viewSwitcher
                            anchors.fill: parent
                            clip: true
                            
                            property int activeView: {
                                switch (root.session.hw.view) {
                                    case "gpu": return 1;
                                    case "battery": return 2;
                                    case "gpumode": return 3;
                                    case "profiles": return 4;
                                    case "rgb": return 5;
                                    default: return 0;
                                }
                            }
                            
                            RowLayout {
                                spacing: 0
                                x: -viewSwitcher.activeView * viewSwitcher.width
                                
                                Behavior on x {
                                    NumberAnimation {
                                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                                    }
                                }

                                SettingsPane {
                                    active: viewSwitcher.activeView === 0 && !root.session.hw.showSysInfo
                                    sourceComponent: Component { CpuSettings { session: root.session } }
                                }
                                
                                SettingsPane {
                                    active: viewSwitcher.activeView === 1 && !root.session.hw.showSysInfo
                                    sourceComponent: Component { GpuSettings { session: root.session } }
                                }
                                
                                SettingsPane {
                                    active: viewSwitcher.activeView === 2 && !root.session.hw.showSysInfo
                                    sourceComponent: Component { BatterySettings { session: root.session } }
                                }
                                
                                SettingsPane {
                                    active: viewSwitcher.activeView === 3 && !root.session.hw.showSysInfo
                                    sourceComponent: Component { GpuModeSettings { session: root.session } }
                                }
                                
                                SettingsPane {
                                    active: viewSwitcher.activeView === 4 && !root.session.hw.showSysInfo
                                    sourceComponent: Component { ProfilesSettings { session: root.session } }
                                }
                                
                                SettingsPane {
                                    active: viewSwitcher.activeView === 5 && !root.session.hw.showSysInfo
                                    sourceComponent: Component { RgbSettings { session: root.session } }
                                }
                            }
                        }
                    }
                    
                    // Pane 1: System Info (Vulkan/VA-API)
                    Item {
                        Layout.preferredWidth: horizontalPanes.width
                        Layout.preferredHeight: horizontalPanes.height
                        
                        Loader {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            active: root.session.hw.showSysInfo
                            
                            sourceComponent: Component { SysInfoSettings { session: root.session } }
                        }
                    }
                }
            }
        }

        InnerBorder {
            id: rightBorder
            leftThickness: Appearance.padding.normal / 2
        }
    }

    // =====================================================
    // COMPONENTS
    // =====================================================

    component SettingsPane: Item {
        property alias active: loader.active
        property alias sourceComponent: loader.sourceComponent
        
        Layout.preferredWidth: viewSwitcher.width
        Layout.preferredHeight: viewSwitcher.height
        
        Loader {
            id: loader
            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 2
        }
    }

    component ProgressBar: Item {
        property real value: 0
        property color barColor: Colours.palette.m3primary
        property int barHeight: 8
        
        Layout.fillWidth: true
        Layout.preferredHeight: barHeight
        Layout.topMargin: Appearance.spacing.small

        Rectangle {
            anchors.fill: parent
            radius: parent.barHeight / 2
            color: Colours.palette.m3surfaceContainerHighest
        }

        Rectangle {
            width: parent.width * Math.min(1, Math.max(0, parent.value))
            height: parent.barHeight
            radius: height / 2
            color: parent.barColor

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }

    component HardwareCard: StyledRect {
        id: cardRoot

        required property string icon
        required property string title
        required property string subtitle
        property bool isSelected: false
        default property alias content: contentLayout.children

        signal clicked()

        implicitHeight: cardLayout.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.normal
        color: isSelected ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer

        // Hover
        StateLayer {
            radius: cardRoot.radius
            color: Colours.palette.m3onSurface
            onClicked: cardRoot.clicked()
        }

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                // Bg icon
                StyledRect {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: Appearance.rounding.small
                    color: cardRoot.isSelected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHighest

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: cardRoot.icon
                        color: cardRoot.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: cardRoot.title
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 600
                        color: Colours.palette.m3onSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: cardRoot.subtitle
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            ColumnLayout {
                id: contentLayout
                Layout.fillWidth: true
                spacing: Appearance.spacing.small
            }
        }
    }

    component StatItem: ColumnLayout {
        required property string label
        required property string value
        required property string icon
        property color color: Colours.palette.m3primary

        spacing: 2

        RowLayout {
            spacing: 4

            MaterialIcon {
                text: parent.parent.icon
                font.pointSize: Appearance.font.size.small
                color: parent.parent.color
            }

            StyledText {
                text: parent.parent.value
                font.pointSize: Appearance.font.size.normal
                font.weight: 600
                color: parent.parent.color
            }
        }

        StyledText {
            text: label
            font.pointSize: Appearance.font.size.smaller
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // ToggleButton - matching style from Network/Bluetooth/Monitor
    component ToggleButton: StyledRect {
        id: toggleBtn

        required property bool toggled
        property string icon
        property string label: ""
        property string accent: "Secondary"

        function onClicked(): void {}

        Layout.preferredWidth: implicitWidth + (toggleStateLayer.pressed ? Appearance.padding.normal * 2 : toggled ? Appearance.padding.small * 2 : 0)
        implicitWidth: toggleBtnInner.implicitWidth + Appearance.padding.large * 2
        implicitHeight: toggleBtnIcon.implicitHeight + Appearance.padding.normal * 2

        radius: toggled || toggleStateLayer.pressed ? Appearance.rounding.small : Math.min(width, height) / 2 * Math.min(1, Appearance.rounding.scale)
        color: toggled ? Colours.palette[`m3${accent.toLowerCase()}`] : Colours.palette[`m3${accent.toLowerCase()}Container`]

        StateLayer {
            id: toggleStateLayer

            color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]

            function onClicked(): void {
                toggleBtn.onClicked();
            }
        }

        RowLayout {
            id: toggleBtnInner

            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            MaterialIcon {
                id: toggleBtnIcon

                visible: !!text
                fill: toggleBtn.toggled ? 1 : 0
                text: toggleBtn.icon
                color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
                font.pointSize: Appearance.font.size.large

                Behavior on fill {
                    Anim {}
                }
            }

            Loader {
                asynchronous: true
                active: !!toggleBtn.label
                visible: active

                sourceComponent: StyledText {
                    text: toggleBtn.label
                    color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
                }
            }
        }

        Behavior on radius {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }
}
