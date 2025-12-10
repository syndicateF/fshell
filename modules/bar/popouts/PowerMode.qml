pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell.Services.UPower
import QtQuick

// PowerMode popout - power profile switcher dengan info
Column {
    id: root

    spacing: Appearance.spacing.normal
    width: 220

    // Current profile name with icon
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const p = PowerProfiles.profile;
                if (p === PowerProfile.PowerSaver) return "energy_savings_leaf";
                if (p === PowerProfile.Performance) return "rocket_launch";
                return "balance";
            }
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.large
            fill: 1
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const p = PowerProfiles.profile;
                if (p === PowerProfile.PowerSaver) return "Power Saver";
                if (p === PowerProfile.Performance) return "Performance";
                return "Balanced";
            }
            font.weight: Font.Medium
            font.pointSize: Appearance.font.size.normal
        }
    }

    // Description based on current mode
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: {
            const p = PowerProfiles.profile;
            if (p === PowerProfile.PowerSaver) 
                return "Reduces performance to extend battery life";
            if (p === PowerProfile.Performance) 
                return "Maximum performance, higher power consumption";
            return "Optimal balance between performance and battery";
        }
        font.pointSize: Appearance.font.size.smaller
        color: Colours.palette.m3onSurfaceVariant
    }

    // Degradation warning
    Loader {
        anchors.horizontalCenter: parent.horizontalCenter

        active: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
        asynchronous: true

        height: active ? (item?.implicitHeight ?? 0) : 0

        sourceComponent: StyledRect {
            implicitWidth: child.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: child.implicitHeight + Appearance.padding.smaller * 2

            color: Colours.palette.m3error
            radius: Config.border.rounding

            Column {
                id: child

                anchors.centerIn: parent

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Performance Degraded")
                        color: Colours.palette.m3onError
                        font.family: Appearance.font.family.mono
                        font.weight: 500
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: PerformanceDegradationReason.toString(PowerProfiles.degradationReason)
                    color: Colours.palette.m3onError
                    font.pointSize: Appearance.font.size.smaller
                }
            }
        }
    }

    // Profile selector
    StyledRect {
        id: profiles

        property string current: {
            const p = PowerProfiles.profile;
            if (p === PowerProfile.PowerSaver)
                return saver.icon;
            if (p === PowerProfile.Performance)
                return perf.icon;
            return balance.icon;
        }

        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: saver.implicitWidth + balance.implicitWidth + perf.implicitWidth + Appearance.padding.normal * 2 + Appearance.spacing.large * 2
        implicitHeight: Math.max(saver.implicitHeight, balance.implicitHeight, perf.implicitHeight) + Appearance.padding.small * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        StyledRect {
            id: indicator

            color: Colours.palette.m3primary
            radius: Appearance.rounding.full
            state: profiles.current

            states: [
                State {
                    name: saver.icon

                    Fill {
                        item: saver
                    }
                },
                State {
                    name: balance.icon

                    Fill {
                        item: balance
                    }
                },
                State {
                    name: perf.icon

                    Fill {
                        item: perf
                    }
                }
            ]

            transitions: Transition {
                AnchorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        }

        Profile {
            id: saver

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Appearance.padding.small

            profile: PowerProfile.PowerSaver
            icon: "energy_savings_leaf"
        }

        Profile {
            id: balance

            anchors.centerIn: parent

            profile: PowerProfile.Balanced
            icon: "balance"
        }

        Profile {
            id: perf

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Appearance.padding.small

            profile: PowerProfile.Performance
            icon: "rocket_launch"
        }
    }

    component Fill: AnchorChanges {
        required property Item item

        target: indicator
        anchors.left: item.left
        anchors.right: item.right
        anchors.top: item.top
        anchors.bottom: item.bottom
    }

    component Profile: Item {
        required property string icon
        required property int profile

        implicitWidth: iconItem.implicitHeight + Appearance.padding.small * 2
        implicitHeight: iconItem.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            radius: Appearance.rounding.full
            color: profiles.current === parent.icon ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            function onClicked(): void {
                PowerProfiles.profile = parent.profile;
            }
        }

        MaterialIcon {
            id: iconItem

            anchors.centerIn: parent

            text: parent.icon
            font.pointSize: Appearance.font.size.large
            color: profiles.current === text ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            fill: profiles.current === text ? 1 : 0

            Behavior on fill {
                Anim {}
            }
        }
    }
}
