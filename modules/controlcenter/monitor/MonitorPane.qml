pragma ComponentBehavior: Bound

import ".."
import qs.components
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

    // Enable lazy loading when this pane becomes visible
    Component.onCompleted: Monitors.isActive = true
    Component.onDestruction: Monitors.isActive = false

    // Left panel - Monitor List
    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 380
        Layout.fillHeight: true

        MonitorList {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

            session: root.session
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    // Right panel - Settings/Details
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

            // Horizontal sliding panes - same pattern as vertical Panes.qml
            Item {
                id: horizontalPanes
                
                anchors.fill: parent
                clip: true
                
                // 0 = GlobalInfo, 1 = MonitorSettings
                property int activePane: Monitors.selectedMonitor ? 1 : 0
                
                RowLayout {
                    id: paneRow
                    
                    spacing: 0
                    x: -horizontalPanes.activePane * horizontalPanes.width
                    
                    // Pane 0: Global Info
                    Item {
                        Layout.preferredWidth: horizontalPanes.width
                        Layout.preferredHeight: horizontalPanes.height
                        
                        StyledFlickable {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            flickableDirection: Flickable.VerticalFlick
                            contentHeight: globalInfoInner.height

                            GlobalInfo {
                                id: globalInfoInner

                                anchors.left: parent.left
                                anchors.right: parent.right
                                session: root.session
                            }
                        }
                    }
                    
                    // Pane 1: Monitor Settings
                    Item {
                        Layout.preferredWidth: horizontalPanes.width
                        Layout.preferredHeight: horizontalPanes.height
                        
                        Loader {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            
                            active: Monitors.selectedMonitor !== null
                            asynchronous: true
                            
                            sourceComponent: MonitorSettings {
                                anchors.fill: parent
                                session: root.session
                            }
                        }
                    }
                    
                    Behavior on x {
                        Anim {}
                    }
                }
            }
        }

        InnerBorder {
            id: rightBorder
            leftThickness: Appearance.padding.normal / 2
        }

        // Confirmation Dialog Overlay
        Item {
            id: confirmDialogOverlay
            
            anchors.fill: parent
            visible: Monitors.showConfirmDialog
            z: 100
            
            // Scrim background
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.palette.m3scrim, Monitors.showConfirmDialog ? 0.5 : 0)
                
                Behavior on color {
                    CAnim {}
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: Monitors.cancelAction()
                }
            }
            
            // Dialog
            Elevation {
                anchors.centerIn: parent
                width: confirmDialogContent.width
                height: confirmDialogContent.height
                radius: confirmDialogContent.radius
                level: 3
                opacity: Monitors.showConfirmDialog ? 1 : 0
                scale: Monitors.showConfirmDialog ? 1 : 0.8
                
                Behavior on opacity {
                    NumberAnimation { duration: Appearance.anim.durations.normal }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }
            }
            
            StyledClippingRect {
                id: confirmDialogContent
                
                anchors.centerIn: parent
                implicitWidth: Math.min(400, parent.width - Appearance.padding.large * 4)
                implicitHeight: dialogLayout.implicitHeight + Appearance.padding.large * 2
                
                radius: Appearance.rounding.large
                color: Colours.palette.m3surfaceContainerHigh
                opacity: Monitors.showConfirmDialog ? 1 : 0
                scale: Monitors.showConfirmDialog ? 1 : 0.8
                visible: opacity > 0
                
                Behavior on opacity {
                    NumberAnimation { duration: Appearance.anim.durations.normal }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }
                
                ColumnLayout {
                    id: dialogLayout
                    
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal
                    
                    // Icon
                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (Monitors.confirmDialogType === "danger") return "error";
                            if (Monitors.confirmDialogType === "warning") return "warning";
                            return "info";
                        }
                        color: {
                            if (Monitors.confirmDialogType === "danger") return Colours.palette.m3error;
                            if (Monitors.confirmDialogType === "warning") return Colours.palette.m3tertiary;
                            return Colours.palette.m3primary;
                        }
                        font.pointSize: Appearance.font.size.extraLarge * 2
                    }
                    
                    // Title
                    StyledText {
                        Layout.fillWidth: true
                        text: Monitors.confirmDialogTitle
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 600
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                    
                    // Message
                    StyledText {
                        Layout.fillWidth: true
                        text: Monitors.confirmDialogMessage
                        font.pointSize: Appearance.font.size.normal
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
                                    Monitors.cancelAction();
                                }
                            }
                            
                            StyledText {
                                anchors.centerIn: parent
                                text: qsTr("Cancel")
                            }
                        }
                        
                        // Confirm button
                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            
                            radius: Appearance.rounding.full
                            color: {
                                if (Monitors.confirmDialogType === "danger") return Colours.palette.m3error;
                                if (Monitors.confirmDialogType === "warning") return Colours.palette.m3tertiary;
                                return Colours.palette.m3primary;
                            }
                            
                            StateLayer {
                                color: {
                                    if (Monitors.confirmDialogType === "danger") return Colours.palette.m3onError;
                                    if (Monitors.confirmDialogType === "warning") return Colours.palette.m3onTertiary;
                                    return Colours.palette.m3onPrimary;
                                }
                                function onClicked(): void {
                                    Monitors.confirmAction();
                                }
                            }
                            
                            StyledText {
                                anchors.centerIn: parent
                                text: qsTr("Confirm")
                                color: {
                                    if (Monitors.confirmDialogType === "danger") return Colours.palette.m3onError;
                                    if (Monitors.confirmDialogType === "warning") return Colours.palette.m3onTertiary;
                                    return Colours.palette.m3onPrimary;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Preview Countdown Overlay
        Item {
            id: previewOverlay
            
            anchors.fill: parent
            visible: Monitors.inPreviewMode
            z: 200
            
            // Scrim background
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.palette.m3scrim, Monitors.inPreviewMode ? 0.7 : 0)
                
                Behavior on color {
                    CAnim {}
                }
            }
            
            // Preview Dialog
            Elevation {
                anchors.centerIn: parent
                width: previewDialogContent.width
                height: previewDialogContent.height
                radius: previewDialogContent.radius
                level: 4
                opacity: Monitors.inPreviewMode ? 1 : 0
                scale: Monitors.inPreviewMode ? 1 : 0.8
                
                Behavior on opacity {
                    NumberAnimation { duration: Appearance.anim.durations.normal }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }
            }
            
            StyledClippingRect {
                id: previewDialogContent
                
                anchors.centerIn: parent
                implicitWidth: Math.min(420, parent.width - Appearance.padding.large * 4)
                implicitHeight: previewLayout.implicitHeight + Appearance.padding.large * 2
                
                radius: Appearance.rounding.large
                color: Colours.palette.m3surfaceContainerHigh
                opacity: Monitors.inPreviewMode ? 1 : 0
                scale: Monitors.inPreviewMode ? 1 : 0.8
                visible: opacity > 0
                
                Behavior on opacity {
                    NumberAnimation { duration: Appearance.anim.durations.normal }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }
                
                ColumnLayout {
                    id: previewLayout
                    
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.large
                    
                    // Countdown circle
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 100
                        
                        // Background circle
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 6
                            border.color: Colours.palette.m3surfaceContainerHighest
                        }
                        
                        // Progress circle (using Canvas for arc)
                        Canvas {
                            id: countdownCanvas
                            anchors.fill: parent
                            
                            property real progress: Monitors.previewCountdown / 15
                            
                            onProgressChanged: requestPaint()
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                
                                var centerX = width / 2;
                                var centerY = height / 2;
                                var radius = width / 2 - 3;
                                
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * progress), false);
                                ctx.lineWidth = 6;
                                ctx.strokeStyle = Colours.palette.m3primary;
                                ctx.lineCap = "round";
                                ctx.stroke();
                            }
                        }
                        
                        // Countdown number
                        StyledText {
                            anchors.centerIn: parent
                            text: Monitors.previewCountdown
                            font.pointSize: Appearance.font.size.extraLarge * 1.5
                            font.weight: 700
                            color: Colours.palette.m3primary
                        }
                    }
                    
                    // Title
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Keep these display settings?")
                        font.pointSize: Appearance.font.size.larger
                        font.weight: 600
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                    
                    // Message
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Your display settings have been changed. If you don't respond, the previous settings will be restored in %1 seconds.").arg(Monitors.previewCountdown)
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                    
                    // Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.small
                        spacing: Appearance.spacing.normal
                        
                        // Revert button
                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3errorContainer
                            
                            StateLayer {
                                color: Colours.palette.m3onErrorContainer
                                function onClicked(): void {
                                    Monitors.revertPreview();
                                }
                            }
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.small
                                
                                MaterialIcon {
                                    text: "undo"
                                    color: Colours.palette.m3onErrorContainer
                                }
                                
                                StyledText {
                                    text: qsTr("Revert")
                                    color: Colours.palette.m3onErrorContainer
                                    font.weight: 500
                                }
                            }
                        }
                        
                        // Keep button
                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3primary
                            
                            StateLayer {
                                color: Colours.palette.m3onPrimary
                                function onClicked(): void {
                                    Monitors.keepPreview();
                                }
                            }
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.small
                                
                                MaterialIcon {
                                    text: "check"
                                    color: Colours.palette.m3onPrimary
                                }
                                
                                StyledText {
                                    text: qsTr("Keep Changes")
                                    color: Colours.palette.m3onPrimary
                                    font.weight: 500
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
