pragma Singleton

import qs.config
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // WMO Weather codes (Open-Meteo standard)
    readonly property var wmoWeatherIcons: ({
            // Day icons
            "0_day": "clear_day",
            "1_day": "clear_day",
            "2_day": "partly_cloudy_day",
            "3_day": "cloud",
            "45_day": "foggy",
            "48_day": "foggy",
            "51_day": "rainy",
            "53_day": "rainy",
            "55_day": "rainy",
            "56_day": "rainy",
            "57_day": "rainy",
            "61_day": "rainy",
            "63_day": "rainy",
            "65_day": "weather_hail",
            "66_day": "rainy",
            "67_day": "rainy",
            "71_day": "cloudy_snowing",
            "73_day": "cloudy_snowing",
            "75_day": "snowing_heavy",
            "77_day": "snowing",
            "80_day": "rainy",
            "81_day": "rainy",
            "82_day": "weather_hail",
            "85_day": "cloudy_snowing",
            "86_day": "snowing_heavy",
            "95_day": "thunderstorm",
            "96_day": "thunderstorm",
            "99_day": "thunderstorm",
            // Night icons
            "0_night": "clear_night",
            "1_night": "clear_night",
            "2_night": "partly_cloudy_night",
            "3_night": "cloud",
            "45_night": "foggy",
            "48_night": "foggy",
            "51_night": "rainy",
            "53_night": "rainy",
            "55_night": "rainy",
            "56_night": "rainy",
            "57_night": "rainy",
            "61_night": "rainy",
            "63_night": "rainy",
            "65_night": "weather_hail",
            "66_night": "rainy",
            "67_night": "rainy",
            "71_night": "cloudy_snowing",
            "73_night": "cloudy_snowing",
            "75_night": "snowing_heavy",
            "77_night": "snowing",
            "80_night": "rainy",
            "81_night": "rainy",
            "82_night": "weather_hail",
            "85_night": "cloudy_snowing",
            "86_night": "snowing_heavy",
            "95_night": "thunderstorm",
            "96_night": "thunderstorm",
            "99_night": "thunderstorm"
        })

    readonly property var categoryIcons: ({
            WebBrowser: "web",
            Printing: "print",
            Security: "security",
            Network: "chat",
            Archiving: "archive",
            Compression: "archive",
            Development: "code",
            IDE: "code",
            TextEditor: "edit_note",
            Audio: "music_note",
            Music: "music_note",
            Player: "music_note",
            Recorder: "mic",
            Game: "sports_esports",
            FileTools: "files",
            FileManager: "files",
            Filesystem: "files",
            FileTransfer: "files",
            Settings: "settings",
            DesktopSettings: "settings",
            HardwareSettings: "settings",
            TerminalEmulator: "terminal",
            ConsoleOnly: "terminal",
            Utility: "build",
            Monitor: "monitor_heart",
            Midi: "graphic_eq",
            Mixer: "graphic_eq",
            AudioVideoEditing: "video_settings",
            AudioVideo: "music_video",
            Video: "videocam",
            Building: "construction",
            Graphics: "photo_library",
            "2DGraphics": "photo_library",
            RasterGraphics: "photo_library",
            TV: "tv",
            System: "host",
            Office: "content_paste"
        })

    function getAppIcon(name: string, fallback: string): string {
        const icon = DesktopEntries.heuristicLookup(name)?.icon;
        if (!icon) {
            if (fallback !== "undefined")
                return Quickshell.iconPath(fallback);
            return "";
        }
        if (fallback !== "undefined")
            return Quickshell.iconPath(icon, fallback);
        return Quickshell.iconPath(icon);
    }

    function getAppCategoryIcon(name: string, fallback: string): string {
        const categories = DesktopEntries.heuristicLookup(name)?.categories;

        if (categories)
            for (const [key, value] of Object.entries(categoryIcons))
                if (categories.includes(key))
                    return value;
        return fallback;
    }

    function getNetworkIcon(strength: int): string {
        if (strength >= 80)
            return "signal_wifi_4_bar";
        if (strength >= 60)
            return "network_wifi_3_bar";
        if (strength >= 40)
            return "network_wifi_2_bar";
        if (strength >= 20)
            return "network_wifi_1_bar";
        return "signal_wifi_0_bar";
    }

    function getBluetoothIcon(icon: string): string {
        if (icon.includes("headset") || icon.includes("headphones"))
            return "headphones";
        if (icon.includes("audio"))
            return "speaker";
        if (icon.includes("phone"))
            return "smartphone";
        if (icon.includes("mouse"))
            return "mouse";
        if (icon.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    function getWeatherIcon(code, isDay) {
        // Default to day if isDay not provided
        if (isDay === undefined) isDay = true;
        const suffix = isDay ? "_day" : "_night";
        const key = code.toString() + suffix;
        if (wmoWeatherIcons.hasOwnProperty(key))
            return wmoWeatherIcons[key];
        // Fallback to day variant if night not found
        const dayKey = code.toString() + "_day";
        if (wmoWeatherIcons.hasOwnProperty(dayKey))
            return wmoWeatherIcons[dayKey];
        return "cloud";
    }

    function getNotifIcon(summary: string, urgency: int): string {
        summary = summary.toLowerCase();
        if (summary.includes("reboot"))
            return "restart_alt";
        if (summary.includes("recording"))
            return "screen_record";
        if (summary.includes("battery"))
            return "power";
        if (summary.includes("screenshot"))
            return "screenshot_monitor";
        if (summary.includes("welcome"))
            return "waving_hand";
        if (summary.includes("time") || summary.includes("a break"))
            return "schedule";
        if (summary.includes("installed"))
            return "download";
        if (summary.includes("update"))
            return "update";
        if (summary.includes("unable to"))
            return "deployed_code_alert";
        if (summary.includes("profile"))
            return "person";
        if (summary.includes("file"))
            return "folder_copy";
        if (urgency === NotificationUrgency.Critical)
            return "release_alert";
        return "chat";
    }

    function getVolumeIcon(volume: real, isMuted: bool): string {
        if (isMuted)
            return "no_sound";
        if (volume >= 0.5)
            return "volume_up";
        if (volume > 0)
            return "volume_down";
        return "volume_mute";
    }

    function getMicVolumeIcon(volume: real, isMuted: bool): string {
        if (!isMuted && volume > 0)
            return "mic";
        return "mic_off";
    }

    function getSpecialWsIcon(name: string): string {
        name = name.toLowerCase().slice("special:".length);
        
        for (const iconConfig of Config.bar.workspaces.specialWorkspaceIcons) {
            if (iconConfig.name === name) {
                return iconConfig.icon;
            }
        }
        
        if (name === "special")
            return "star";
        if (name === "communication")
            return "forum";
        if (name === "music")
            return "music_cast";
        if (name === "todo")
            return "checklist";
        if (name === "sysmon")
            return "monitor_heart";
        return name[0].toUpperCase();
    }

    function getTrayIcon(id: string, icon: string): string {
        for (const sub of Config.bar.tray.iconSubs)
            if (sub.id === id)
                return sub.image ? Qt.resolvedUrl(sub.image) : Quickshell.iconPath(sub.icon);

        if (icon.includes("?path=")) {
            const [name, path] = icon.split("?path=");
            icon = Qt.resolvedUrl(`${path}/${name.slice(name.lastIndexOf("/") + 1)}`);
        }
        return icon;
    }
}
