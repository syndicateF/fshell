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

                // Header
                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "memory"
                    font.pointSize: Appearance.font.size.extraLarge * 2.5
                    font.bold: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Hardware")
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                }

                // CPU Overview Card
                HardwareCard {
                    Layout.fillWidth: true

                    icon: "developer_board"
                    title: "CPU"
                    subtitle: Hardware.cpuModel
                    isActive: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        // Temperature & Usage
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

                        // Usage bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            Layout.topMargin: Appearance.spacing.small

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Colours.palette.m3surfaceContainerHighest
                            }

                            Rectangle {
                                width: parent.width * (Hardware.cpuUsage / 100)
                                height: parent.height
                                radius: height / 2
                                color: Colours.palette.m3primary

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }

                    onClicked: {
                        root.session.hw.view = "cpu";
                    }
                }

                // GPU Overview Card (NVIDIA)
                HardwareCard {
                    Layout.fillWidth: true
                    visible: Hardware.hasNvidiaGpu

                    icon: "videogame_asset"
                    title: "GPU"
                    subtitle: Hardware.gpuModel
                    isActive: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        // Temperature & Usage & Power
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

                        // GPU Usage bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            Layout.topMargin: Appearance.spacing.small

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Colours.palette.m3surfaceContainerHighest
                            }

                            Rectangle {
                                width: parent.width * (Hardware.gpuUsage / 100)
                                height: parent.height
                                radius: height / 2
                                color: Colours.palette.m3tertiary

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        // VRAM Usage
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
                                text: `${Hardware.gpuMemoryUsed} / ${Hardware.gpuMemoryTotal} MiB`
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Colours.palette.m3surfaceContainerHighest
                            }

                            Rectangle {
                                width: parent.width * (Hardware.gpuMemoryUsed / Math.max(1, Hardware.gpuMemoryTotal))
                                height: parent.height
                                radius: height / 2
                                color: Colours.palette.m3secondary

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }

                    onClicked: {
                        root.session.hw.view = "gpu";
                    }
                }

                // Battery Card
                HardwareCard {
                    Layout.fillWidth: true
                    visible: Hardware.hasBattery

                    icon: Hardware.batteryCharging ? "battery_charging_full" : 
                          Hardware.batteryPercent > 80 ? "battery_full" :
                          Hardware.batteryPercent > 50 ? "battery_3_bar" :
                          Hardware.batteryPercent > 20 ? "battery_2_bar" : "battery_alert"
                    title: qsTr("Battery")
                    subtitle: Hardware.batteryStatus
                    isActive: true

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

                        // Battery bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            Layout.topMargin: Appearance.spacing.small

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Colours.palette.m3surfaceContainerHighest
                            }

                            Rectangle {
                                width: parent.width * (Hardware.batteryPercent / 100)
                                height: parent.height
                                radius: height / 2
                                color: Hardware.batteryPercent < 20 ? Colours.palette.m3error :
                                       Hardware.batteryCharging ? Colours.palette.m3primary : Colours.palette.m3secondary

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }

                    onClicked: {
                        root.session.hw.view = "battery";
                    }
                }

                // TDP Card (RyzenAdj)
                HardwareCard {
                    Layout.fillWidth: true
                    visible: Hardware.hasRyzenAdj

                    icon: "electric_bolt"
                    title: qsTr("TDP Control")
                    subtitle: qsTr("RyzenAdj - %1W").arg(Hardware.tdpStapmLimit.toFixed(0))
                    isActive: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.large

                            StatItem {
                                label: "STAPM"
                                value: Hardware.tdpStapmValue.toFixed(0) + "W"
                                icon: "trending_flat"
                                color: Colours.palette.m3primary
                            }

                            StatItem {
                                label: "Fast"
                                value: Hardware.tdpFastValue.toFixed(0) + "W"
                                icon: "trending_up"
                                color: Colours.palette.m3tertiary
                            }

                            StatItem {
                                label: qsTr("Temp")
                                value: Hardware.tdpThermalValue.toFixed(0) + "°C"
                                icon: "thermostat"
                                color: Hardware.tdpThermalValue > 90 ? Colours.palette.m3error : Colours.palette.m3secondary
                            }
                        }

                        // TDP usage bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            Layout.topMargin: Appearance.spacing.small

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Colours.palette.m3surfaceContainerHighest
                            }

                            Rectangle {
                                width: parent.width * Math.min(1, Hardware.tdpStapmValue / Math.max(1, Hardware.tdpStapmLimit))
                                height: parent.height
                                radius: height / 2
                                color: Colours.palette.m3tertiary

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }

                    onClicked: {
                        root.session.hw.view = "tdp";
                    }
                }

                // GPU Mode Card
                HardwareCard {
                    Layout.fillWidth: true
                    visible: Hardware.hasEnvyControl || Hardware.hasNvidiaGpu

                    icon: "swap_horiz"
                    title: qsTr("GPU Switching")
                    subtitle: Hardware.gpuMode === "nvidia" ? qsTr("NVIDIA Only") :
                              Hardware.gpuMode === "integrated" ? qsTr("Integrated") : qsTr("Hybrid")
                    isActive: true

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

                    onClicked: {
                        root.session.hw.view = "gpumode";
                    }
                }

                // RGB Keyboard Card
                HardwareCard {
                    Layout.fillWidth: true
                    visible: Hardware.hasRgbKeyboard

                    icon: "keyboard"
                    title: qsTr("RGB Keyboard")
                    subtitle: Hardware.rgbCurrentMode.charAt(0).toUpperCase() + 
                              Hardware.rgbCurrentMode.slice(1).replace(/_/g, " ")
                    isActive: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        // Zone color preview - simple row
                        Row {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            spacing: 2

                            Repeater {
                                model: Hardware.rgbColors

                                Rectangle {
                                    required property string modelData
                                    required property int index
                                    
                                    width: 20  // Fixed width
                                    height: 20
                                    radius: 4
                                    color: modelData || "#333333"
                                }
                            }
                        }

                        StyledText {
                            text: {
                                var name = Hardware.rgbDeviceName || qsTr("Legion 4-Zone RGB");
                                // Extract first few words for shorter format
                                var words = name.split(" ");
                                if (words.length >= 3) {
                                    return words[0] + " " + words[1] + " " + words[2]; // e.g., "Lenovo 5 2021"
                                } else {
                                    return name;
                                }
                            }
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: parent.width
                        }
                    }

                    onClicked: {
                        root.session.hw.view = "rgb";
                    }
                }

                // Quick Profiles Card
                HardwareCard {
                    Layout.fillWidth: true

                    icon: "tune"
                    title: qsTr("Quick Profiles")
                    subtitle: qsTr("One-click optimization")
                    isActive: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

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

                    onClicked: {
                        root.session.hw.view = "profiles";
                    }
                }

                // Power Profile Quick Toggle
                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    text: qsTr("Power Profile")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                    visible: Hardware.hasPowerProfiles
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: Hardware.hasPowerProfiles
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: Hardware.powerProfilesAvailable

                        ProfileButton {
                            required property string modelData
                            required property int index

                            Layout.fillWidth: true
                            
                            icon: modelData === "performance" ? "bolt" :
                                  modelData === "balanced" ? "balance" :
                                  modelData === "power-saver" ? "eco" : "settings"
                            label: modelData === "performance" ? qsTr("Performance") :
                                   modelData === "balanced" ? qsTr("Balanced") :
                                   modelData === "power-saver" ? qsTr("Power Saver") : modelData
                            isActive: Hardware.powerProfile === modelData

                            onClicked: {
                                Hardware.setPowerProfile(modelData);
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

            // View switcher
            Item {
                id: viewSwitcher
                
                anchors.fill: parent
                clip: true
                
                // 0=CPU, 1=GPU, 2=Battery, 3=TDP, 4=GPUMode, 5=Profiles, 6=RGB
                property int activeView: {
                    switch (root.session.hw.view) {
                        case "gpu": return 1;
                        case "battery": return 2;
                        case "tdp": return 3;
                        case "gpumode": return 4;
                        case "profiles": return 5;
                        case "rgb": return 6;
                        default: return 0;  // cpu
                    }
                }
                
                RowLayout {
                    spacing: 0
                    x: -viewSwitcher.activeView * viewSwitcher.width
                    
                    // CPU Details
                    Item {
                        Layout.preferredWidth: viewSwitcher.width
                        Layout.preferredHeight: viewSwitcher.height
                        
                        CpuSettings {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            session: root.session
                        }
                    }
                    
                    // GPU Details
                    Item {
                        Layout.preferredWidth: viewSwitcher.width
                        Layout.preferredHeight: viewSwitcher.height
                        
                        GpuSettings {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            session: root.session
                        }
                    }
                    
                    // Battery Details
                    Item {
                        Layout.preferredWidth: viewSwitcher.width
                        Layout.preferredHeight: viewSwitcher.height
                        
                        BatterySettings {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            session: root.session
                        }
                    }
                    
                    // TDP Details
                    Item {
                        Layout.preferredWidth: viewSwitcher.width
                        Layout.preferredHeight: viewSwitcher.height
                        
                        TdpSettings {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            session: root.session
                        }
                    }
                    
                    // GPU Mode Details
                    Item {
                        Layout.preferredWidth: viewSwitcher.width
                        Layout.preferredHeight: viewSwitcher.height
                        
                        GpuModeSettings {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            session: root.session
                        }
                    }
                    
                    // Profiles Details
                    Item {
                        Layout.preferredWidth: viewSwitcher.width
                        Layout.preferredHeight: viewSwitcher.height
                        
                        ProfilesSettings {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            session: root.session
                        }
                    }
                    
                    // RGB Details
                    Item {
                        Layout.preferredWidth: 400
                        Layout.maximumWidth: viewSwitcher.width
                        Layout.preferredHeight: viewSwitcher.height
                        
                        RgbSettings {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            session: root.session
                        }
                    }
                    
                    Behavior on x {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
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

    component HardwareCard: StyledRect {
        id: cardRoot

        required property string icon
        required property string title
        required property string subtitle
        property bool isActive: false

        default property alias content: contentLayout.children

        signal clicked()

        implicitHeight: cardLayout.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        StateLayer {
            radius: cardRoot.radius
            color: Colours.palette.m3onSurface
            onClicked: {
                cardRoot.clicked();
            }
        }

        ColumnLayout {
            id: cardLayout

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledRect {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: Appearance.rounding.small
                    color: cardRoot.isActive ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: cardRoot.icon
                        color: cardRoot.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: cardRoot.title
                        font.pointSize: Appearance.font.size.normal
                        font.weight: 600
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

            // Content area
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

    component ProfileButton: StyledRect {
        id: profileBtn

        required property string icon
        required property string label
        property bool isActive: false

        signal clicked()

        implicitHeight: 48
        radius: Appearance.rounding.full
        color: isActive ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

        StateLayer {
            radius: profileBtn.radius
            color: isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            onClicked: {
                profileBtn.clicked();
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: profileBtn.icon
                color: profileBtn.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: profileBtn.label
                font.pointSize: Appearance.font.size.small
                font.weight: 500
                color: profileBtn.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            }
        }
    }
}
