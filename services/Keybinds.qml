pragma Singleton

import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // =====================================================
    // PROPERTIES
    // =====================================================

    // Raw keybinds from hyprctl
    property var rawBinds: []
    
    // Processed and filtered keybinds
    property var binds: []
    
    // Keybinds grouped by category
    property var categories: ({
        window: [],
        workspace: [],
        apps: [],
        system: [],
        media: [],
        other: []
    })
    
    // Loading state
    property bool isLoading: false
    
    // Dirty flag - needs refresh
    property bool isDirty: true
    
    // Last refresh timestamp
    property real lastRefresh: 0

    // =====================================================
    // SIGNALS
    // =====================================================

    signal bindsRefreshed()
    signal refreshFailed(string error)

    // =====================================================
    // MODMASK DECODING
    // =====================================================

    // Modifier bit flags (from Hyprland source)
    readonly property int modShift: 1
    readonly property int modCaps: 2
    readonly property int modCtrl: 4
    readonly property int modAlt: 8
    readonly property int modMod2: 16
    readonly property int modMod3: 32
    readonly property int modSuper: 64
    readonly property int modMod5: 128

    function decodeModmask(mask: int): string {
        if (mask === 0) return "";
        
        const mods = [];
        
        // Order: SUPER, CTRL, ALT, SHIFT (consistent with common conventions)
        if (mask & modSuper) mods.push("Super");
        if (mask & modCtrl) mods.push("Ctrl");
        if (mask & modAlt) mods.push("Alt");
        if (mask & modShift) mods.push("Shift");
        
        return mods.join(" + ");
    }

    // =====================================================
    // DESCRIPTION INFERENCE
    // =====================================================

    function inferDescription(bind: var): string {
        // If has explicit description, use it
        if (bind.description && bind.description !== "") {
            return bind.description;
        }
        
        const dispatcher = bind.dispatcher;
        const arg = bind.arg ?? "";
        
        // Dispatcher-based inference
        switch (dispatcher) {
            // Workspace management
            case "workspace":
                return qsTr("Go to workspace %1").arg(arg);
            case "movetoworkspace":
                return qsTr("Move window to workspace %1").arg(arg);
            case "movetoworkspacesilent":
                return qsTr("Move window silently to workspace %1").arg(arg);
            case "togglespecialworkspace":
                return qsTr("Toggle special workspace %1").arg(arg || "scratchpad");
            
            // Window management
            case "killactive":
                return qsTr("Close active window");
            case "fullscreen":
                if (arg === "1") return qsTr("Toggle maximize");
                if (arg === "2") return qsTr("Toggle fake fullscreen");
                return qsTr("Toggle fullscreen");
            case "togglefloating":
                return qsTr("Toggle floating");
            case "pseudo":
                return qsTr("Toggle pseudo-tiling");
            case "pin":
                return qsTr("Pin window");
            case "centerwindow":
                return qsTr("Center window");
            case "focuswindow":
                return qsTr("Focus window: %1").arg(arg);
            
            // Focus & movement
            case "movefocus":
                return qsTr("Move focus %1").arg(arg);
            case "movewindow":
                return qsTr("Move window %1").arg(arg);
            case "swapwindow":
                return qsTr("Swap window %1").arg(arg);
            case "resizeactive":
                return qsTr("Resize window: %1").arg(arg);
            case "cyclenext":
                return qsTr("Cycle to next window");
            case "focuscurrentorlast":
                return qsTr("Focus current or last window");
            
            // Layout
            case "layoutmsg":
                return qsTr("Layout: %1").arg(arg);
            case "togglesplit":
                return qsTr("Toggle split direction");
            case "splitratio":
                return qsTr("Adjust split ratio: %1").arg(arg);
            
            // Groups
            case "togglegroup":
                return qsTr("Toggle window group");
            case "changegroupactive":
                return qsTr("Change active in group: %1").arg(arg || "next");
            case "moveoutofgroup":
                return qsTr("Move window out of group");
            case "moveintogroup":
                return qsTr("Move window into group: %1").arg(arg);
            
            // Monitors
            case "focusmonitor":
                return qsTr("Focus monitor: %1").arg(arg);
            case "movecurrentworkspacetomonitor":
                return qsTr("Move workspace to monitor: %1").arg(arg);
            case "movewindowtomonitor":
                return qsTr("Move window to monitor: %1").arg(arg);
            
            // System
            case "exit":
                return qsTr("Exit Hyprland");
            case "forcerendererreload":
                return qsTr("Force renderer reload");
            case "dpms":
                return qsTr("Toggle DPMS: %1").arg(arg || "toggle");
            
            // Misc
            case "exec":
                return inferFromExec(arg);
            case "execr":
                return inferFromExec(arg);
            case "pass":
                return qsTr("Pass to: %1").arg(arg);
            case "submap":
                return qsTr("Enter submap: %1").arg(arg || "reset");
            
            default:
                // Fallback: Show dispatcher and arg
                if (arg) return `${dispatcher}: ${arg}`;
                return dispatcher;
        }
    }

    function inferFromExec(cmd: string): string {
        if (!cmd) return qsTr("Execute command");
        
        // Extract base command
        const parts = cmd.split(/\s+/);
        const baseCmd = parts[0].split("/").pop(); // Get filename from path
        
        // Common command mappings
        const cmdMap = {
            // Terminals
            "kitty": qsTr("Open terminal"),
            "alacritty": qsTr("Open terminal"),
            "foot": qsTr("Open terminal"),
            "wezterm": qsTr("Open terminal"),
            
            // Browsers
            "firefox": qsTr("Open Firefox"),
            "chromium": qsTr("Open Chromium"),
            "brave": qsTr("Open Brave"),
            "zen-browser": qsTr("Open Zen Browser"),
            
            // File managers
            "nautilus": qsTr("Open file manager"),
            "thunar": qsTr("Open file manager"),
            "dolphin": qsTr("Open file manager"),
            "nemo": qsTr("Open file manager"),
            
            // Launchers
            "rofi": qsTr("Open launcher"),
            "wofi": qsTr("Open launcher"),
            "fuzzel": qsTr("Open launcher"),
            
            // Screenshot
            "grim": qsTr("Take screenshot"),
            "grimblast": qsTr("Take screenshot"),
            "flameshot": qsTr("Screenshot tool"),
            
            // Clipboard
            "wl-copy": qsTr("Copy to clipboard"),
            "wl-paste": qsTr("Paste from clipboard"),
            "cliphist": qsTr("Clipboard history"),
            
            // Audio
            "wpctl": qsTr("Audio control"),
            "pactl": qsTr("Audio control"),
            "playerctl": qsTr("Media control"),
            
            // Brightness
            "brightnessctl": qsTr("Brightness control"),
            "light": qsTr("Brightness control"),
            
            // Lock/Power
            "loginctl": qsTr("Session control"),
            "systemctl": qsTr("System control"),
            "hyprlock": qsTr("Lock screen"),
            "swaylock": qsTr("Lock screen"),
            
            // Quickshell/Caelestia
            "qs": qsTr("Quickshell command"),
            "caelestia": inferCaelestiaCmd(cmd)
        };
        
        return cmdMap[baseCmd] ?? qsTr("Run: %1").arg(baseCmd);
    }

    function inferCaelestiaCmd(cmd: string): string {
        if (cmd.includes("toggle sysmon")) return qsTr("Toggle system monitor");
        if (cmd.includes("shell")) return qsTr("Reload shell");
        if (cmd.includes("scheme")) return qsTr("Change color scheme");
        if (cmd.includes("wallpaper")) return qsTr("Change wallpaper");
        return qsTr("Caelestia command");
    }

    // =====================================================
    // CATEGORIZATION
    // =====================================================

    function categorize(bind: var): string {
        const dispatcher = bind.dispatcher;
        const arg = bind.arg ?? "";
        
        // Window management
        if (["killactive", "fullscreen", "togglefloating", "pseudo", "pin", 
             "centerwindow", "focuswindow", "movefocus", "movewindow", 
             "swapwindow", "resizeactive", "cyclenext", "focuscurrentorlast",
             "togglesplit", "splitratio", "togglegroup", "changegroupactive",
             "moveoutofgroup", "moveintogroup", "layoutmsg"].includes(dispatcher)) {
            return "window";
        }
        
        // Workspace
        if (["workspace", "movetoworkspace", "movetoworkspacesilent",
             "togglespecialworkspace", "focusmonitor", "movecurrentworkspacetomonitor",
             "movewindowtomonitor"].includes(dispatcher)) {
            return "workspace";
        }
        
        // System
        if (["exit", "forcerendererreload", "dpms", "submap"].includes(dispatcher)) {
            return "system";
        }
        
        // Exec-based categorization
        if (dispatcher === "exec" || dispatcher === "execr") {
            if (arg.includes("playerctl") || arg.includes("wpctl") || 
                arg.includes("pactl") || arg.includes("volume")) {
                return "media";
            }
            if (arg.includes("screenshot") || arg.includes("grim") || 
                arg.includes("flameshot")) {
                return "system";
            }
            return "apps";
        }
        
        return "other";
    }

    // =====================================================
    // FILTERING
    // =====================================================

    function filterBinds(rawBinds: var): var {
        return rawBinds.filter(bind => {
            // Skip internal GlobalShortcut binds
            if (bind.dispatcher === "global") return false;
            
            // Skip catch-all handlers
            if (bind.catch_all) return false;
            
            // Skip empty key binds
            if (!bind.key || bind.key === "") return false;
            
            // Skip mouse binds (optional - can enable if wanted)
            if (bind.key.startsWith("mouse:")) return false;
            
            // Skip submap entry/exit (keep only actual binds)
            // if (bind.dispatcher === "submap") return false;
            
            return true;
        });
    }

    // =====================================================
    // PROCESSING
    // =====================================================

    function processBinds(rawBinds: var): void {
        const filtered = filterBinds(rawBinds);
        
        // Process each bind
        const processed = filtered.map(bind => ({
            // Original data
            key: bind.key,
            modmask: bind.modmask,
            dispatcher: bind.dispatcher,
            arg: bind.arg,
            submap: bind.submap,
            
            // Processed data
            modifiers: decodeModmask(bind.modmask),
            description: inferDescription(bind),
            category: categorize(bind),
            
            // Flags
            repeat: bind.repeat,
            release: bind.release,
            locked: bind.locked
        }));
        
        // Sort by category, then by modmask, then by key
        processed.sort((a, b) => {
            if (a.category !== b.category) {
                const order = ["workspace", "window", "apps", "media", "system", "other"];
                return order.indexOf(a.category) - order.indexOf(b.category);
            }
            if (a.modmask !== b.modmask) return a.modmask - b.modmask;
            return a.key.localeCompare(b.key);
        });
        
        root.binds = processed;
        
        // Group by category
        const cats = {
            window: [],
            workspace: [],
            apps: [],
            system: [],
            media: [],
            other: []
        };
        
        for (const bind of processed) {
            if (cats[bind.category]) {
                cats[bind.category].push(bind);
            } else {
                cats.other.push(bind);
            }
        }
        
        root.categories = cats;
    }

    // =====================================================
    // PUBLIC FUNCTIONS
    // =====================================================

    function refresh(): void {
        if (isLoading) return;
        
        isLoading = true;
        fetchProcess.running = true;
    }

    function refreshIfDirty(): void {
        if (isDirty) {
            refresh();
        }
    }

    function invalidate(): void {
        isDirty = true;
    }

    // =====================================================
    // CATEGORY DISPLAY INFO
    // =====================================================

    readonly property var categoryInfo: ({
        workspace: { 
            name: qsTr("Workspaces"), 
            icon: "space_dashboard",
            description: qsTr("Navigate and manage workspaces")
        },
        window: { 
            name: qsTr("Windows"), 
            icon: "select_window",
            description: qsTr("Window management and focus")
        },
        apps: { 
            name: qsTr("Applications"), 
            icon: "apps",
            description: qsTr("Launch applications")
        },
        media: { 
            name: qsTr("Media"), 
            icon: "music_note",
            description: qsTr("Audio and media controls")
        },
        system: { 
            name: qsTr("System"), 
            icon: "settings",
            description: qsTr("System controls and utilities")
        },
        other: { 
            name: qsTr("Other"), 
            icon: "more_horiz",
            description: qsTr("Miscellaneous shortcuts")
        }
    })

    function getCategoryName(category: string): string {
        return categoryInfo[category]?.name ?? category;
    }

    function getCategoryIcon(category: string): string {
        return categoryInfo[category]?.icon ?? "keyboard";
    }

    // =====================================================
    // CONNECTIONS
    // =====================================================

    Connections {
        target: Hypr
        
        function onConfigReloaded(): void {
            // Invalidate cache when Hyprland config is reloaded
            root.invalidate();
            console.log("[Keybinds] Config reloaded - cache invalidated");
        }
    }

    // =====================================================
    // FETCH PROCESS
    // =====================================================

    // Accumulator for stdout chunks
    property string stdoutBuffer: ""

    Process {
        id: fetchProcess
        
        command: ["hyprctl", "binds", "-j"]
        
        stdout: SplitParser {
            splitMarker: ""
            
            onRead: data => {
                // Accumulate chunks, don't parse yet
                root.stdoutBuffer += data;
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.stdoutBuffer.length > 0) {
                try {
                    const parsed = JSON.parse(root.stdoutBuffer);
                    root.rawBinds = parsed;
                    root.processBinds(parsed);
                    root.isDirty = false;
                    root.lastRefresh = Date.now();
                    root.isLoading = false;
                    root.bindsRefreshed();
                    console.log("[Keybinds] Loaded", root.binds.length, "keybinds");
                } catch (e) {
                    console.error("[Keybinds] Failed to parse:", e);
                    root.isLoading = false;
                    root.refreshFailed(e.toString());
                }
            } else if (exitCode !== 0) {
                console.error("[Keybinds] hyprctl failed with code:", exitCode);
                root.isLoading = false;
                root.refreshFailed("hyprctl exited with code " + exitCode);
            }
            // Clear buffer for next fetch
            root.stdoutBuffer = "";
        }
    }
}

