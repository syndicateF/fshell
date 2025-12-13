import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool showOnHover: true
    property int maxShown: 18 // For grid: 3 columns x 6 rows
    property int columns: 3 // Number of columns in grid (horizontal)
    property int rows: 6 // Number of visible rows (vertical)
    property int maxWallpapers: 14 // Warning: even numbers look bad
    property string specialPrefix: "@"
    property string actionPrefix: ">"
    property bool enableDangerousActions: false // Allow actions that can cause losing data, like shutdown, reboot and logout
    property int dragThreshold: 50
    property bool vimKeybinds: false
    property list<string> hiddenApps: []
    property UseFuzzy useFuzzy: UseFuzzy {}
    property Sizes sizes: Sizes {}
    property Tabs tabs: Tabs {}

    component UseFuzzy: JsonObject {
        property bool apps: false
        property bool actions: false
        property bool schemes: false
        property bool variants: false
        property bool wallpapers: false
    }

    component Sizes: JsonObject {
        property int itemWidth: 240
        property int itemHeight: 48
        property int wallpaperWidth: 320
        property int wallpaperHeight: 200
    }

    // Tab definitions for the launcher - 6 tabs
    component Tabs: JsonObject {
        property Tab apps: Tab {
            name: "Apps"
            icon: "apps"
        }
        property Tab commands: Tab {
            name: "Commands"
            icon: "terminal"
        }
        property Tab calculator: Tab {
            name: "Calc"
            icon: "calculate"
        }
        property Tab schemes: Tab {
            name: "Schemes"
            icon: "palette"
        }
        property Tab wallpapers: Tab {
            name: "Wallpaperss"
            icon: "image"
        }
        property Tab variants: Tab {
            name: "Variants"
            icon: "colors"
        }
    }

    component Tab: JsonObject {
        property string name: ""
        property string icon: ""
    }

    property list<var> actions: [
        {
            name: "Random",
            icon: "casino",
            description: "Switch to a random wallpaper",
            command: ["caelestia", "wallpaper", "-r"],
            enabled: true,
            dangerous: false
        },
        {
            name: "Light",
            icon: "light_mode",
            description: "Change the scheme to light mode",
            command: ["setMode", "light"],
            enabled: true,
            dangerous: false
        },
        {
            name: "Dark",
            icon: "dark_mode",
            description: "Change the scheme to dark mode",
            command: ["setMode", "dark"],
            enabled: true,
            dangerous: false
        },
        {
            name: "Shutdown",
            icon: "power_settings_new",
            description: "Shutdown the system",
            command: ["systemctl", "poweroff"],
            enabled: true,
            dangerous: true
        },
        {
            name: "Reboot",
            icon: "cached",
            description: "Reboot the system",
            command: ["systemctl", "reboot"],
            enabled: true,
            dangerous: true
        },
        {
            name: "Logout",
            icon: "exit_to_app",
            description: "Log out of the current session",
            command: ["loginctl", "terminate-user", ""],
            enabled: true,
            dangerous: true
        },
        {
            name: "Lock",
            icon: "lock",
            description: "Lock the current session",
            command: ["loginctl", "lock-session"],
            enabled: true,
            dangerous: false
        },
        {
            name: "Sleep",
            icon: "bedtime",
            description: "Suspend then hibernate",
            command: ["systemctl", "suspend-then-hibernate"],
            enabled: true,
            dangerous: false
        }
    ]
}
