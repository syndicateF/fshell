pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.config
import qs.services
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    // Vulkan info state
    property string vulkanVersion: ""
    property var vulkanDevices: []
    property string vulkanLayersCount: ""
    property string vulkanExtensionsCount: ""
    property bool vulkanLoading: true
    property bool vulkanError: false
    property string vulkanRawOutput: ""

    // VA-API info state
    property string vaapiDriver: ""
    property string vaapiVersion: ""
    property string vaapiLibVersion: ""
    property var vaapiProfiles: []
    property bool vaapiLoading: true
    property bool vaapiError: false
    property string vaapiRawOutput: ""

    // GLX/EGL info (bonus)
    property string glRenderer: ""
    property string glVersion: ""
    property string glVendor: ""
    property bool glLoading: true

    Component.onCompleted: {
        vulkanProcess.running = true;
        vaapiProcess.running = true;
        glProcess.running = true;
    }

    // =====================================================
    // VULKAN PROCESS
    // =====================================================
    Process {
        id: vulkanProcess

        command: ["vulkaninfo", "--summary"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.vulkanRawOutput += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.vulkanLoading = false;
            if (exitCode !== 0) {
                root.vulkanError = true;
                return;
            }
            parseVulkanOutput(root.vulkanRawOutput);
        }

        function parseVulkanOutput(output: string): void {
            const lines = output.split("\n");
            let devices = [];
            let currentDevice = null;

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];

                // Parse Vulkan version
                if (line.includes("Vulkan Instance Version")) {
                    const match = line.match(/(\d+\.\d+\.\d+)/);
                    if (match) {
                        root.vulkanVersion = match[1];
                    }
                }

                // Parse extensions count
                if (line.includes("Instance Extensions: count =")) {
                    const match = line.match(/count\s*=\s*(\d+)/);
                    if (match) root.vulkanExtensionsCount = match[1];
                }

                // Parse layers count
                if (line.includes("Instance Layers: count =")) {
                    const match = line.match(/count\s*=\s*(\d+)/);
                    if (match) root.vulkanLayersCount = match[1];
                }

                // Parse GPU devices
                if (line.match(/^GPU\d+:/)) {
                    if (currentDevice && currentDevice.name) devices.push(currentDevice);
                    currentDevice = { 
                        name: "", 
                        driver: "", 
                        driverInfo: "",
                        api: "", 
                        type: "",
                        vendorId: "",
                        deviceId: "",
                        conformance: ""
                    };
                }

                if (currentDevice) {
                    const trimmed = line.trim();
                    if (trimmed.startsWith("deviceName")) {
                        const match = line.match(/=\s*(.+)$/);
                        if (match) currentDevice.name = match[1].trim();
                    }
                    if (trimmed.startsWith("driverName")) {
                        const match = line.match(/=\s*(.+)$/);
                        if (match) currentDevice.driver = match[1].trim();
                    }
                    if (trimmed.startsWith("driverInfo")) {
                        const match = line.match(/=\s*(.+)$/);
                        if (match) currentDevice.driverInfo = match[1].trim();
                    }
                    if (trimmed.startsWith("apiVersion")) {
                        const match = line.match(/(\d+\.\d+\.\d+)/);
                        if (match) currentDevice.api = match[1];
                    }
                    if (trimmed.startsWith("driverVersion")) {
                        const match = line.match(/=\s*(.+)$/);
                        if (match) currentDevice.driverVersion = match[1].trim();
                    }
                    if (trimmed.startsWith("deviceType")) {
                        const match = line.match(/=\s*(.+)$/);
                        if (match) {
                            const type = match[1].trim();
                            currentDevice.type = type.includes("INTEGRATED") ? "Integrated" :
                                                 type.includes("DISCRETE") ? "Discrete" : type;
                        }
                    }
                    if (trimmed.startsWith("vendorID")) {
                        const match = line.match(/=\s*(.+)$/);
                        if (match) currentDevice.vendorId = match[1].trim();
                    }
                    if (trimmed.startsWith("deviceID")) {
                        const match = line.match(/=\s*(.+)$/);
                        if (match) currentDevice.deviceId = match[1].trim();
                    }
                    if (trimmed.startsWith("conformanceVersion")) {
                        const match = line.match(/=\s*(.+)$/);
                        if (match) currentDevice.conformance = match[1].trim();
                    }
                }
            }

            if (currentDevice && currentDevice.name) devices.push(currentDevice);
            root.vulkanDevices = devices;
        }
    }

    // =====================================================
    // VA-API PROCESS
    // =====================================================
    Process {
        id: vaapiProcess

        command: ["vainfo"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.vaapiRawOutput += data;
            }
        }
        
        stderr: SplitParser {
            splitMarker: ""
            onRead: data => {
                // vainfo outputs most info to stderr
                root.vaapiRawOutput += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.vaapiLoading = false;
            // vainfo can exit with 0 even if it outputs to stderr
            parseVaapiOutput(root.vaapiRawOutput);
        }

        function parseVaapiOutput(output: string): void {
            const lines = output.split("\n");
            let profiles = [];

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];

                // Parse VA-API version (format: "VA-API version: 1.22 (libva 2.22.0)")
                if (line.includes("VA-API version:")) {
                    const verMatch = line.match(/VA-API version:\s*(\d+\.\d+)/);
                    if (verMatch) root.vaapiVersion = verMatch[1];
                    
                    const libMatch = line.match(/libva\s*([\d.]+)/);
                    if (libMatch) root.vaapiLibVersion = libMatch[1];
                }

                // Parse driver info
                if (line.includes("Driver version:")) {
                    const match = line.match(/Driver version:\s*(.+)/);
                    if (match) root.vaapiDriver = match[1].trim();
                }

                // Parse supported profiles
                if (line.includes("VAProfile") && line.includes("VAEntrypoint")) {
                    const profileMatch = line.match(/VAProfile(\w+)/);
                    const entryMatch = line.match(/VAEntrypoint(\w+)/);
                    
                    if (profileMatch && entryMatch) {
                        const rawProfile = profileMatch[1];
                        const entry = entryMatch[1];
                        
                        // Determine type
                        let type = "decode";
                        if (entry.includes("Enc")) type = "encode";
                        else if (entry === "VLD") type = "decode";
                        else if (entry === "VideoProc") type = "process";
                        
                        // Clean up profile name
                        let profile = rawProfile;
                        if (rawProfile.includes("H264")) profile = "H.264";
                        else if (rawProfile.includes("HEVC")) {
                            profile = "HEVC";
                            if (rawProfile.includes("10")) profile += " 10-bit";
                            if (rawProfile.includes("12")) profile += " 12-bit";
                            if (rawProfile.includes("444")) profile += " 4:4:4";
                        }
                        else if (rawProfile.includes("VP9")) {
                            profile = "VP9";
                            if (rawProfile.includes("2")) profile += " HDR";
                        }
                        else if (rawProfile.includes("VP8")) profile = "VP8";
                        else if (rawProfile.includes("AV1")) profile = "AV1";
                        else if (rawProfile.includes("MPEG2")) profile = "MPEG-2";
                        else if (rawProfile.includes("VC1")) profile = "VC-1";
                        else if (rawProfile.includes("JPEG")) profile = "JPEG";
                        
                        // Avoid duplicates
                        const existing = profiles.find(p => p.name === profile && p.type === type);
                        if (!existing && profile !== "None") {
                            profiles.push({ 
                                name: profile, 
                                type: type,
                                raw: rawProfile,
                                entry: entry
                            });
                        }
                    }
                }
            }

            root.vaapiProfiles = profiles;
        }
    }

    // =====================================================
    // OpenGL/GLX PROCESS (Bonus info)
    // =====================================================
    Process {
        id: glProcess

        property string rawOutput: ""
        
        command: ["sh", "-c", "glxinfo -B 2>/dev/null || echo 'N/A'"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                glProcess.rawOutput += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.glLoading = false;
            parseGlOutput(rawOutput);
        }

        function parseGlOutput(output: string): void {
            const lines = output.split("\n");
            
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];
                
                if (line.includes("OpenGL renderer string:")) {
                    const match = line.match(/OpenGL renderer string:\s*(.+)/);
                    if (match) root.glRenderer = match[1].trim();
                }
                if (line.includes("OpenGL version string:")) {
                    const match = line.match(/OpenGL version string:\s*(.+)/);
                    if (match) root.glVersion = match[1].trim();
                }
                if (line.includes("OpenGL vendor string:")) {
                    const match = line.match(/OpenGL vendor string:\s*(.+)/);
                    if (match) root.glVendor = match[1].trim();
                }
            }
        }
    }

    // =====================================================
    // UI
    // =====================================================
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
                text: "info"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("System Graphics Info")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Vulkan, VA-API & OpenGL Capabilities")
                color: Colours.palette.m3onSurfaceVariant
            }
            
            // Refresh button
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                text: qsTr("Refresh")
                icon: "refresh"
                onClicked: {
                    root.vulkanLoading = true;
                    root.vaapiLoading = true;
                    root.glLoading = true;
                    root.vulkanError = false;
                    root.vaapiError = false;
                    root.vulkanRawOutput = "";
                    root.vaapiRawOutput = "";
                    glProcess.rawOutput = "";
                    vulkanProcess.running = true;
                    vaapiProcess.running = true;
                    glProcess.running = true;
                }
            }

            // =====================================================
            // Vulkan Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("🔺 Vulkan")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("High-performance graphics & compute API")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: vulkanLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: vulkanLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Loading state
                    RowLayout {
                        visible: root.vulkanLoading
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: qsTr("Loading Vulkan info...")
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Error state
                    RowLayout {
                        visible: root.vulkanError && !root.vulkanLoading
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "error"
                            color: Colours.palette.m3error
                        }

                        StyledText {
                            text: qsTr("vulkaninfo not available (install vulkan-tools)")
                            color: Colours.palette.m3error
                        }
                    }

                    // Vulkan Stats Row
                    RowLayout {
                        visible: !root.vulkanLoading && !root.vulkanError
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.large

                        StatBox {
                            label: qsTr("Version")
                            value: root.vulkanVersion || "N/A"
                            icon: "verified"
                            color: Colours.palette.m3primary
                        }

                        StatBox {
                            label: qsTr("Extensions")
                            value: root.vulkanExtensionsCount || "0"
                            icon: "extension"
                            color: Colours.palette.m3secondary
                        }

                        StatBox {
                            label: qsTr("Layers")
                            value: root.vulkanLayersCount || "0"
                            icon: "layers"
                            color: Colours.palette.m3tertiary
                        }
                    }

                    // GPU Devices
                    Repeater {
                        model: root.vulkanDevices

                        StyledRect {
                            required property var modelData
                            required property int index

                            visible: !root.vulkanLoading && !root.vulkanError
                            Layout.fillWidth: true
                            implicitHeight: deviceLayout.implicitHeight + Appearance.padding.normal * 2
                            radius: Appearance.rounding.small
                            color: Colours.tPalette.m3surfaceContainerHighest

                            ColumnLayout {
                                id: deviceLayout

                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                spacing: Appearance.spacing.small

                                // GPU Header
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.normal

                                    StyledRect {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: Appearance.rounding.small
                                        color: modelData.type === "Integrated" ? 
                                               Colours.palette.m3tertiaryContainer : 
                                               Colours.palette.m3primaryContainer

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: modelData.type === "Integrated" ? "memory" : "videogame_asset"
                                            color: modelData.type === "Integrated" ? 
                                                   Colours.palette.m3onTertiaryContainer : 
                                                   Colours.palette.m3onPrimaryContainer
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.name || qsTr("Unknown GPU")
                                            font.weight: 600
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            text: modelData.type + " GPU"
                                            font.pointSize: Appearance.font.size.small
                                            color: modelData.type === "Integrated" ? 
                                                   Colours.palette.m3tertiary : 
                                                   Colours.palette.m3primary
                                        }
                                    }
                                }

                                // GPU Details Grid
                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Appearance.spacing.small
                                    columns: 2
                                    rowSpacing: 4
                                    columnSpacing: Appearance.spacing.large

                                    DetailLabel { text: qsTr("Driver") }
                                    DetailValue { text: modelData.driver || "N/A" }

                                    DetailLabel { text: qsTr("Driver Info") }
                                    DetailValue { text: modelData.driverInfo || "N/A" }

                                    DetailLabel { text: qsTr("Vulkan API") }
                                    DetailValue { text: modelData.api || "N/A"; highlight: true }

                                    DetailLabel { text: qsTr("Conformance") }
                                    DetailValue { text: modelData.conformance || "N/A" }

                                    DetailLabel { text: qsTr("Vendor ID") }
                                    DetailValue { text: modelData.vendorId || "N/A" }

                                    DetailLabel { text: qsTr("Device ID") }
                                    DetailValue { text: modelData.deviceId || "N/A" }
                                }
                            }
                        }
                    }
                }
            }

            // =====================================================
            // VA-API Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("🎬 VA-API")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Hardware video acceleration")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: vaapiLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: vaapiLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Loading state
                    RowLayout {
                        visible: root.vaapiLoading
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: qsTr("Loading VA-API info...")
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Error state
                    RowLayout {
                        visible: root.vaapiError && !root.vaapiLoading
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "error"
                            color: Colours.palette.m3error
                        }

                        StyledText {
                            text: qsTr("vainfo not available (install libva-utils)")
                            color: Colours.palette.m3error
                        }
                    }

                    // VA-API Stats
                    RowLayout {
                        visible: !root.vaapiLoading && !root.vaapiError && root.vaapiVersion
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.large

                        StatBox {
                            label: qsTr("VA-API")
                            value: root.vaapiVersion || "N/A"
                            icon: "play_circle"
                            color: Colours.palette.m3primary
                        }

                        StatBox {
                            label: qsTr("libva")
                            value: root.vaapiLibVersion || "N/A"
                            icon: "library_books"
                            color: Colours.palette.m3secondary
                        }
                    }

                    // Driver info
                    StatRow {
                        visible: !root.vaapiLoading && !root.vaapiError && root.vaapiDriver
                        Layout.fillWidth: true
                        icon: "memory"
                        label: qsTr("Backend Driver")
                        value: root.vaapiDriver
                    }

                    // Decode Profiles
                    ColumnLayout {
                        visible: !root.vaapiLoading && !root.vaapiError
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("🔓 Decode Support")
                            font.weight: 500
                            color: Colours.palette.m3onSurface
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            Repeater {
                                model: root.vaapiProfiles.filter(p => p.type === "decode")

                                CodecTag {
                                    required property var modelData
                                    text: modelData.name
                                    tagColor: Colours.palette.m3primaryContainer
                                    textColor: Colours.palette.m3onPrimaryContainer
                                }
                            }
                        }

                        StyledText {
                            visible: root.vaapiProfiles.filter(p => p.type === "decode").length === 0
                            text: qsTr("No decode profiles available")
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Encode Profiles
                    ColumnLayout {
                        visible: !root.vaapiLoading && !root.vaapiError
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("🔒 Encode Support")
                            font.weight: 500
                            color: Colours.palette.m3onSurface
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            Repeater {
                                model: root.vaapiProfiles.filter(p => p.type === "encode")

                                CodecTag {
                                    required property var modelData
                                    text: modelData.name
                                    tagColor: Colours.palette.m3tertiaryContainer
                                    textColor: Colours.palette.m3onTertiaryContainer
                                }
                            }
                        }

                        StyledText {
                            visible: root.vaapiProfiles.filter(p => p.type === "encode").length === 0
                            text: qsTr("No encode profiles (NVENC uses different API)")
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }
            }

            // =====================================================
            // OpenGL Section
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("🎨 OpenGL")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Legacy graphics API compatibility")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: glLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: glLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    // Loading
                    StyledText {
                        visible: root.glLoading
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Loading OpenGL info...")
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    // Content
                    GridLayout {
                        visible: !root.glLoading
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: Appearance.spacing.small
                        columnSpacing: Appearance.spacing.large

                        StatRow {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            icon: "brush"
                            label: qsTr("Renderer")
                            value: root.glRenderer || "N/A"
                        }

                        StatRow {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            icon: "verified"
                            label: qsTr("Version")
                            value: root.glVersion || "N/A"
                        }

                        StatRow {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            icon: "business"
                            label: qsTr("Vendor")
                            value: root.glVendor || "N/A"
                        }
                    }
                }
            }

            // =====================================================
            // Quick Reference
            // =====================================================
            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("📚 Codec Reference")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: refLayout.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                GridLayout {
                    id: refLayout

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    columns: 2
                    rowSpacing: Appearance.spacing.small
                    columnSpacing: Appearance.spacing.normal

                    CodecTag { text: "H.264/AVC"; tagColor: Colours.palette.m3primaryContainer; textColor: Colours.palette.m3onPrimaryContainer }
                    StyledText { text: qsTr("Most compatible, good quality"); font.pointSize: Appearance.font.size.small; color: Colours.palette.m3onSurfaceVariant; Layout.fillWidth: true }

                    CodecTag { text: "HEVC/H.265"; tagColor: Colours.palette.m3primaryContainer; textColor: Colours.palette.m3onPrimaryContainer }
                    StyledText { text: qsTr("Better compression, 4K content"); font.pointSize: Appearance.font.size.small; color: Colours.palette.m3onSurfaceVariant; Layout.fillWidth: true }

                    CodecTag { text: "AV1"; tagColor: Colours.palette.m3tertiaryContainer; textColor: Colours.palette.m3onTertiaryContainer }
                    StyledText { text: qsTr("Modern, royalty-free, best compression"); font.pointSize: Appearance.font.size.small; color: Colours.palette.m3onSurfaceVariant; Layout.fillWidth: true }

                    CodecTag { text: "VP9"; tagColor: Colours.palette.m3secondaryContainer; textColor: Colours.palette.m3onSecondaryContainer }
                    StyledText { text: qsTr("YouTube & WebM streaming"); font.pointSize: Appearance.font.size.small; color: Colours.palette.m3onSurfaceVariant; Layout.fillWidth: true }

                    CodecTag { text: "NVENC"; tagColor: Colours.palette.m3errorContainer; textColor: Colours.palette.m3onErrorContainer }
                    StyledText { text: qsTr("NVIDIA hardware encode (separate API)"); font.pointSize: Appearance.font.size.small; color: Colours.palette.m3onSurfaceVariant; Layout.fillWidth: true }
                }
            }

            // Spacer at bottom
            Item { Layout.preferredHeight: Appearance.padding.large }
        }
    }

    // =====================================================
    // COMPONENTS
    // =====================================================

    component StatRow: RowLayout {
        required property string icon
        required property string label
        required property string value
        property color valueColor: Colours.palette.m3onSurface

        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: parent.icon
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true
            text: parent.label
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: parent.value
            font.weight: 500
            color: parent.valueColor
        }
    }

    component StatBox: ColumnLayout {
        required property string label
        required property string value
        required property string icon
        property color color: Colours.palette.m3primary

        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            spacing: 6
            
            MaterialIcon {
                text: parent.parent.icon
                font.pointSize: Appearance.font.size.normal
                color: parent.parent.color
            }

            StyledText {
                text: parent.parent.value
                font.pointSize: Appearance.font.size.larger
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

    component DetailLabel: StyledText {
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3onSurfaceVariant
    }

    component DetailValue: StyledText {
        property bool highlight: false
        Layout.fillWidth: true
        font.pointSize: Appearance.font.size.small
        font.weight: highlight ? 600 : 400
        color: highlight ? Colours.palette.m3primary : Colours.palette.m3onSurface
        elide: Text.ElideRight
    }

    component CodecTag: StyledRect {
        required property string text
        property color tagColor: Colours.palette.m3primaryContainer
        property color textColor: Colours.palette.m3onPrimaryContainer

        implicitWidth: tagLabel.implicitWidth + Appearance.padding.small * 2
        implicitHeight: tagLabel.implicitHeight + 6
        radius: Appearance.rounding.small
        color: tagColor

        StyledText {
            id: tagLabel
            anchors.centerIn: parent
            text: parent.text
            font.pointSize: Appearance.font.size.small
            font.weight: 500
            color: parent.textColor
        }
    }
}
