pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    
    // Confirmation dialog state
    property bool showKillConfirm: false
    property int pendingKillPid: 0
    property string pendingKillCommand: ""

    StyledFlickable {
        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: mainLayout.height

        ColumnLayout {
            id: mainLayout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            // Header
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "swap_horiz"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
                color: Colours.palette.m3secondary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("GPU Switching")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Optimus / Prime Render Offload")
                color: Colours.palette.m3onSurfaceVariant
            }
            
            // Note: No reset button for GPU Mode since switching requires reboot
            // and there's no "default" mode

            // =====================================================
            // Current GPU Status
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Current Status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: statusLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: statusLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Mode info
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: Hardware.gpuMode === "nvidia" ? "videogame_asset" :
                                  Hardware.gpuMode === "integrated" ? "battery_saver" : "auto_mode"
                            font.pointSize: Appearance.font.size.extraLarge * 1.5
                            color: Hardware.gpuMode === "nvidia" ? Colours.palette.m3tertiary :
                                   Hardware.gpuMode === "integrated" ? Colours.palette.m3primary : Colours.palette.m3secondary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: Hardware.gpuMode === "nvidia" ? qsTr("NVIDIA Only") :
                                      Hardware.gpuMode === "integrated" ? qsTr("Integrated Only") : qsTr("Hybrid Mode")
                                font.pointSize: Appearance.font.size.larger
                                font.weight: 600
                            }

                            StyledText {
                                text: Hardware.gpuMode === "nvidia" ? qsTr("Always use discrete GPU") :
                                      Hardware.gpuMode === "integrated" ? qsTr("Discrete GPU is powered off") : 
                                      qsTr("Apps use iGPU, games use dGPU on demand")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }

                    // Current render GPU
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: renderRow.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3surfaceContainerHighest

                        RowLayout {
                            id: renderRow
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.normal
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "monitor"
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                text: qsTr("Current Render GPU:")
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Hardware.currentRenderGpu || "Unknown"
                                font.weight: 500
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }
            }

            // =====================================================
            // GPU Mode Selection
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                visible: Hardware.hasEnvyControl
                text: qsTr("GPU Mode")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                visible: Hardware.hasEnvyControl
                text: qsTr("Select which GPU(s) to use. Requires reboot to apply.")
                color: Colours.palette.m3outline
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: Hardware.hasEnvyControl
                spacing: Appearance.spacing.small

                GpuModeCard {
                    Layout.fillWidth: true
                    mode: "integrated"
                    icon: "battery_saver"
                    name: qsTr("Integrated Only")
                    description: qsTr("AMD Radeon Graphics only. Best battery life, NVIDIA GPU powered off completely.")
                    pros: qsTr("• Maximum battery life\n• Lowest heat & fan noise\n• Good for office work")
                    cons: qsTr("• No 3D gaming\n• No CUDA/NVENC")
                    isActive: Hardware.gpuMode === "integrated"

                    onClicked: {
                        Hardware.setGpuMode("integrated");
                    }
                }

                GpuModeCard {
                    Layout.fillWidth: true
                    mode: "hybrid"
                    icon: "auto_mode"
                    name: qsTr("Hybrid (Recommended)")
                    description: qsTr("Use iGPU for desktop, dGPU for games/apps via prime-run. Best of both worlds.")
                    pros: qsTr("• Good battery when idle\n• Full GPU power when needed\n• Use prime-run for games")
                    cons: qsTr("• Slight overhead switching\n• Need to prefix commands")
                    isActive: Hardware.gpuMode === "hybrid"

                    onClicked: {
                        Hardware.setGpuMode("hybrid");
                    }
                }

                GpuModeCard {
                    Layout.fillWidth: true
                    mode: "nvidia"
                    icon: "videogame_asset"
                    name: qsTr("NVIDIA Only")
                    description: qsTr("Always use NVIDIA RTX GPU for everything. Maximum performance.")
                    pros: qsTr("• Maximum GPU performance\n• No switching overhead\n• Best for gaming sessions")
                    cons: qsTr("• Higher power usage\n• More heat\n• Reduced battery life")
                    isActive: Hardware.gpuMode === "nvidia"

                    onClicked: {
                        Hardware.setGpuMode("nvidia");
                    }
                }
            }

            // envycontrol not installed
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.large
                visible: !Hardware.hasEnvyControl
                implicitHeight: notInstalledLayout.implicitHeight + Appearance.padding.large * 2
                radius: Appearance.rounding.normal
                color: Colours.palette.m3errorContainer

                ColumnLayout {
                    id: notInstalledLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "warning"
                            font.pointSize: Appearance.font.size.extraLarge
                            color: Colours.palette.m3onErrorContainer
                        }

                        StyledText {
                            text: qsTr("envycontrol not installed")
                            font.weight: 600
                            color: Colours.palette.m3onErrorContainer
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("To enable GPU switching, install envycontrol:\nyay -S envycontrol")
                        color: Colours.palette.m3onErrorContainer
                        wrapMode: Text.Wrap
                    }
                }
            }

            // =====================================================
            // GPU Processes
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                visible: Hardware.hasNvidiaGpu
                text: qsTr("GPU Processes")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                visible: Hardware.hasNvidiaGpu
                text: qsTr("Applications currently using the NVIDIA GPU")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                visible: Hardware.hasNvidiaGpu
                implicitHeight: processesLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: processesLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.small

                    // No processes
                    RowLayout {
                        Layout.fillWidth: true
                        visible: Hardware.gpuProcesses.length === 0
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "check_circle"
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: qsTr("No applications using the GPU")
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Process list
                    Repeater {
                        model: Hardware.gpuProcesses

                        ProcessRow {
                            Layout.fillWidth: true
                            required property var modelData
                            required property int index

                            pid: modelData.pid
                            command: modelData.command
                            gpuUsage: modelData.sm
                            memUsage: modelData.mem
                            processType: modelData.type

                            onKillRequested: {
                                root.pendingKillPid = modelData.pid;
                                root.pendingKillCommand = modelData.command;
                                root.showKillConfirm = true;
                            }
                        }
                    }
                }
            }

            // Reboot warning
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                visible: Hardware.hasEnvyControl
                implicitHeight: rebootRow.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.small
                color: Colours.palette.m3tertiaryContainer

                RowLayout {
                    id: rebootRow
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "restart_alt"
                        color: Colours.palette.m3onTertiaryContainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("GPU mode changes require a system reboot to take effect")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onTertiaryContainer
                        wrapMode: Text.Wrap
                    }
                }
            }

            Item { Layout.preferredHeight: Appearance.spacing.large }
        }
    }

    // Confirmation Dialog Overlay for Kill Process
    Item {
        id: killConfirmOverlay
        
        anchors.fill: parent
        visible: root.showKillConfirm || killDialogContent.opacity > 0
        z: 100
        
        // Scrim background
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, root.showKillConfirm ? 0.5 : 0)
            
            Behavior on color {
                ColorAnimation { duration: Appearance.anim.durations.normal }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.showKillConfirm = false
            }
        }
        
        // Dialog
        StyledRect {
            id: killDialogContent
            
            anchors.centerIn: parent
            implicitWidth: Math.min(400, parent.width - Appearance.padding.large * 4)
            implicitHeight: killDialogLayout.implicitHeight + Appearance.padding.large * 2
            
            radius: Appearance.rounding.large
            color: Colours.palette.m3surfaceContainerHigh
            opacity: root.showKillConfirm ? 1 : 0
            scale: root.showKillConfirm ? 1 : 0.8
            visible: opacity > 0 || closeAnim.running
            
            Behavior on opacity {
                NumberAnimation { 
                    duration: Appearance.anim.durations.normal
                }
            }
            
            Behavior on scale {
                NumberAnimation {
                    id: closeAnim
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.OutBack
                }
            }
            
            ColumnLayout {
                id: killDialogLayout
                
                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal
                
                // Icon
                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "warning"
                    color: Colours.palette.m3error
                    font.pointSize: Appearance.font.size.extraLarge * 2
                }
                
                // Title
                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Terminate Process?")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 600
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                
                // Process info
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: processInfoLayout.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest
                    
                    ColumnLayout {
                        id: processInfoLayout
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        spacing: 4
                        
                        StyledText {
                            Layout.fillWidth: true
                            text: root.pendingKillCommand
                            font.weight: 600
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle
                        }
                        
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("PID: %1").arg(root.pendingKillPid)
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
                
                // Warning message
                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("This will forcefully terminate the process. Unsaved data may be lost.")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                
                // Buttons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.normal
                    spacing: Appearance.spacing.normal
                    
                    // Cancel button
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        
                        radius: Appearance.rounding.full
                        color: Colours.palette.m3surfaceContainerHighest
                        
                        StateLayer {
                            color: Colours.palette.m3onSurface
                            function onClicked(): void {
                                root.showKillConfirm = false;
                            }
                        }
                        
                        StyledText {
                            anchors.centerIn: parent
                            text: qsTr("Cancel")
                        }
                    }
                    
                    // Confirm kill button
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        
                        radius: Appearance.rounding.full
                        color: Colours.palette.m3error
                        
                        StateLayer {
                            color: Colours.palette.m3onError
                            function onClicked(): void {
                                Hardware.killGpuProcess(root.pendingKillPid);
                                root.showKillConfirm = false;
                            }
                        }
                        
                        StyledText {
                            anchors.centerIn: parent
                            text: qsTr("Terminate")
                            color: Colours.palette.m3onError
                        }
                    }
                }
            }
        }
    }

    // =====================================================
    // COMPONENTS
    // =====================================================

    component GpuModeCard: StyledRect {
        id: modeCard

        property string mode
        property string icon
        property string name
        property string description
        property string pros
        property string cons
        property bool isActive: false

        signal clicked()

        implicitHeight: modeLayout.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.normal
        color: isActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
        border.width: isActive ? 2 : 0
        border.color: Colours.palette.m3primary

        StateLayer {
            radius: modeCard.radius
            color: isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

            onClicked: {
                modeCard.clicked();
            }
        }

        ColumnLayout {
            id: modeLayout

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: modeCard.icon
                    font.pointSize: Appearance.font.size.extraLarge * 1.5
                    color: modeCard.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: modeCard.name
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 600
                        color: modeCard.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modeCard.description
                        font.pointSize: Appearance.font.size.small
                        color: modeCard.isActive ? Qt.alpha(Colours.palette.m3onPrimaryContainer, 0.8) : Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.Wrap
                    }
                }

                MaterialIcon {
                    visible: modeCard.isActive
                    text: "check_circle"
                    font.pointSize: Appearance.font.size.extraLarge
                    color: Colours.palette.m3onPrimaryContainer
                }
            }

            // Pros and Cons
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.large

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: "✓ " + qsTr("Pros")
                        font.pointSize: Appearance.font.size.small
                        font.weight: 500
                        color: modeCard.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modeCard.pros
                        font.pointSize: Appearance.font.size.small
                        color: modeCard.isActive ? Qt.alpha(Colours.palette.m3onPrimaryContainer, 0.7) : Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.Wrap
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: "✗ " + qsTr("Cons")
                        font.pointSize: Appearance.font.size.small
                        font.weight: 500
                        color: modeCard.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3error
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modeCard.cons
                        font.pointSize: Appearance.font.size.small
                        color: modeCard.isActive ? Qt.alpha(Colours.palette.m3onPrimaryContainer, 0.7) : Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    component ProcessRow: StyledRect {
        id: processRow

        property int pid
        property string command
        property int gpuUsage
        property int memUsage
        property string processType

        signal killRequested()

        implicitHeight: processLayout.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.small
        color: "transparent"

        RowLayout {
            id: processLayout

            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.small
            anchors.rightMargin: Appearance.padding.small
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: processRow.processType === "G" ? "videogame_asset" : "memory"
                color: Colours.palette.m3onSurfaceVariant
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true
                    text: processRow.command
                    font.weight: 500
                    elide: Text.ElideMiddle
                }

                StyledText {
                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true
                    text: qsTr("PID: %1 | GPU: %2% | MEM: %3%").arg(processRow.pid).arg(processRow.gpuUsage).arg(processRow.memUsage)
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                icon: "close"
                type: IconButton.Tonal
                activeColour: Colours.palette.m3errorContainer
                activeOnColour: Colours.palette.m3onErrorContainer
                checked: true

                onClicked: {
                    processRow.killRequested();
                }
            }
        }
    }
}
