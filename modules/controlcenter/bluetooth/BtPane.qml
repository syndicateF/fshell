pragma ComponentBehavior: Bound

import ".."
import qs.components.effects
import qs.components.containers
import qs.config
import Quickshell.Widgets
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent

    spacing: 0

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        DeviceList {
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

            // Horizontal sliding panes
            Item {
                id: horizontalPanes
                
                anchors.fill: parent
                clip: true
                
                // 0 = Settings, 1 = Details
                property int activePane: root.session.bt.active ? 1 : 0
                
                RowLayout {
                    id: paneRow
                    
                    spacing: 0
                    x: -horizontalPanes.activePane * horizontalPanes.width
                    
                    // Pane 0: Settings
                    Item {
                        Layout.preferredWidth: horizontalPanes.width
                        Layout.preferredHeight: horizontalPanes.height
                        
                        StyledFlickable {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            flickableDirection: Flickable.VerticalFlick
                            contentHeight: settingsInner.height

                            Settings {
                                id: settingsInner

                                anchors.left: parent.left
                                anchors.right: parent.right
                                session: root.session
                            }
                        }
                    }
                    
                    // Pane 1: Details
                    Item {
                        Layout.preferredWidth: horizontalPanes.width
                        Layout.preferredHeight: horizontalPanes.height
                        
                        Loader {
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large * 2
                            
                            active: root.session.bt.active !== null
                            asynchronous: true
                            
                            sourceComponent: Details {
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

    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
