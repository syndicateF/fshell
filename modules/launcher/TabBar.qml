pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    required property int currentTab
    signal tabChanged(int index)

    readonly property var tabs: [
        { name: Config.launcher.tabs.apps.name, icon: Config.launcher.tabs.apps.icon },
        { name: Config.launcher.tabs.commands.name, icon: Config.launcher.tabs.commands.icon },
        { name: Config.launcher.tabs.calculator.name, icon: Config.launcher.tabs.calculator.icon },
        { name: Config.launcher.tabs.schemes.name, icon: Config.launcher.tabs.schemes.icon },
        { name: Config.launcher.tabs.wallpapers.name, icon: Config.launcher.tabs.wallpapers.icon },
        { name: Config.launcher.tabs.variants.name, icon: Config.launcher.tabs.variants.icon }
    ]

    implicitHeight: tabRow.implicitHeight + Appearance.padding.small * 2
    implicitWidth: tabRow.implicitWidth + Appearance.padding.normal * 2

    // Container untuk Row + Indicator (centered as a unit)
    Item {
        id: tabContainer

        anchors.centerIn: parent
        implicitWidth: tabRow.implicitWidth
        implicitHeight: tabRow.implicitHeight

        // Trigger to force binding re-evaluation when Repeater is ready
        property bool repeaterReady: false

        // Background indicator - position relative to tabContainer
        StyledRect {
            id: activeIndicator

            // Direct binding - repeaterReady forces re-evaluation
            x: tabContainer.repeaterReady, tabRepeater.itemAt(root.currentTab)?.x ?? 0
            y: 0
            width: tabContainer.repeaterReady, tabRepeater.itemAt(root.currentTab)?.width ?? 0
            height: tabRow.height

            radius: Config.border.rounding
            color: Colours.palette.m3primary

            Behavior on x {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            Behavior on width {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        }

        // Tab buttons row - x=0 relatif ke container
        Row {
            id: tabRow
            spacing: Appearance.spacing.smaller

            Repeater {
                id: tabRepeater
                model: root.tabs

                // Mark ready when last item is added
                onItemAdded: (index, item) => {
                    if (index === root.tabs.length - 1) {
                        tabContainer.repeaterReady = true;
                    }
                }

                Item {
                    id: tabBtn

                    required property var modelData
                    required property int index

                    readonly property bool isActive: root.currentTab === index

                    implicitWidth: content.implicitWidth + Appearance.padding.normal * 2
                    implicitHeight: content.implicitHeight + Appearance.padding.small * 2

                    Row {
                        id: content
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.smaller

                        MaterialIcon {
                            text: tabBtn.modelData.icon
                            color: tabBtn.isActive ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            font.pixelSize: 15
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color {
                                ColorAnimation { duration: Appearance.anim.durations.normal }
                            }
                        }

                        Text {
                            text: tabBtn.modelData.name
                            color: tabBtn.isActive ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            font.pixelSize: 15
                            font.family: Appearance.font.family.sans
                            font.hintingPreference: Font.PreferDefaultHinting
                            font.variableAxes: ({ "wght": 450, "wdth": 100 })
                            renderType: Text.NativeRendering
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color {
                                ColorAnimation { duration: Appearance.anim.durations.normal }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabChanged(tabBtn.index)
                    }
                }
            }
        }
    }

    // Hint text
    StyledText {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Appearance.padding.small
        text: "Shift+</>"
        font.pointSize: Appearance.font.size.smaller
        color: Colours.palette.m3outline
        opacity: 0.5
    }
}
