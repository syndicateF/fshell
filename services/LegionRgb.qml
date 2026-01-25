pragma Singleton
pragma ComponentBehavior: Bound

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Legion RGB Keyboard Service
 * 
 * Communicates with legion-rgbd via Unix socket at /run/legion-rgb.sock
 * Protocol v1: key=value format, parsed by key name (order independent)
 * 
 * NO POLLING - refresh() only called on explicit action (popout open)
 */
Singleton {
    id: root

    // =====================================================
    // PUBLIC STATE (from daemon)
    // =====================================================
    
    readonly property bool available: _available
    readonly property bool hasState: _hasState
    readonly property string effect: _effect  // static|breath|wave|hue|off|unknown
    readonly property var colors: _colors     // [hex, hex, hex, hex]
    readonly property string direction: _direction  // ltr|rtl (wave only)
    readonly property int brightness: _brightness  // 1-2
    readonly property int speed: _speed        // 1-4
    
    // Busy state for UI feedback
    readonly property bool busy: _busy
    readonly property string lastError: _lastError
    
    // =====================================================
    // PRIVATE STATE
    // =====================================================
    
    property bool _available: false
    property bool _hasState: false
    property string _effect: "unknown"
    property var _colors: ["000000", "000000", "000000", "000000"]
    property string _direction: ""
    property int _brightness: 1
    property int _speed: 1
    property bool _busy: false
    property string _lastError: ""
    
    // =====================================================
    // PUBLIC FUNCTIONS
    // =====================================================
    
    /**
     * Query current status from daemon - call on popout open
     * NO POLLING - only explicit refresh
     */
    function refresh(): void {
        if (_busy) return;
        _busy = true;
        _lastError = "";
        statusProc.running = true;
    }
    
    // =====================================================
    // PUBLIC METHODS (UI calls these - no command strings in UI)
    // =====================================================
    
    /**
     * Available color presets (UI reads this, not hardcoded)
     */
    readonly property var colorPresets: [
        "ff0000", "ff5500", "ffff00", "00ff00", 
        "00ffff", "0000ff", "ff00ff", "ffffff"
    ]
    
    /**
     * Set single zone color (preserves other zones)
     */
    function setZoneColor(zoneIndex: int, color: string): void {
        const colors = _colors.slice();
        colors[zoneIndex] = color.toLowerCase().replace("#", "");
        _sendColorCommand(colors);
    }
    
    /**
     * Apply 4 colors at once
     */
    function applyColors4(colors: var): void {
        // Normalize to 4 colors
        const normalized = [];
        for (let i = 0; i < 4; i++) {
            const c = colors[i] || colors[colors.length - 1] || "ff5500";
            normalized.push(c.toLowerCase().replace("#", ""));
        }
        _sendColorCommand(normalized);
    }
    
    /**
     * Preview zone color - apply to hardware WITHOUT persisting
     * Used by color picker for live preview
     */
    function previewZoneColor(zoneIndex: int, color: string): void {
        const colors = _colors.slice();
        colors[zoneIndex] = color.toLowerCase().replace("#", "");
        _colors = colors;
        previewProc.command = ["sh", "-c", `echo 'static ${colors.join(" ")} --brightness ${_brightness}' | nc -U /run/legion-rgb.sock`];
        previewProc.running = true;
    }
    
    /**
     * Apply full state - build explicit command from state object
     * Used for both Apply (current state) and Cancel (snapshot)
     */
    function applyFullState(state: var): void {
        const colorStr = state.colors.join(" ");
        let cmd = "";
        switch (state.effect) {
            case "static":
                cmd = `static ${colorStr} --brightness ${state.brightness}`;
                break;
            case "breath":
                cmd = `breath ${colorStr} --speed ${state.speed} --brightness ${state.brightness}`;
                break;
            case "wave":
                cmd = `wave ${state.direction || "rtl"} --speed ${state.speed} --brightness ${state.brightness}`;
                break;
            case "hue":
                cmd = `hue --speed ${state.speed} --brightness ${state.brightness}`;
                break;
            case "off":
                cmd = "off";
                break;
            default:
                return;
        }
        
        // Update local state
        _effect = state.effect;
        _colors = state.colors.slice();
        _brightness = state.brightness;
        _speed = state.speed;
        _direction = state.direction || "rtl";
        
        // Send command
        _sendRaw(cmd);
    }
    
    /**
     * Switch effect (preserves current colors/settings)
     */
    function switchEffect(newEffect: string): void {
        _sendCommand(newEffect);
    }
    
    /**
     * Set speed (1-4)
     */
    function setSpeed(speed: int): void {
        _speed = speed;
        _sendCommand(_effect);
    }
    
    /**
     * Set brightness (1-2)
     */
    function setBrightness(brightness: int): void {
        _brightness = brightness;
        _sendCommand(_effect);
    }
    
    /**
     * Set direction (ltr/rtl) - wave only
     */
    function setDirection(dir: string): void {
        _direction = dir;
        _sendCommand(_effect);
    }
    
    /**
     * Turn off RGB
     */
    function turnOff(): void {
        _sendRaw("off");
    }
    
    // =====================================================
    // INTERNAL COMMAND BUILDER (private)
    // =====================================================
    
    function _sendColorCommand(colors: var): void {
        _colors = colors;
        _sendCommand(_effect);
    }
    
    function _sendCommand(effect: string): void {
        const colorStr = _colors.join(" ");
        const speed = _speed || 1;
        const brightness = _brightness || 1;
        const direction = _direction || "rtl";
        
        let cmd = "";
        switch (effect) {
            case "static":
                cmd = `static ${colorStr} --brightness ${brightness}`;
                break;
            case "breath":
                cmd = `breath ${colorStr} --speed ${speed} --brightness ${brightness}`;
                break;
            case "wave":
                cmd = `wave ${direction} --speed ${speed} --brightness ${brightness}`;
                break;
            case "hue":
                cmd = `hue --speed ${speed} --brightness ${brightness}`;
                break;
            case "off":
                cmd = "off";
                break;
            default:
                return;
        }
        _sendRaw(cmd);
    }
    
    function _sendRaw(cmd: string): void {
        if (_busy) return;
        _busy = true;
        _lastError = "";
        setProc.command = ["sh", "-c", `echo '${cmd}' | nc -U /run/legion-rgb.sock`];
        setProc.running = true;
    }
    
    // =====================================================
    // PRESET SYSTEM
    // =====================================================
    
    readonly property var presets: _presets
    property var _presets: []
    readonly property string presetsPath: `${Paths.home}/.config/x-shell/rgb-presets.json`
    
    /**
     * Load presets from config file
     */
    function loadPresets(): void {
        presetsFileReader.reload();
    }
    
    /**
     * Save current state as new preset
     */
    function savePreset(name: string): void {
        const preset = {
            version: 1,
            id: Date.now().toString(),
            name: name,
            created: new Date().toISOString(),
            state: {
                effect: _effect,
                colors: _colors.slice(),
                direction: _direction,
                brightness: _brightness,
                speed: _speed
            }
        };
        
        _presets = [..._presets, preset];
        writePresets();
    }
    
    /**
     * Delete preset by id
     */
    function deletePreset(id: string): void {
        _presets = _presets.filter(p => p.id !== id);
        writePresets();
    }
    
    /**
     * Apply preset
     */
    function applyPreset(preset: var): void {
        const s = preset.state;
        
        // Update internal state
        _effect = s.effect || "static";
        _colors = s.colors || ["ff5500", "ff5500", "ff5500", "ff5500"];
        _direction = s.direction || "rtl";
        _speed = s.speed || 1;
        _brightness = s.brightness || 1;
        
        // Send command
        _sendCommand(_effect);
    }
    
    function writePresets(): void {
        const json = JSON.stringify(_presets, null, 2);
        // Escape single quotes for shell
        const escaped = json.replace(/'/g, "'\\''");
        presetWriter.command = ["sh", "-c", `mkdir -p "$(dirname '${presetsPath}')" && printf '%s' '${escaped}' > '${presetsPath}'`];
        presetWriter.running = true;
    }
    
    FileView {
        id: presetsFileReader
        path: root.presetsPath
        
        onLoaded: {
            const content = text();
            if (content && content.trim()) {
                try {
                    root._presets = JSON.parse(content);
                } catch (e) {
                    console.warn("Failed to parse presets:", e);
                    root._presets = [];
                }
            }
        }
        
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                // Create empty presets file on first run
                root._presets = [];
                writePresets();
            }
        }
    }
    
    Process {
        id: presetWriter
    }
    
    Component.onCompleted: {
        loadPresets();
    }
    
    // =====================================================
    // PROCESSES
    // =====================================================
    
    Process {
        id: statusProc
        command: ["sh", "-c", "echo 'status' | nc -U /run/legion-rgb.sock"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                if (!text.startsWith("OK")) {
                    root._lastError = text.trim();
                    return;
                }
                root.parseStatusResponse(text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    root._lastError = text.trim();
                }
            }
        }
    }
    
    Process {
        id: setProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._busy = false;
                if (!text.startsWith("OK")) {
                    root._lastError = text.trim();
                } else {
                    // After successful set, refresh state
                    root.refresh();
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    root._lastError = text.trim();
                }
            }
        }
    }
    
    // Preview process - no busy state, no refresh (ephemeral)
    Process {
        id: previewProc
        // Silent - preview doesn't affect UI state
    }
    
    // =====================================================
    // PARSER (key-based, order independent)
    // =====================================================
    
    function parseStatusResponse(text: string): void {
        const lines = text.trim().split("\n");
        
        // Build key-value map (skip first "OK" line)
        const kv = {};
        for (let i = 1; i < lines.length; i++) {
            const line = lines[i];
            const idx = line.indexOf("=");
            if (idx > 0) {
                const key = line.substring(0, idx);
                const value = line.substring(idx + 1);
                kv[key] = value;
            }
            // Unknown keys ignored (forward compatibility)
        }
        
        // Update state from map
        if ("available" in kv) {
            root._available = kv["available"] === "true";
        }
        if ("has_state" in kv) {
            root._hasState = kv["has_state"] === "true";
        }
        if ("effect" in kv) {
            root._effect = kv["effect"];
        }
        if ("colors" in kv && kv["colors"]) {
            root._colors = kv["colors"].split(",");
        }
        if ("direction" in kv) {
            root._direction = kv["direction"];
        }
        if ("brightness" in kv) {
            root._brightness = parseInt(kv["brightness"]) || 1;
        }
        if ("speed" in kv) {
            root._speed = parseInt(kv["speed"]) || 1;
        }
    }
}
