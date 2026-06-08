import ".."
import QtQuick

ListView {
    id: root

    maximumFlickVelocity: 3000

    rebound: Transition {
        Anim {
            properties: "x,y"
        }
    }

    WheelHandler {
        acceptedDevices:   PointerDevice.Mouse | PointerDevice.TouchPad
        acceptedModifiers: Qt.NoModifier
        property:          "contentY"
        rotationScale:     4
    }
}
