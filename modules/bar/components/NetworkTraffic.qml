pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Network Traffic Indicator - displays upload/download speed in bar
// Style: rotated 90° vertical text with unit indicator (PowerMode style)
StyledRect {
    id: root

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: mainLayout.implicitHeight + Config.bar.sizes.itemPadding * 2
    
    radius: Appearance.rounding.small
    color: Colours.palette.m3surfaceContainerHigh

    // Format with unit
    function formatSpeed(bytesPerSec: real): string {
        if (bytesPerSec >= 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
        } else if (bytesPerSec >= 1024) {
            return (bytesPerSec / 1024).toFixed(0) + " KB/s"
        } else {
            return bytesPerSec.toFixed(0) + " B/s"
        }
    }

    Column {
        id: mainLayout
        anchors.centerIn: parent
        spacing: Appearance.spacing.smaller

        // Upload section
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0 // hapus aja 0 lebih baik

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "arrow_upward"
                color: Colours.palette.m3primary
                font.pointSize: Config.bar.sizes.materialIconSize
            }

            // Upload label - rotated 90° (PowerMode style)
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: uploadLabel.implicitHeight
                height: Math.min(uploadLabel.implicitWidth, 60)
                
                Text {
                    id: uploadLabel
                    text: root.formatSpeed(Network.uploadSpeed)
                    font.pixelSize: 13
                    font.family: Appearance.font.family.sans
                    font.hintingPreference: Font.PreferDefaultHinting
                    font.variableAxes: ({ "wght": Config.bar.sizes.textWeight, "wdth": Config.bar.sizes.textWidth })
                    color: Colours.palette.m3primary
                    renderType: Text.NativeRendering
                    
                    transform: [
                        Rotation {
                            angle: 90
                            origin.x: uploadLabel.implicitHeight / 2
                            origin.y: uploadLabel.implicitHeight / 2
                        }
                    ]
                }
            }
        }

        // Divider
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Config.bar.sizes.innerWidth - Appearance.padding.normal * 2
            height: 1
            // color: Colours.palette.m3outlineVariant
            color: Colours.palette.m3primary
            opacity: 0.5
        }

        // Download section
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0 // sama ini juga 0 lwbih mantep

            // Download label - rotated 90° (PowerMode style)
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: downloadLabel.implicitHeight
                height: Math.min(downloadLabel.implicitWidth, 60)
                
                Text {
                    id: downloadLabel
                    text: root.formatSpeed(Network.downloadSpeed)
                    font.pixelSize: 13
                    font.family: Appearance.font.family.sans
                    font.hintingPreference: Font.PreferDefaultHinting
                    font.variableAxes: ({ "wght": Config.bar.sizes.textWeight, "wdth": Config.bar.sizes.textWidth })
                    color: Colours.palette.m3primary
                    renderType: Text.NativeRendering
                    
                    transform: [
                        Rotation {
                            angle: 90
                            origin.x: downloadLabel.implicitHeight / 2
                            origin.y: downloadLabel.implicitHeight / 2
                        }
                    ]
                }
            }

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "arrow_downward"
                color: Colours.palette.m3primary
                font.pointSize: Config.bar.sizes.materialIconSize
            }
        }
    }
}
