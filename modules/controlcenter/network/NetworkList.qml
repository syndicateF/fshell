pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property bool smallScanning: width <= 540

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: Appearance.spacing.small

        RowLayout {
            spacing: Appearance.spacing.smaller

            StyledText {
                text: qsTr("Networks")
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            Item {
                Layout.fillWidth: true
            }

            ToggleButton {
                toggled: Network.wifiEnabled
                icon: "power"
                accent: "Tertiary"

                function onClicked(): void {
                    Network.toggleWifi();
                }
            }

            ToggleButton {
                toggled: Network.scanning
                icon: root.smallScanning ? "wifi_find" : ""
                label: root.smallScanning ? "" : qsTr("Scanning")

                function onClicked(): void {
                    Network.rescanWifi();
                }
            }

            ToggleButton {
                toggled: !root.session.nw.active
                icon: "settings"
                accent: "Primary"

                function onClicked(): void {
                    if (root.session.nw.active)
                        root.session.nw.active = null;
                    else {
                        root.session.nw.active = Network.active ?? Network.networks[0] ?? null;
                    }
                }
            }
        }

        RowLayout {
            Layout.topMargin: Appearance.spacing.large
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Available Networks (%1)").arg(Network.networks.length)
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Network.wifiEnabled ? qsTr("All available Wi-Fi networks") : qsTr("Wi-Fi is disabled")
                    color: Colours.palette.m3outline
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: scanIcon.implicitHeight + Appearance.padding.normal * 2

                radius: Network.scanning ? Appearance.rounding.normal : implicitHeight / 2 * Math.min(1, Appearance.rounding.scale)
                color: Network.scanning ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                StateLayer {
                    color: Network.scanning ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer

                    function onClicked(): void {
                        Network.rescanWifi();
                    }
                }

                MaterialIcon {
                    id: scanIcon

                    anchors.centerIn: parent
                    animate: true
                    text: "wifi_find"
                    color: Network.scanning ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                    fill: Network.scanning ? 1 : 0
                }

                Behavior on radius {
                    Anim {}
                }
            }
        }

        // Network traffic indicator
        StyledRect {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            implicitHeight: trafficRow.implicitHeight + Appearance.padding.normal * 2
            
            visible: Network.active !== null
            radius: Appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh

            RowLayout {
                id: trafficRow
                
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.large

                RowLayout {
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "download"
                        color: Colours.palette.m3primary
                        font.pointSize: Appearance.font.size.normal
                        opacity: Network.speedOpacity(Network.downloadSpeed)
                        
                        Behavior on opacity {
                            Anim { duration: Appearance.anim.durations.small }
                        }
                    }

                    StyledText {
                        text: Network.formatSpeed(Network.downloadSpeed)
                        color: Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.small
                    }
                }

                RowLayout {
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "upload"
                        color: Colours.palette.m3tertiary
                        font.pointSize: Appearance.font.size.normal
                        opacity: Network.speedOpacity(Network.uploadSpeed)
                        
                        Behavior on opacity {
                            Anim { duration: Appearance.anim.durations.small }
                        }
                    }

                    StyledText {
                        text: Network.formatSpeed(Network.uploadSpeed)
                        color: Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.small
                    }
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: Network.networkInterface
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }
            }
        }

        // Captive Portal Warning
        StyledRect {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            implicitHeight: captiveRow.implicitHeight + Appearance.padding.normal * 2
            
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
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "captive_portal"
                    color: Colours.palette.m3onTertiaryContainer
                    font.pointSize: Appearance.font.size.large
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: qsTr("Sign in required")
                        color: Colours.palette.m3onTertiaryContainer
                        font.weight: 500
                    }

                    StyledText {
                        text: qsTr("Tap to open browser and authenticate")
                        color: Colours.palette.m3onTertiaryContainer
                        font.pointSize: Appearance.font.size.small
                        opacity: 0.8
                    }
                }

                MaterialIcon {
                    text: "open_in_new"
                    color: Colours.palette.m3onTertiaryContainer
                    font.pointSize: Appearance.font.size.normal
                }
            }
        }

        StyledListView {
            id: view

            model: ScriptModel {
                id: networkModel

                values: [...Network.networks].sort((a, b) => (b.active - a.active) || (b.isSaved - a.isSaved) || (b.strength - a.strength))
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacing.small / 2

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: view
            }

            delegate: StyledRect {
                id: network

                required property var modelData
                readonly property bool isActive: modelData.active
                readonly property bool isSecure: modelData.isSecure
                readonly property bool isSaved: modelData.isSaved
                readonly property bool isConnecting: Network.connecting && Network.lastConnectedSSID === modelData.ssid

                anchors.left: parent?.left
                anchors.right: parent?.right
                implicitHeight: networkInner.implicitHeight + Appearance.padding.normal * 2

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.session.nw.active === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Appearance.rounding.normal

                StateLayer {
                    id: stateLayer

                    function onClicked(): void {
                        root.session.nw.active = network.modelData;
                    }
                }

                RowLayout {
                    id: networkInner

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal

                    spacing: Appearance.spacing.normal

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2

                        radius: Appearance.rounding.normal
                        color: network.isActive ? Colours.palette.m3primaryContainer : network.isSaved ? Colours.palette.m3tertiaryContainer : network.isSecure ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

                        StyledRect {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.alpha(network.isActive ? Colours.palette.m3onPrimaryContainer : network.isSaved ? Colours.palette.m3onTertiaryContainer : network.isSecure ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface, stateLayer.pressed ? 0.1 : stateLayer.containsMouse ? 0.08 : 0)
                        }

                        CircularIndicator {
                            anchors.fill: parent
                            running: network.isConnecting
                        }

                        MaterialIcon {
                            id: icon

                            anchors.centerIn: parent
                            text: getWifiIcon(network.modelData.strength)
                            color: network.isActive ? Colours.palette.m3onPrimaryContainer : network.isSaved ? Colours.palette.m3onTertiaryContainer : network.isSecure ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.large
                            fill: network.isActive ? 1 : 0
                            opacity: network.isConnecting ? 0 : 1

                            function getWifiIcon(strength): string {
                                if (strength >= 80) return "signal_wifi_4_bar";
                                if (strength >= 60) return "network_wifi_3_bar";
                                if (strength >= 40) return "network_wifi_2_bar";
                                if (strength >= 20) return "network_wifi_1_bar";
                                return "signal_wifi_0_bar";
                            }

                            Behavior on fill {
                                Anim {}
                            }

                            Behavior on opacity {
                                Anim {}
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                Layout.fillWidth: true
                                text: network.modelData.ssid
                                elide: Text.ElideRight
                            }

                            MaterialIcon {
                                visible: network.isSaved
                                text: "bookmark"
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3tertiary
                            }

                            MaterialIcon {
                                visible: network.isSecure
                                text: "lock"
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3outline
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                let info = network.modelData.strength + "%" + (network.modelData.frequency ? " • " + (network.modelData.frequency > 5000 ? "5 GHz" : "2.4 GHz") : "");
                                if (network.isConnecting) info = qsTr("Connecting...");
                                else if (network.isActive) info += qsTr(" (Connected)");
                                else if (network.isSaved) info += qsTr(" (Saved)");
                                return info;
                            }
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledRect {
                        id: connectBtn

                        implicitWidth: implicitHeight
                        implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                        radius: Appearance.rounding.full
                        color: Qt.alpha(Colours.palette.m3primaryContainer, network.isActive ? 1 : 0)

                        CircularIndicator {
                            anchors.fill: parent
                            running: network.isConnecting
                        }

                        StateLayer {
                            color: network.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            disabled: network.isConnecting

                            function onClicked(): void {
                                if (network.isActive) {
                                    Network.disconnectFromNetwork();
                                } else if (network.isSaved) {
                                    Network.connectToNetwork(network.modelData.ssid, "");
                                } else if (network.isSecure) {
                                    root.session.nw.pendingNetwork = network.modelData;
                                    root.session.nw.connectDialogOpen = true;
                                } else {
                                    Network.connectToNetwork(network.modelData.ssid, "");
                                }
                            }
                        }

                        MaterialIcon {
                            id: connectIcon

                            anchors.centerIn: parent
                            animate: true
                            text: network.isActive ? "link_off" : network.isSecure && !network.isSaved ? "key" : "link"
                            color: network.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.normal
                            opacity: network.isConnecting ? 0 : 1

                            Behavior on opacity {
                                Anim {}
                            }
                        }
                    }
                }
            }
        }
    }

    // Dialog Overlay Container (outside ColumnLayout)
    Item {
        id: dialogOverlay

        anchors.fill: parent
        visible: root.session.nw.connectDialogOpen || root.session.nw.forgetDialogOpen || Network.warningMessage.length > 0
        z: 100

        // Scrim background
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, (root.session.nw.connectDialogOpen || root.session.nw.forgetDialogOpen) ? 0.5 : 0)

            Behavior on color {
                CAnim {}
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.session.nw.connectDialogOpen = false;
                    root.session.nw.forgetDialogOpen = false;
                    root.session.nw.pendingPassword = "";
                    Network.clearWarning();
                }
            }
        }

        // Warning/Info Toast Popup
        Elevation {
            id: warningElevation
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.padding.large
            width: warningPopup.width
            height: warningPopup.height
            radius: warningPopup.radius
            level: 2
            opacity: Network.warningMessage.length > 0 ? 1 : 0
            scale: Network.warningMessage.length > 0 ? 1 : 0.8

            Behavior on opacity {
                Anim { duration: Appearance.anim.durations.normal }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
            }
        }

        StyledClippingRect {
            id: warningPopup

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.padding.large
            implicitWidth: Math.min(360, root.width - Appearance.padding.large * 4)
            implicitHeight: warningContent.implicitHeight + Appearance.padding.normal * 2

            radius: Appearance.rounding.normal
            color: {
                if (Network.warningType === "error") return Colours.palette.m3errorContainer;
                if (Network.warningType === "success") return Colours.palette.m3primaryContainer;
                if (Network.warningType === "warning") return Colours.palette.m3tertiaryContainer;
                return Colours.palette.m3secondaryContainer;
            }
            opacity: Network.warningMessage.length > 0 ? 1 : 0
            scale: Network.warningMessage.length > 0 ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                Anim { duration: Appearance.anim.durations.normal }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
            }

            RowLayout {
                id: warningContent

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: {
                        if (Network.warningType === "error") return "error";
                        if (Network.warningType === "success") return "check_circle";
                        if (Network.warningType === "warning") return "warning";
                        return "info";
                    }
                    color: {
                        if (Network.warningType === "error") return Colours.palette.m3onErrorContainer;
                        if (Network.warningType === "success") return Colours.palette.m3onPrimaryContainer;
                        if (Network.warningType === "warning") return Colours.palette.m3onTertiaryContainer;
                        return Colours.palette.m3onSecondaryContainer;
                    }
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Network.warningMessage
                    color: {
                        if (Network.warningType === "error") return Colours.palette.m3onErrorContainer;
                        if (Network.warningType === "success") return Colours.palette.m3onPrimaryContainer;
                        if (Network.warningType === "warning") return Colours.palette.m3onTertiaryContainer;
                        return Colours.palette.m3onSecondaryContainer;
                    }
                    wrapMode: Text.WordWrap
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: closeWarningIcon.implicitHeight + Appearance.padding.smaller * 2
                    radius: Appearance.rounding.full
                    color: "transparent"

                    StateLayer {
                        function onClicked(): void {
                            Network.clearWarning();
                        }
                    }

                    MaterialIcon {
                        id: closeWarningIcon
                        anchors.centerIn: parent
                        text: "close"
                        color: {
                            if (Network.warningType === "error") return Colours.palette.m3onErrorContainer;
                            if (Network.warningType === "success") return Colours.palette.m3onPrimaryContainer;
                            if (Network.warningType === "warning") return Colours.palette.m3onTertiaryContainer;
                            return Colours.palette.m3onSecondaryContainer;
                        }
                        font.pointSize: Appearance.font.size.small
                    }
                }
            }
        }

        // Password Dialog
        Elevation {
            id: dialogElevation
            anchors.centerIn: parent
            width: dialog.width
            height: dialog.height
            radius: dialog.radius
            level: 3
            opacity: root.session.nw.connectDialogOpen ? 1 : 0
            scale: root.session.nw.connectDialogOpen ? 1 : 0.8

            Behavior on opacity {
                Anim { duration: Appearance.anim.durations.normal }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
            }
        }

        StyledClippingRect {
            id: dialog

            anchors.centerIn: parent
            implicitWidth: 380
            implicitHeight: 340

            radius: Appearance.rounding.large
            color: Colours.palette.m3surfaceContainerHigh
            opacity: root.session.nw.connectDialogOpen ? 1 : 0
            scale: root.session.nw.connectDialogOpen ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                Anim { duration: Appearance.anim.durations.normal }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
            }

            ColumnLayout {
                id: dialogContent

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.large

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "wifi_password"
                        font.pointSize: Appearance.font.size.extraLarge
                        color: Colours.palette.m3primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: qsTr("Connect to network")
                            font.pointSize: Appearance.font.size.large
                            font.weight: 500
                        }

                        StyledText {
                            text: root.session.nw.pendingNetwork?.ssid ?? ""
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                        }
                    }

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: closeDialogIcon.implicitHeight + Appearance.padding.smaller * 2
                        radius: Appearance.rounding.full
                        color: "transparent"

                        StateLayer {
                            function onClicked(): void {
                                root.session.nw.connectDialogOpen = false;
                                root.session.nw.pendingPassword = "";
                            }
                        }

                        MaterialIcon {
                            id: closeDialogIcon
                            anchors.centerIn: parent
                            text: "close"
                            color: Colours.palette.m3outline
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: networkInfoRow.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.small
                    color: Colours.tPalette.m3surfaceContainer

                    RowLayout {
                        id: networkInfoRow
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "lock"
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.session.nw.pendingNetwork?.security ?? qsTr("Secured")
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                        }

                        StyledText {
                            text: (root.session.nw.pendingNetwork?.strength ?? 0) + "%"
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: Appearance.spacing.small
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("Password")
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3outline
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: Appearance.rounding.small
                            color: Colours.tPalette.m3surfaceContainer
                            border.width: passwordInput.activeFocus ? 2 : 0
                            border.color: Colours.palette.m3primary

                            Behavior on border.width {
                                Anim { duration: Appearance.anim.durations.small }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.padding.normal
                                anchors.rightMargin: Appearance.padding.normal
                                spacing: Appearance.spacing.small

                                MaterialIcon {
                                    text: "password"
                                    color: passwordInput.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline
                                    font.pointSize: Appearance.font.size.normal
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                StyledTextField {
                                    id: passwordInput

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    placeholderText: qsTr("Enter password")
                                    echoMode: showPasswordBtn.showPassword ? TextInput.Normal : TextInput.Password
                                    text: root.session.nw.pendingPassword
                                    onTextChanged: root.session.nw.pendingPassword = text

                                    background: Item {}

                                    onAccepted: {
                                        if (text.length >= 8) {
                                            Network.connectToNewNetwork(root.session.nw.pendingNetwork.ssid, text);
                                            root.session.nw.connectDialogOpen = false;
                                            root.session.nw.pendingPassword = "";
                                        }
                                    }
                                }

                                StyledRect {
                                    id: showPasswordBtn

                                    property bool showPassword: false

                                    implicitWidth: implicitHeight
                                    implicitHeight: showPasswordIcon.implicitHeight + Appearance.padding.smaller * 2
                                    radius: Appearance.rounding.full
                                    color: "transparent"
                                    Layout.alignment: Qt.AlignVCenter

                                    StateLayer {
                                        function onClicked(): void {
                                            showPasswordBtn.showPassword = !showPasswordBtn.showPassword;
                                        }
                                    }

                                    MaterialIcon {
                                        id: showPasswordIcon
                                        anchors.centerIn: parent
                                        text: showPasswordBtn.showPassword ? "visibility_off" : "visibility"
                                        color: Colours.palette.m3outline
                                        font.pointSize: Appearance.font.size.normal
                                    }
                                }
                            }
                        }

                        StyledText {
                            visible: passwordInput.text.length > 0 && passwordInput.text.length < 8
                            text: qsTr("Password must be at least 8 characters")
                            color: Colours.palette.m3error
                            font.pointSize: Appearance.font.size.small
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    Item { Layout.fillWidth: true }

                    StyledRect {
                        implicitWidth: cancelBtnContent.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: cancelBtnContent.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.full
                        color: "transparent"

                        StateLayer {
                            function onClicked(): void {
                                root.session.nw.connectDialogOpen = false;
                                root.session.nw.pendingPassword = "";
                            }
                        }

                        RowLayout {
                            id: cancelBtnContent
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: qsTr("Cancel")
                                color: Colours.palette.m3primary
                            }
                        }
                    }

                    StyledRect {
                        implicitWidth: connectBtnContentDialog.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: connectBtnContentDialog.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.full
                        color: passwordInput.text.length >= 8 ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest
                        opacity: passwordInput.text.length >= 8 ? 1 : 0.5

                        Behavior on color {
                            CAnim {}
                        }

                        Behavior on opacity {
                            Anim {}
                        }

                        StateLayer {
                            color: Colours.palette.m3onPrimary
                            disabled: passwordInput.text.length < 8

                            function onClicked(): void {
                                if (passwordInput.text.length >= 8) {
                                    Network.connectToNewNetwork(root.session.nw.pendingNetwork.ssid, passwordInput.text);
                                    root.session.nw.connectDialogOpen = false;
                                    root.session.nw.pendingPassword = "";
                                }
                            }
                        }

                        RowLayout {
                            id: connectBtnContentDialog
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "wifi"
                                color: passwordInput.text.length >= 8 ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                            }

                            StyledText {
                                text: qsTr("Connect")
                                color: passwordInput.text.length >= 8 ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                            }
                        }
                    }
                }
            }
        }

        // Forget Confirmation Dialog
        Elevation {
            id: forgetDialogElevation
            anchors.centerIn: parent
            width: forgetDialog.width
            height: forgetDialog.height
            radius: forgetDialog.radius
            level: 3
            opacity: root.session.nw.forgetDialogOpen ? 1 : 0
            scale: root.session.nw.forgetDialogOpen ? 1 : 0.8

            Behavior on opacity {
                Anim { duration: Appearance.anim.durations.normal }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
            }
        }

        StyledClippingRect {
            id: forgetDialog

            anchors.centerIn: parent
            implicitWidth: 340
            implicitHeight: forgetDialogContent.implicitHeight + Appearance.padding.large * 2

            radius: Appearance.rounding.large
            color: Colours.palette.m3surfaceContainerHigh
            opacity: root.session.nw.forgetDialogOpen ? 1 : 0
            scale: root.session.nw.forgetDialogOpen ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                Anim { duration: Appearance.anim.durations.normal }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
            }

            ColumnLayout {
                id: forgetDialogContent

                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.large

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "delete_forever"
                        font.pointSize: Appearance.font.size.extraLarge
                        color: Colours.palette.m3error
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: qsTr("Forget network?")
                            font.pointSize: Appearance.font.size.large
                            font.weight: 500
                        }

                        StyledText {
                            text: root.session.nw.networkToForget?.ssid ?? root.session.nw.networkToForget?.name ?? ""
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                        }
                    }

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: closeForgetIcon.implicitHeight + Appearance.padding.smaller * 2
                        radius: Appearance.rounding.full
                        color: "transparent"

                        StateLayer {
                            function onClicked(): void {
                                root.session.nw.forgetDialogOpen = false;
                                root.session.nw.networkToForget = null;
                            }
                        }

                        MaterialIcon {
                            id: closeForgetIcon
                            anchors.centerIn: parent
                            text: "close"
                            color: Colours.palette.m3outline
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("This will remove saved credentials. You'll need to enter the password again to reconnect.")
                    color: Colours.palette.m3outline
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    Item { Layout.fillWidth: true }

                    StyledRect {
                        implicitWidth: keepBtnContent.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: keepBtnContent.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.full
                        color: "transparent"

                        StateLayer {
                            function onClicked(): void {
                                root.session.nw.forgetDialogOpen = false;
                                root.session.nw.networkToForget = null;
                            }
                        }

                        RowLayout {
                            id: keepBtnContent
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: qsTr("Keep")
                                color: Colours.palette.m3primary
                            }
                        }
                    }

                    StyledRect {
                        implicitWidth: forgetBtnContentDialog.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: forgetBtnContentDialog.implicitHeight + Appearance.padding.normal * 2
                        radius: Appearance.rounding.full
                        color: Colours.palette.m3error

                        StateLayer {
                            color: Colours.palette.m3onError

                            function onClicked(): void {
                                const networkName = root.session.nw.networkToForget?.ssid ?? root.session.nw.networkToForget?.name;
                                if (networkName) {
                                    Network.forgetNetwork(networkName);
                                }
                                root.session.nw.forgetDialogOpen = false;
                                root.session.nw.networkToForget = null;
                                root.session.nw.active = null;
                            }
                        }

                        RowLayout {
                            id: forgetBtnContentDialog
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "delete"
                                color: Colours.palette.m3onError
                            }

                            StyledText {
                                text: qsTr("Forget")
                                color: Colours.palette.m3onError
                            }
                        }
                    }
                }
            }
        }

        Connections {
            target: root.session.nw
            function onConnectDialogOpenChanged() {
                if (root.session.nw.connectDialogOpen) {
                    passwordInput.text = "";
                    passwordInput.forceActiveFocus();
                }
            }
        }
    }

    component ToggleButton: StyledRect {
        id: toggleBtn

        required property bool toggled
        property string icon
        property string label
        property string accent: "Secondary"

        function onClicked(): void {
        }

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

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
