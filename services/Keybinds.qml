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
    // KEYBOARD LAYOUT DETECTION
    // =====================================================
    
    // Whether resolve_binds_by_sym is enabled in Hyprland
    property bool resolveBySymbol: false
    
    // Whether multiple keyboard layouts are configured
    // Check if keyboard layout config contains comma (e.g., "us,ru")
    property bool multiLayout: (Hypr.keyboard?.layout ?? "").includes(",")
    
    // Show warning if multi-layout but not resolving by symbol
    readonly property bool showLayoutWarning: multiLayout && !resolveBySymbol
    
    // =====================================================
    // SUBMAP TRACKING
    // =====================================================
    
    // List of unique submaps from processed binds
    readonly property var submaps: {
        if (binds.length === 0) return ["global"];
        const subs = new Set(binds.map(b => b.submap ?? "global"));
        return Array.from(subs).sort();
    }
    
    // Whether there are multiple submaps (show filter UI)
    readonly property bool hasMultipleSubmaps: submaps.length > 1
    
    // =====================================================
    // DESCRIPTION CONFIG (loaded from JSON)
    // =====================================================
    
    // External config for keybind descriptions
    property var descConfig: ({})
    property bool configLoaded: false
    
    // Load config file
    FileView {
        id: configFile
        path: Qt.resolvedUrl("../data/keybind-descriptions.json")
        
        onLoaded: {
            try {
                root.descConfig = JSON.parse(text());
                root.configLoaded = true;
                console.log("[Keybinds] Loaded description config");
            } catch (e) {
                console.error("[Keybinds] Failed to parse config:", e);
            }
        }
        
        onLoadFailed: err => {
            console.warn("[Keybinds] Failed to load config:", err);
        }
    }
    
    Component.onCompleted: {
        configFile.reload();
        layoutOptionProcess.running = true;
    }

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
        
        // Try JSON config lookup first
        if (configLoaded && descConfig.dispatchers) {
            const result = lookupDispatcher(dispatcher, arg);
            if (result) return result;
        }
        
        // Fallback to hardcoded logic when config not loaded
        return fallbackInferDescription(dispatcher, arg);
    }
    
    // Dynamic dispatcher lookup from JSON config
    function lookupDispatcher(dispatcher: string, arg: string): string {
        const dispatchers = descConfig.dispatchers;
        const transforms = descConfig.transforms || {};
        
        if (!dispatchers || !dispatchers[dispatcher]) return "";
        
        const config = dispatchers[dispatcher];
        
        // Handle function references
        if (typeof config === "string" && config.startsWith("__function:")) {
            const funcName = config.replace("__function:", "");
            if (funcName === "inferFromExec") return inferFromExec(arg);
            if (funcName === "inferGlobalShortcut") return inferGlobalShortcut(arg);
            return "";
        }
        
        // Simple string value
        if (typeof config === "string") {
            return applyTemplate(config, arg, transforms);
        }
        
        // Object with arg overrides
        if (typeof config === "object") {
            // Check exact arg match first
            if (config[arg]) {
                return applyTemplate(config[arg], arg, transforms);
            }
            
            // Check startsWith patterns
            for (const key of Object.keys(config)) {
                if (key.startsWith("__startsWith:")) {
                    const prefix = key.replace("__startsWith:", "");
                    if (arg.startsWith(prefix)) {
                        return applyTemplate(config[key], arg, transforms);
                    }
                }
            }
            
            // Use __default
            if (config.__default) {
                return applyTemplate(config.__default, arg, transforms);
            }
        }
        
        return "";
    }
    
    // Apply template substitutions like {arg} and {arg:direction}
    function applyTemplate(template: string, arg: string, transforms: var): string {
        if (!template) return "";
        
        let result = template;
        
        // Replace {arg:transform|default} patterns (with optional default)
        const transformWithDefaultPattern = /\{arg:(\w+)\|([^}]+)\}/g;
        let match;
        while ((match = transformWithDefaultPattern.exec(template)) !== null) {
            const transformName = match[1];
            const defaultVal = match[2];
            const transformMap = transforms[transformName] || {};
            const transformed = transformMap[arg] || arg || defaultVal;
            result = result.replace(match[0], transformed);
        }
        
        // Replace {arg:transform} patterns (without default)
        const transformPattern = /\{arg:(\w+)\}/g;
        while ((match = transformPattern.exec(result)) !== null) {
            const transformName = match[1];
            const transformMap = transforms[transformName] || {};
            const transformed = transformMap[arg] || arg;
            result = result.replace(match[0], transformed);
        }
        
        // Replace {arg|default}
        result = result.replace(/\{arg\|([^}]+)\}/g, arg || "$1");
        // Replace {arg}
        result = result.replace(/\{arg\}/g, arg);
        
        return result;
    }
    
    // Minimal hardcoded fallback for when config not loaded
    function fallbackInferDescription(dispatcher: string, arg: string): string {
        const directionMap = { l: "left", r: "right", u: "up", d: "down" };
        const toDirection = (d) => directionMap[d] ?? d;
        
        switch (dispatcher) {
            case "workspace":
                if (arg === "+1") return qsTr("Next workspace");
                if (arg === "-1") return qsTr("Previous workspace");
                return qsTr("Go to workspace %1").arg(arg);
            case "killactive":
                return qsTr("Close active window");
            case "fullscreen":
                return qsTr("Toggle fullscreen");
            case "togglefloating":
                return qsTr("Toggle floating");
            case "movefocus":
                return qsTr("Move focus %1").arg(toDirection(arg));
            case "movewindow":
                return qsTr("Move window %1").arg(toDirection(arg));
            case "exec":
            case "execr":
                return inferFromExec(arg);
            case "global":
                return inferGlobalShortcut(arg);
            default:
                if (arg) return `${dispatcher}: ${arg}`;
                return dispatcher;
        }
    }

    function inferGlobalShortcut(shortcutName: string): string {
        if (!shortcutName) return qsTr("Global shortcut");
        
        // First try JSON config lookup (full name like "caelestia:launcher")
        if (configLoaded && descConfig.globalShortcuts) {
            const configDesc = descConfig.globalShortcuts[shortcutName];
            if (configDesc) return configDesc;
        }
        
        // caelestia: prefixed shortcuts - fallback to hardcoded map
        if (shortcutName.startsWith("caelestia:")) {
            const action = shortcutName.replace("caelestia:", "");
            
            // Try config lookup for just the action part
            if (configLoaded && descConfig.globalShortcuts) {
                const configDesc = descConfig.globalShortcuts["caelestia:" + action];
                if (configDesc) return configDesc;
            }
            
            // Hardcoded fallback (kept for when config not loaded)
            const fallbackMap = {
                "screenshotFreeze": qsTr("Screenshot region"),
                "screenshot": qsTr("Screenshot"),
                "launcher": qsTr("Open launcher"),
                "overview": qsTr("Workspace overview"),
                "keybinds": qsTr("Keybinds overlay"),
                "lock": qsTr("Lock screen")
            };
            return fallbackMap[action] ?? qsTr("Shortcut: %1").arg(action);
        }
        
        return qsTr("Global: %1").arg(shortcutName);
    }

    function inferFromExec(cmd: string): string {
        if (!cmd) return qsTr("Execute command");
        
        // Extract base command
        const parts = cmd.split(/\s+/);
        const baseCmd = parts[0].split("/").pop(); // Get filename from path
        
        // Handle caelestia specially - parse full command
        if (baseCmd === "caelestia") {
            return inferCaelestiaCmd(cmd);
        }
        
        // pkill + caelestia compound commands
        if (cmd.includes("pkill") && cmd.includes("caelestia")) {
            return inferCaelestiaCmd(cmd);
        }
        
        // Check for caelestia in qs command
        if (baseCmd === "qs" && cmd.includes("caelestia")) {
            return inferCaelestiaCmd(cmd);
        }
        
        // Try JSON config execPatterns for commands like wpctl, systemctl
        if (configLoaded && descConfig.execPatterns && descConfig.execPatterns[baseCmd]) {
            const result = lookupExecPattern(baseCmd, cmd);
            if (result) return result;
        }
        
        // Try JSON config lookup for simple commands
        if (configLoaded && descConfig.execCommands) {
            const configDesc = descConfig.execCommands[baseCmd];
            if (configDesc) return configDesc;
        }
        
        // Minimal hardcoded fallback
        const fallbackMap = {
            "kitty": qsTr("Open terminal"),
            "firefox": qsTr("Open Firefox"),
            "nautilus": qsTr("Open file manager"),
            "hyprlock": qsTr("Lock screen"),
            "qs": qsTr("Quickshell command"),
            "sleep": qsTr("Delay command")
        };
        
        // wsaction.fish script (workspace actions) - requires runtime parsing
        if (cmd.includes("wsaction.fish")) {
            const wsMatch = cmd.match(/wsaction\.fish\s+(?:-g\s+)?(\w+)\s+(\d+)/);
            if (wsMatch) {
                const action = wsMatch[1];
                const num = wsMatch[2];
                if (action === "workspace") {
                    if (cmd.includes("-g")) {
                        return qsTr("Move to workspace %1").arg(num);
                    }
                    return qsTr("Go to workspace %1").arg(num);
                } else if (action === "movetoworkspace") {
                    return qsTr("Move window to workspace %1").arg(num);
                }
            }
            return qsTr("Workspace action");
        }
        
        // app2unit/systemd-run patterns (for sandboxed apps)
        if (baseCmd === "app2unit" || cmd.includes("app2unit")) {
            // Extract the actual app being launched
            const appMatch = cmd.match(/--\s+(\S+)/);
            if (appMatch) {
                const appName = appMatch[1].split("/").pop();
                return qsTr("Open %1").arg(appName);
            }
            return qsTr("Launch application");
        }
        
        return fallbackMap[baseCmd] ?? qsTr("Run: %1").arg(baseCmd);
    }
    
    // Lookup pattern for exec commands with complex patterns (wpctl, systemctl)
    function lookupExecPattern(baseCmd: string, fullCmd: string): string {
        const patterns = descConfig.execPatterns[baseCmd];
        if (!patterns) return "";
        
        // Check __contains patterns
        for (const key of Object.keys(patterns)) {
            if (key.startsWith("__contains:")) {
                const pattern = key.replace("__contains:", "");
                try {
                    const regex = new RegExp(pattern);
                    if (regex.test(fullCmd)) {
                        return patterns[key];
                    }
                } catch (e) {
                    if (fullCmd.includes(pattern.replace(/\\.\\*/g, ""))) {
                        return patterns[key];
                    }
                }
            }
        }
        
        // Return __default if exists
        return patterns.__default ?? "";
    }

    function inferCaelestiaCmd(cmd: string): string {
        // Try JSON config patterns first
        if (configLoaded && descConfig.caelestiaPatterns) {
            for (const pattern of descConfig.caelestiaPatterns) {
                try {
                    const regex = new RegExp(pattern.match);
                    if (regex.test(cmd) || cmd.includes(pattern.match)) {
                        return pattern.desc;
                    }
                } catch (e) {
                    // If regex fails, try simple includes match
                    if (cmd.includes(pattern.match)) {
                        return pattern.desc;
                    }
                }
            }
        }
        
        // Minimal hardcoded fallback
        if (cmd.includes("screenshot")) return qsTr("Screenshot");
        if (cmd.includes("record")) return qsTr("Record screen");
        if (cmd.includes("toggle")) return qsTr("Toggle");
        if (cmd.includes("lock")) return qsTr("Lock screen");
        
        // Fallback - show truncated command
        const subCmd = cmd.replace(/.*caelestia\s+/, "").slice(0, 25);
        return subCmd ? qsTr("Caelestia: %1").arg(subCmd) : qsTr("Caelestia command");
    }

    // =====================================================
    // CATEGORIZATION
    // =====================================================

    function categorize(bind: var): string {
        const dispatcher = bind.dispatcher;
        const arg = bind.arg ?? "";
        
        // Try JSON config categories first
        if (configLoaded && descConfig.categories) {
            const cats = descConfig.categories;
            
            // Check dispatcher categories
            if (cats.dispatchers) {
                for (const category of Object.keys(cats.dispatchers)) {
                    if (cats.dispatchers[category].includes(dispatcher)) {
                        return category;
                    }
                }
            }
            
            // Exec-based categorization
            if (dispatcher === "exec" || dispatcher === "execr") {
                if (cats.execPatterns) {
                    for (const category of Object.keys(cats.execPatterns)) {
                        for (const pattern of cats.execPatterns[category]) {
                            if (arg.includes(pattern)) {
                                return category;
                            }
                        }
                    }
                }
                return cats.default ?? "apps";
            }
        }
        
        // Minimal hardcoded fallback
        if (["killactive", "fullscreen", "togglefloating", "movefocus", "movewindow"].includes(dispatcher)) {
            return "window";
        }
        if (["workspace", "movetoworkspace", "togglespecialworkspace"].includes(dispatcher)) {
            return "workspace";
        }
        if (dispatcher === "exec" || dispatcher === "execr") {
            return "apps";
        }
        
        return "other";
    }

    // =====================================================
    // FILTERING
    // =====================================================

    function filterBinds(rawBinds: var): var {
        return rawBinds.filter(bind => {
            // Skip empty key binds
            if (!bind.key || bind.key === "") return false;
            
            // Skip catch-all handlers
            if (bind.catch_all) return false;
            
            // Skip mouse binds (optional - can enable if wanted)
            if (bind.key.startsWith("mouse:")) return false;
            
            // For global dispatcher, skip internal handlers
            if (bind.dispatcher === "global") {
                const arg = bind.arg ?? "";
                // Skip interrupt handlers
                if (arg.includes("Interrupt") || arg.includes("interrupt")) return false;
                // Skip refreshDevices (Caps_Lock/Num_Lock device refresh - duplicated many times)
                if (arg.includes("refreshDevices")) return false;
                // Allow useful global shortcuts
                return true;
            }
            
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
            
            // Submap context
            submap: bind.submap ?? "global",
            isGlobal: (bind.submap ?? "global") === "global",
            
            // Processed data
            modifiers: decodeModmask(bind.modmask),
            description: inferDescription(bind),
            category: categorize(bind),
            
            // Bind flags (for visual badges)
            flags: {
                locked: bind.locked ?? false,
                repeat: bind.repeat ?? false,
                release: bind.release ?? false,
                nonConsuming: bind.non_consuming ?? false,
                mouse: bind.mouse ?? false,
                longPress: bind.longPress ?? false
            }
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
            // Also refresh layout option
            layoutOptionProcess.running = true;
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

    // =====================================================
    // LAYOUT OPTION FETCH
    // =====================================================

    property string layoutOptionBuffer: ""

    Process {
        id: layoutOptionProcess
        
        command: ["hyprctl", "getoption", "input:resolve_binds_by_sym", "-j"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.layoutOptionBuffer += data;
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.layoutOptionBuffer.length > 0) {
                try {
                    const parsed = JSON.parse(root.layoutOptionBuffer);
                    root.resolveBySymbol = (parsed.int === 1) || (parsed.set === true);
                    console.log("[Keybinds] resolve_binds_by_sym:", root.resolveBySymbol);
                } catch (e) {
                    console.warn("[Keybinds] Failed to parse layout option:", e);
                }
            }
            root.layoutOptionBuffer = "";
        }
    }
}
