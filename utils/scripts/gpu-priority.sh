#!/bin/bash
# GPU Priority Switcher for Hyprland
# Usage: gpu-priority.sh [get|set|toggle] [nvidia|integrated]

HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

# GPU paths (using stable symlinks from udev rules)
NVIDIA_GPU="/dev/dri/nvidia-dgpu"
AMD_GPU="/dev/dri/amd-igpu"

get_current_mode() {
    local primary
    primary=$(grep "AQ_DRM_DEVICES" "$HYPR_CONFIG" | head -1 | sed 's/.*,\([^:]*\):.*/\1/' | xargs basename 2>/dev/null)
    
    case "$primary" in
        "amd-igpu"|"card0")
            echo "integrated"
            ;;
        "nvidia-dgpu"|"card1")
            echo "nvidia"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

set_mode() {
    local mode="$1"
    
    case "$mode" in
        "nvidia")
            # Set NVIDIA as primary
            sed -i "s|env = WLR_DRM_DEVICES,.*|env = WLR_DRM_DEVICES,$NVIDIA_GPU:$AMD_GPU|" "$HYPR_CONFIG"
            sed -i "s|env = AQ_DRM_DEVICES,.*|env = AQ_DRM_DEVICES,$NVIDIA_GPU:$AMD_GPU|" "$HYPR_CONFIG"
            echo "nvidia"
            ;;
        "integrated")
            # Set AMD iGPU as primary
            sed -i "s|env = WLR_DRM_DEVICES,.*|env = WLR_DRM_DEVICES,$AMD_GPU:$NVIDIA_GPU|" "$HYPR_CONFIG"
            sed -i "s|env = AQ_DRM_DEVICES,.*|env = AQ_DRM_DEVICES,$AMD_GPU:$NVIDIA_GPU|" "$HYPR_CONFIG"
            echo "integrated"
            ;;
        *)
            echo "error: invalid mode '$mode'. Use 'nvidia' or 'integrated'"
            exit 1
            ;;
    esac
}

toggle_mode() {
    local current
    current=$(get_current_mode)
    
    if [[ "$current" == "nvidia" ]]; then
        set_mode "integrated"
    else
        set_mode "nvidia"
    fi
}

case "$1" in
    "get")
        get_current_mode
        ;;
    "set")
        if [[ -z "$2" ]]; then
            echo "error: missing mode argument"
            exit 1
        fi
        set_mode "$2"
        ;;
    "toggle")
        toggle_mode
        ;;
    *)
        echo "Usage: $0 [get|set|toggle] [nvidia|integrated]"
        echo ""
        echo "Commands:"
        echo "  get              - Get current GPU priority mode"
        echo "  set <mode>       - Set GPU priority (nvidia|integrated)"
        echo "  toggle           - Toggle between nvidia and integrated"
        echo ""
        echo "Note: Changes require logout/login or reboot to take effect."
        exit 1
        ;;
esac
