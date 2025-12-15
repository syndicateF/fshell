pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

// PowerMode popout - power profile switcher
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
                const p = Hardware.customPowerMode;
                if (p === "power-saver") return "energy_savings_leaf";
                if (p === "performance") return "rocket_launch";
                return "balance";
            }
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.large
            fill: 1
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const p = Hardware.customPowerMode;
                if (p === "power-saver") return "Power Saver";
                if (p === "performance") return "Performance";
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
            const p = Hardware.customPowerMode;
            if (p === "power-saver") 
                return "Power saving mode (safe - no freeze risk)";
            if (p === "performance") 
                return "Maximum performance, higher power consumption";
            return "Balanced mode (safe - no freeze risk)";
        }
        font.pointSize: Appearance.font.size.smaller
        color: Colours.palette.m3onSurfaceVariant
    }

    // Safe mode indicator for AMD systems
    Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        active: Hardware.cpuDriver === "amd-pstate-epp" || Hardware.cpuDriver === "amd-pstate"
        asynchronous: true
        height: active ? (item?.implicitHeight ?? 0) : 0

        sourceComponent: StyledRect {
            implicitWidth: safeRow.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: safeRow.implicitHeight + Appearance.padding.smaller * 2
            color: Qt.alpha(Colours.palette.m3tertiary, 0.2)
            radius: Config.border.rounding

            Row {
                id: safeRow
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "verified_user"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.small
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("AMD Safe Mode")
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.smaller
                }
            }
        }
    }

    // Profile selector
    StyledRect {
        id: profiles

        property string current: {
            const p = Hardware.customPowerMode;
            if (p === "power-saver")
                return saver.icon;
            if (p === "performance")
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

            mode: "power-saver"
            icon: "energy_savings_leaf"
        }

        Profile {
            id: balance

            anchors.centerIn: parent

            mode: "balanced"
            icon: "balance"
        }

        Profile {
            id: perf

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Appearance.padding.small

            mode: "performance"
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
        required property string mode

        implicitWidth: iconItem.implicitHeight + Appearance.padding.small * 2
        implicitHeight: iconItem.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            radius: Appearance.rounding.full
            color: profiles.current === parent.icon ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            function onClicked(): void {
                Hardware.setCustomPowerMode(parent.mode);
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
