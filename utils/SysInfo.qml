pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string osName
    property string osPrettyName
    property string osId
    property list<string> osIdLike
    property string osLogo: Qt.resolvedUrl(`${Quickshell.shellDir}/assets/logo.svg`)
    property bool isDefaultLogo: true

    property string uptime
    readonly property string user: Quickshell.env("USER")
    readonly property string wm: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP")
    readonly property string shell: Quickshell.env("SHELL").split("/").pop()
    property string kernelVersion: ""

    FileView {
        id: kernelFile
        path: "/proc/version"
        onLoaded: {
            // Extract kernel version from /proc/version (e.g., "Linux version 6.17.9-arch1-1 ...")
            const match = text().match(/Linux version (\S+)/);
            root.kernelVersion = match ? match[1] : "Unknown";
        }
    }

    FileView {
        id: osRelease

        path: "/etc/os-release"
        onLoaded: {
            const lines = text().split("\n");

            const fd = key => lines.find(l => l.startsWith(`${key}=`))?.split("=")[1].replace(/"/g, "") ?? "";

            root.osName = fd("NAME");
            root.osPrettyName = fd("PRETTY_NAME");
            root.osId = fd("ID");
            root.osIdLike = fd("ID_LIKE").split(" ");

            const logo = Quickshell.iconPath(fd("LOGO"), true);
            if (logo) {
                root.osLogo = logo;
                root.isDefaultLogo = false;
            }
        }
    }

    // On-demand uptime refresh - components that display uptime should:
    // Component.onCompleted: SysInfo.uptimeRefCount++
    // Component.onDestruction: SysInfo.uptimeRefCount--
    property int uptimeRefCount: 0
    
    // Refresh uptime when refCount becomes > 0, then every 15s while needed
    Timer {
        running: root.uptimeRefCount > 0
        repeat: true
        interval: 15000
        triggeredOnStart: true
        onTriggered: fileUptime.reload()
    }

    FileView {
        id: fileUptime

        path: "/proc/uptime"
        onLoaded: {
            const up = parseInt(text().split(" ")[0] ?? 0);

            const days = Math.floor(up / 86400);
            const hours = Math.floor((up % 86400) / 3600);
            const minutes = Math.floor((up % 3600) / 60);

            let str = "";
            if (days > 0)
                str += `${days} day${days === 1 ? "" : "s"}`;
            if (hours > 0)
                str += `${str ? ", " : ""}${hours} hour${hours === 1 ? "" : "s"}`;
            if (minutes > 0 || !str)
                str += `${str ? ", " : ""}${minutes} minute${minutes === 1 ? "" : "s"}`;
            root.uptime = str;
        }
    }
}
