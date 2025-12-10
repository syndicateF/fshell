pragma ComponentBehavior: Bound

import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts
    readonly property int vPadding: 28

    // Expose repeaters untuk checkPopout
    readonly property var allRepeaters: [topRepeater, centerRepeater, bottomRepeater]

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (const rep of allRepeaters) {
            for (let i = 0; i < rep.count; i++) {
                const item = rep.itemAt(i);
                if (item?.enabled && item.entryId === "tray") {
                    item.item.expanded = false;
                }
            }
        }
    }

    function findItemAtY(y: real): Item {
        // Check semua section untuk cari item di posisi y
        const sections = [topSection, centerSection, bottomSection];
        for (const section of sections) {
            const localY = mapToItem(section, 0, y).y;
            if (localY >= 0 && localY <= section.height) {
                const child = section.childAt(section.width / 2, localY);
                if (child && child.entryId !== undefined) {
                    return child;
                }
            }
        }
        return null;
    }

    function checkPopout(y: real): void {
        const ch = findItemAtY(y);

        if (ch?.entryId !== "tray")
            closeTray();

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;
        const top = ch.mapToItem(root, 0, 0).y;
        const item = ch.item;
        const itemHeight = item.implicitHeight;

        if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const items = item.items;
            const icon = items.childAt(items.width / 2, mapToItem(items, 0, y).y);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "tray" && Config.bar.popouts.tray) {
            if (!Config.bar.tray.compact || (item.expanded && !item.expandIcon.contains(mapToItem(item.expandIcon, item.implicitWidth / 2, y)))) {
                const index = Math.floor(((y - top - item.padding * 2 + item.spacing) / item.layout.implicitHeight) * item.items.count);
                const trayItem = item.items.itemAt(index);
                if (trayItem) {
                    popouts.currentName = `traymenu${index}`;
                    popouts.currentCenter = Qt.binding(() => trayItem.mapToItem(root, 0, trayItem.implicitHeight / 2).y);
                    popouts.hasCurrent = true;
                } else {
                    popouts.hasCurrent = false;
                }
            } else {
                popouts.hasCurrent = false;
                item.expanded = true;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow) {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = item.mapToItem(root, 0, itemHeight / 2).y;
            popouts.hasCurrent = true;
        } else if (id === "dashboardIcons") {
            const items = item.items;
            const icon = items.childAt(items.width / 2, mapToItem(items, 0, y).y);
            if (icon && icon.name) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            } else {
                const dashPopouts = ["dash", "media", "performance", "bluetooth"];
                if (!dashPopouts.includes(popouts.currentName)) {
                    popouts.hasCurrent = false;
                }
            }
        } else if ((id === "networkIcon" || id === "networkTraffic") && Config.bar.popouts.statusIcons) {
            // Network icon + traffic indicator - both trigger network popout
            // Find the combined center between networkTraffic and networkIcon
            let combinedTop = Infinity;
            let combinedBottom = 0;
            
            for (const rep of allRepeaters) {
                for (let i = 0; i < rep.count; i++) {
                    const entry = rep.itemAt(i);
                    if (entry?.enabled && (entry.entryId === "networkIcon" || entry.entryId === "networkTraffic")) {
                        const entryTop = entry.item.mapToItem(root, 0, 0).y;
                        const entryBottom = entryTop + entry.item.implicitHeight;
                        combinedTop = Math.min(combinedTop, entryTop);
                        combinedBottom = Math.max(combinedBottom, entryBottom);
                    }
                }
            }
            
            popouts.currentName = "network";
            popouts.currentCenter = (combinedTop + combinedBottom) / 2;
            popouts.hasCurrent = true;
        } else if (id === "powerMode" && Config.bar.popouts.statusIcons) {
            // PowerMode popout
            popouts.currentName = "powermode";
            popouts.currentCenter = item.mapToItem(root, 0, itemHeight / 2).y;
            popouts.hasCurrent = true;
        }
    }

    function handleWheel(y: real, angleDelta: point): void {
        const ch = findItemAtY(y);
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            const mon = (Config.bar.workspaces.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(`togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || (Config.bar.workspaces.perMonitorWorkspaces ? mon.activeWorkspace?.id : Hypr.activeWsId) > 1)
                Hypr.dispatch(`workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (y < screen.height / 2 && Config.bar.scrollActions.volume) {
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + 0.1);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - 0.1);
        }
    }

    // TOP SECTION - anchored ke atas
    ColumnLayout {
        id: topSection
        anchors.top: parent.top
        anchors.topMargin: root.vPadding
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Appearance.spacing.normal

        Repeater {
            id: topRepeater
            model: Config.bar.topEntries
            delegate: entryDelegate
        }
    }

    // CENTER SECTION - anchored ke tengah
    ColumnLayout {
        id: centerSection
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        Repeater {
            id: centerRepeater
            model: Config.bar.centerEntries
            delegate: entryDelegate
        }
    }

    // BOTTOM SECTION - anchored ke bawah
    ColumnLayout {
        id: bottomSection
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.vPadding
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Appearance.spacing.normal

        Repeater {
            id: bottomRepeater
            model: Config.bar.bottomEntries
            delegate: entryDelegate
        }
    }

    // Shared delegate component
    Component {
        id: entryDelegate

        Loader {
            id: entryLoader

            required property var modelData
            required property int index

            readonly property bool enabled: modelData.enabled
            readonly property string entryId: modelData.id

            Layout.alignment: Qt.AlignHCenter
            visible: enabled
            active: enabled

            sourceComponent: {
                switch (entryId) {
                    case "logo": return logoComp
                    case "workspaces": return workspacesComp
                    case "activeWindow": return activeWindowComp
                    case "dashboardIcons": return dashboardIconsComp
                    case "tray": return trayComp
                    case "clock": return clockComp
                    case "statusIcons": return statusIconsComp
                    case "power": return powerComp
                    case "networkIcon": return networkIconComp
                    case "networkTraffic": return networkTrafficComp
                    case "batteryIcon": return batteryIconComp
                    case "powerMode": return powerModeComp
                    default: return null
                }
            }
        }
    }

    // Component definitions
    Component {
        id: logoComp
        OsIcon {}
    }

    Component {
        id: workspacesComp
        Workspaces {
            screen: root.screen
        }
    }

    Component {
        id: activeWindowComp
        WindowList {
            bar: root
            screen: root.screen
        }
    }

    Component {
        id: dashboardIconsComp
        DashboardIcons {
            bar: root
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }

    Component {
        id: trayComp
        Tray {}
    }

    Component {
        id: clockComp
        Clock {}
    }

    Component {
        id: statusIconsComp
        StatusIcons {}
    }

    Component {
        id: powerComp
        Power {
            visibilities: root.visibilities
        }
    }

    Component {
        id: networkIconComp
        NetworkIcon {}
    }

    Component {
        id: networkTrafficComp
        NetworkTraffic {}
    }

    Component {
        id: batteryIconComp
        BatteryIcon {}
    }

    Component {
        id: powerModeComp
        PowerMode {}
    }
}
