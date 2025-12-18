import ".."
import QtQuick
import QtQuick.Effects

MultiEffect {
    property color sourceColor: "black"

    // Always full colorization for text - icons handle their own colorization separately
    colorization: 1
    brightness: 1 - sourceColor.hslLightness

    Behavior on colorizationColor {
        CAnim {}
    }
}
