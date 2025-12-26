pragma ComponentBehavior: Bound

import Caelestia
import Quickshell.Widgets
import QtQuick

IconImage {
    id: root

    required property color colour

    asynchronous: true

    // Only enable layer effect when image is ready - prevents ShaderEffect 'source' warning
    layer.enabled: status === Image.Ready
    layer.effect: Colouriser {
        sourceColor: analyser.dominantColour
        colorizationColor: root.colour
    }

    onStatusChanged: {
        if (layer.enabled && status === Image.Ready)
            analyser.requestUpdate();
    }

    ImageAnalyser {
        id: analyser

        sourceItem: root
    }
}

