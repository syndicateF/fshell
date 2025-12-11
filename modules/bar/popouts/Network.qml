pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Item wrapper

    spacing: Appearance.spacing.small
    width: Config.bar.sizes.networkWidth

    // Header with title and quick toggles
    RowLayout {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.small
        spacing: Appearance.spacing.smaller

        StyledText {
            text: qsTr("Wi-Fi")
            font.weight: 500
            font.pointSize: Appearance.font.size.large
        }

        Item {
            Layout.fillWidth: true
        }

        // Airplane mode toggle
        ToggleButton {
            toggled: Network.airplaneMode
            icon: Network.airplaneMode ? "airplanemode_active" : "airplanemode_inactive"
            accent: "Error"

            function onClicked(): void {
                Network.toggleAirplaneMode();
            }
        }

        // WiFi toggle
        ToggleButton {
            toggled: Network.wifiEnabled
            icon: "power"
            accent: "Tertiary"
            disabled: Network.airplaneMode

            function onClicked(): void {
                Network.toggleWifi();
            }
        }

        // Scan networks toggle
        ToggleButton {
            toggled: Network.scanning
            icon: "wifi_find"
            accent: "Secondary"
            disabled: !Network.wifiEnabled || Network.airplaneMode

            function onClicked(): void {
                Network.rescanWifi();
            }
        }

        // Open panel button
        ToggleButton {
            toggled: false
            icon: "open_in_full"

            function onClicked(): void {
                root.wrapper.detach("network");
            }
        }
    }

    // Captive Portal Warning
    StyledRect {
        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        implicitHeight: captiveRow.implicitHeight + Appearance.padding.small * 2
        
        visible: Network.captivePortalDetected
        radius: Appearance.rounding.small
        color: Colours.palette.m3tertiaryContainer

        StateLayer {
            color: Colours.palette.m3onTertiaryContainer

            function onClicked(): void {
                Network.openCaptivePortal();
            }
        }

        RowLayout {
            id: captiveRow
            
            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: "captive_portal"
                color: Colours.palette.m3onTertiaryContainer
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Sign in required")
                color: Colours.palette.m3onTertiaryContainer
                font.pointSize: Appearance.font.size.small
            }

            MaterialIcon {
                text: "open_in_new"
                color: Colours.palette.m3onTertiaryContainer
                font.pointSize: Appearance.font.size.small
            }
        }
    }

    // Network list
    Repeater {
        model: ScriptModel {
            values: [...Network.networks].sort((a, b) => {
                if (a.active !== b.active)
                    return b.active - a.active;
                if (a.isSaved !== b.isSaved)
                    return b.isSaved - a.isSaved;
                return b.strength - a.strength;
            }).slice(0, 8)
        }

        RowLayout {
            id: networkItem

            required property var modelData
            readonly property bool isConnecting: Network.connecting && Network.lastConnectedSSID === modelData.ssid

            Layout.fillWidth: true
            Layout.rightMargin: Appearance.padding.small
            spacing: Appearance.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            // Network strength icon
            MaterialIcon {
                text: Icons.getNetworkIcon(networkItem.modelData.strength)
                color: Colours.palette.m3onSurfaceVariant
            }

            // SSID
            StyledText {
                Layout.leftMargin: Appearance.spacing.small / 2
                Layout.rightMargin: Appearance.spacing.small / 2
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font.weight: networkItem.modelData.active ? 500 : 400
                color: Colours.palette.m3onSurface
            }

            // Security/Saved indicator (moved to RIGHT, before connect button)
            MaterialIcon {
                visible: networkItem.modelData.isSaved || networkItem.modelData.isSecure
                text: networkItem.modelData.isSaved ? "bookmark" : "lock"
                font.pointSize: Appearance.font.size.small
                color: networkItem.modelData.isSaved ? Colours.palette.m3tertiary : Colours.palette.m3outline
            }

            // Connect/Disconnect/Password button
            StyledRect {
                id: connectBtn

                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Appearance.padding.small

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primaryContainer, networkItem.modelData.active ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: networkItem.isConnecting
                }

                StateLayer {
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    disabled: networkItem.isConnecting || !Network.wifiEnabled || Network.airplaneMode

                    function onClicked(): void {
                        if (networkItem.modelData.active) {
                            Network.disconnectFromNetwork();
                        } else if (networkItem.modelData.isSaved) {
                            // Saved network - use conn up
                            Network.connectToNetwork(networkItem.modelData.ssid, "", true);
                        } else if (networkItem.modelData.isSecure) {
                            // New secured network - set pending and open panel with password dialog
                            Network.pendingNetworkFromBar = networkItem.modelData;
                            Network.openPasswordDialogOnPanelOpen = true;
                            root.wrapper.detach("network");
                        } else {
                            // Open network - use wifi connect
                            Network.connectToNetwork(networkItem.modelData.ssid, "", false);
                        }
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : networkItem.modelData.isSecure && !networkItem.modelData.isSaved ? "key" : "link"
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                    opacity: networkItem.isConnecting ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }

    // Unified Status Footer - SATU LOKASI untuk semua status/notifikasi
    StyledRect {
        id: statusFooter
        
        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        implicitHeight: statusContent.implicitHeight + Appearance.padding.normal
        
        // Status priority: warning > connected > airplane > disabled > hotspot > count
        readonly property bool hasWarning: Network.warningMessage.length > 0
        readonly property string currentState: {
            if (hasWarning) return "warning";
            if (Network.active !== null) return "connected";
            if (Network.airplaneMode) return "airplane";
            if (!Network.wifiEnabled) return "disabled";
            if (Network.hotspotActive) return "hotspot";
            return "available";
        }
        
        readonly property string statusText: {
            if (hasWarning) return Network.warningMessage;
            switch (currentState) {
                case "connected": return qsTr("Connected to %1").arg(Network.active?.ssid ?? "");
                case "airplane": return qsTr("Airplane mode is on");
                case "disabled": return qsTr("Wi-Fi is disabled");
                case "hotspot": return qsTr("Hotspot: %1").arg(Network.hotspotSSID);
                default: return qsTr("%1 networks available").arg(Network.networks.length);
            }
        }
        
        readonly property string statusIcon: {
            if (hasWarning) {
                if (Network.warningType === "error") return "error";
                if (Network.warningType === "success") return "check_circle";
                if (Network.warningType === "warning") return "warning";
                return "info";
            }
            switch (currentState) {
                case "connected": return "wifi";
                case "airplane": return "airplanemode_active";
                case "disabled": return "wifi_off";
                case "hotspot": return "wifi_tethering";
                default: return "";
            }
        }
        
        readonly property color bgColor: {
            if (hasWarning) {
                if (Network.warningType === "error") return Colours.palette.m3errorContainer;
                if (Network.warningType === "success") return Colours.palette.m3primaryContainer;
                if (Network.warningType === "warning") return Colours.palette.m3tertiaryContainer;
                return Colours.palette.m3secondaryContainer;
            }
            switch (currentState) {
                case "connected": return Colours.palette.m3primaryContainer;
                case "airplane": return Colours.palette.m3errorContainer;
                case "disabled": return Colours.palette.m3surfaceContainerHighest;
                case "hotspot": return Colours.palette.m3tertiaryContainer;
                default: return Colours.palette.m3surfaceContainerHigh;
            }
        }
        
        readonly property color fgColor: {
            if (hasWarning) {
                if (Network.warningType === "error") return Colours.palette.m3onErrorContainer;
                if (Network.warningType === "success") return Colours.palette.m3onPrimaryContainer;
                if (Network.warningType === "warning") return Colours.palette.m3onTertiaryContainer;
                return Colours.palette.m3onSecondaryContainer;
            }
            switch (currentState) {
                case "connected": return Colours.palette.m3onPrimaryContainer;
                case "airplane": return Colours.palette.m3onErrorContainer;
                case "disabled": return Colours.palette.m3onSurface;
                case "hotspot": return Colours.palette.m3onTertiaryContainer;
                default: return Colours.palette.m3onSurfaceVariant;
            }
        }
        
        // Radius dari Config.border.rounding (sama seperti bar)
        radius: Config.border.rounding
        color: bgColor
        clip: true

        RowLayout {
            id: statusContent
            
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            // Icon - hanya muncul jika ada
            MaterialIcon {
                id: statusIconDisplay
                
                visible: statusFooter.statusIcon !== ""
                text: statusFooter.statusIcon
                color: statusFooter.fgColor
                
                scale: 1
                
                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: statusIconDisplay; property: "scale"; to: 0; duration: 100; easing.type: Easing.InQuad }
                        PropertyAction { target: statusIconDisplay; property: "text" }
                        NumberAnimation { target: statusIconDisplay; property: "scale"; to: 1.2; duration: 150; easing.type: Easing.OutBack }
                        NumberAnimation { target: statusIconDisplay; property: "scale"; to: 1; duration: 100; easing.type: Easing.OutQuad }
                    }
                }
                
                Behavior on color {
                    ColorAnimation { duration: Appearance.anim.durations.small }
                }
            }

            // Text
            StyledText {
                id: statusTextDisplay
                
                text: statusFooter.statusText
                color: statusFooter.fgColor
                
                opacity: 1
                
                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: statusTextDisplay; property: "opacity"; to: 0; duration: 100; easing.type: Easing.InQuad }
                        PropertyAction { target: statusTextDisplay; property: "text" }
                        NumberAnimation { target: statusTextDisplay; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutQuad }
                    }
                }
                
                Behavior on color {
                    ColorAnimation { duration: Appearance.anim.durations.small }
                }
            }
        }
        
        Behavior on color {
            ColorAnimation { 
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutCubic
            }
        }
        
        opacity: 0
        scale: 0.9
        
        Component.onCompleted: {
            opacity = 1;
            scale = 1;
        }
        
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.OutBack
            }
        }
    }

    // ToggleButton component - compact version for bar popout (same logic as Control Center)
    component ToggleButton: StyledRect {
        id: toggleBtn

        required property bool toggled
        property string icon
        property string accent: "Secondary"
        property bool disabled: false

        function onClicked(): void {
        }

        // Use Layout.preferredWidth for proper RowLayout reflow
        Layout.preferredWidth: implicitWidth + (toggleStateLayer.pressed ? Appearance.padding.small : toggled ? Appearance.padding.smaller : 0)
        implicitWidth: toggleBtnIcon.implicitWidth + Appearance.padding.normal * 2
        implicitHeight: toggleBtnIcon.implicitHeight + Appearance.padding.small * 2

        // Proper pill radius formula - uses width for consistent rounding
        radius: toggled || toggleStateLayer.pressed ? Appearance.rounding.small : Math.min(width, height) / 2 * Math.min(1, Appearance.rounding.scale)
        color: toggled ? Colours.palette[`m3${accent.toLowerCase()}`] : Colours.palette[`m3${accent.toLowerCase()}Container`]
        opacity: disabled ? 0.5 : 1

        StateLayer {
            id: toggleStateLayer

            color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
            disabled: toggleBtn.disabled

            function onClicked(): void {
                toggleBtn.onClicked();
            }
        }

        MaterialIcon {
            id: toggleBtnIcon

            anchors.centerIn: parent
            visible: !!text
            fill: toggleBtn.toggled ? 1 : 0
            text: toggleBtn.icon
            color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
            font.pointSize: Appearance.font.size.normal

            Behavior on fill {
                Anim {}
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

        Behavior on color {
            ColorAnimation {
                duration: Appearance.anim.durations.small
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
