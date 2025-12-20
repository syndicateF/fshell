pragma Singleton

import qs.services
import qs.config
import Caelestia
import Quickshell
import QtQuick

/**
 * MediaPalette - Album Art Color Extraction Service
 * 
 * Simple service that exposes dominant color from album art.
 * UI components should use their own ImageAnalyser for now,
 * and this service provides convenient computed palette colors.
 */
Singleton {
    id: root

    // ========== Input ==========
    // Track art URL from active player
    readonly property url artUrl: Players.active?.trackArtUrl ?? ""
    
    // ========== Raw Color (must be set by UI with ImageAnalyser) ==========
    // UI should bind their ImageAnalyser.dominantColour here
    property color dominantColor: Colours.palette.m3primary
    
    // ========== Computed Properties ==========
    readonly property bool hasPlayer: Players.active !== null
    readonly property bool hasArt: artUrl.toString() !== ""
    
    // Dark mode check
    readonly property bool isDark: !Colours.light
    
    // ========== Simple Color Processing ==========
    // Boost low saturation colors
    readonly property color sourceColor: {
        const raw = dominantColor;
        let h = raw.hslHue;
        let s = raw.hslSaturation;
        let l = raw.hslLightness;
        
        // Boost low saturation
        if (s < 0.25) {
            s = 0.35 + s;
        } else if (s < 0.4) {
            s = s * 1.5;
        }
        
        // Adjust extreme lightness
        if (l < 0.15) {
            l = 0.35;
        } else if (l > 0.85) {
            l = 0.55;
        }
        
        s = Math.min(1.0, s);
        return Qt.hsla(h, s, l, 1.0);
    }
    
    // ========== Palette Functions ==========
    function toneColor(baseColor: color, targetLightness: real): color {
        return Qt.hsla(baseColor.hslHue, baseColor.hslSaturation, targetLightness, 1.0);
    }
    
    // ========== Output Palette ==========
    // Main accent (softened)
    readonly property color accent: {
        const newL = isDark 
            ? Math.min(0.65, sourceColor.hslLightness + 0.20)
            : Math.max(0.35, sourceColor.hslLightness - 0.10);
        return Qt.hsla(sourceColor.hslHue, sourceColor.hslSaturation, newL, 1.0);
    }
    
    // Primary colors
    readonly property color primary: toneColor(sourceColor, isDark ? 0.70 : 0.40)
    readonly property color onPrimary: isDark ? "#1a1a1a" : "#ffffff"
    
    // Surface variant
    readonly property color onSurfaceVariant: isDark 
        ? toneColor(sourceColor, 0.65) 
        : toneColor(sourceColor, 0.35)
}
