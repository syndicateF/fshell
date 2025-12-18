pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Dashboard Icons + Bluetooth - gabung dalam 1 bg dengan divider
// Uses HOVER to show popouts (like StatusIcons)
StyledRect {
    id: root

    required property Item bar
    required property PersistentProperties visibilities
    required property var popouts

    readonly property alias items: iconsColumn
    property color colour: Colours.palette.m3yellow

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding
    
    clip: true
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: iconsColumn.implicitHeight + Config.bar.sizes.itemPadding * 2

    ColumnLayout {
        id: iconsColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.bar.sizes.itemPadding

        spacing: 0

        // Dashboard icons section
        WrappedLoader {
            name: "dash"
            active: true

            sourceComponent: MaterialIcon {
                text: "dashboard"
                color: root.colour
                font.pointSize: Config.bar.sizes.font.materialIcon
            }
        }

        WrappedLoader {
            name: "media"
            active: true

            sourceComponent: MaterialIcon {
                text: "music_note"
                color: root.colour
                font.pointSize: Config.bar.sizes.font.materialIcon
            }
        }

        WrappedLoader {
            name: "performance"
            active: true

            sourceComponent: MaterialIcon {
                text: "monitoring"
                color: root.colour
                font.pointSize: Config.bar.sizes.font.materialIcon
            }
        }

        // Divider - seperti di WindowList
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.spacing.small
            Layout.bottomMargin: Appearance.spacing.small
            visible: Config.bar.status.showBluetooth
            width: Config.bar.sizes.innerWidth * 0.5
            height: 1
            // color: Colours.palette.m3outlineVariant
            color: root.colour
            opacity: 0.5
        }

        // Bluetooth section
        WrappedLoader {
            Layout.preferredHeight: implicitHeight
            name: "bluetooth"
            active: Config.bar.status.showBluetooth

            sourceComponent: ColumnLayout {
                // spacing: Appearance.spacing.smaller / 2

                // Bluetooth icon
                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    animate: true
                    text: {
                        if (!Bluetooth.defaultAdapter?.enabled)
                            return "bluetooth_disabled";
                        if (Bluetooth.devices.values.some(d => d.connected))
                            return "bluetooth_connected";
                        return "bluetooth";
                    }
                    color: root.colour
                    font.pointSize: Config.bar.sizes.font.materialIcon
                }

                // Connected bluetooth devices
                Repeater {
                    model: ScriptModel {
                        values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected)
                    }

                    MaterialIcon {
                        id: device

                        required property BluetoothDevice modelData

                        Layout.alignment: Qt.AlignHCenter
                        animate: true
                        text: Icons.getBluetoothIcon(modelData?.icon)
                        color: root.colour
                        fill: 1
                        font.pointSize: Config.bar.sizes.font.materialIcon

                        SequentialAnimation on opacity {
                            running: device.modelData?.state !== BluetoothDeviceState.Connected
                            alwaysRunToEnd: true
                            loops: Animation.Infinite

                            Anim {
                                from: 1
                                to: 0
                                duration: Appearance.anim.durations.large
                                easing.bezierCurve: Appearance.anim.curves.standardAccel
                            }
                            Anim {
                                from: 0
                                to: 1
                                duration: Appearance.anim.durations.large
                                easing.bezierCurve: Appearance.anim.curves.standardDecel
                            }
                        }
                    }
                }
            }

            Behavior on Layout.preferredHeight {
                Anim {}
            }
        }
    }

    component WrappedLoader: Loader {
        required property string name

        Layout.alignment: Qt.AlignHCenter
        asynchronous: true
        visible: active
    }
}
