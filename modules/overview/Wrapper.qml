pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property var popouts

    readonly property real nonAnimHeight: isVisible ? (content.item?.nonAnimHeight ?? 0) : 0
    
    // Track visibility tanpa State untuk hindari binding loop
    readonly property bool isVisible: visibilities.overview && Config.overview.enabled
    property real targetImplicitHeight: 0
    
    // Track apakah sedang opening atau closing untuk animasi yang benar
    property bool isOpening: false

    visible: height > 0
    implicitHeight: targetImplicitHeight
    // Pakai content.implicitWidth, fallback ke calculated width saat belum loaded
    implicitWidth: content.implicitWidth > 0 ? content.implicitWidth : defaultOverviewWidth
    
    // Calculated default width untuk hover area sebelum content loaded
    readonly property real defaultOverviewWidth: {
        const monitorWidth = screen?.width ?? 1920
        const scale = Config.overview.sizes.scale
        const columns = 5
        const spacing = 5
        const padding = 20
        return (monitorWidth * scale * columns) + ((columns - 1) * spacing) + (padding * 2)
    }
    
    // Update targetImplicitHeight saat visibility atau content berubah
    onIsVisibleChanged: {
        if (isVisible) {
            isOpening = true
            Qt.callLater(() => {
                targetImplicitHeight = content.item?.implicitHeight ?? 0
            })
            if (timer.running) {
                timer.triggered();
                timer.stop();
            }
        } else {
            isOpening = false
            targetImplicitHeight = 0
        }
    }
    
    // Update height saat content height berubah (saat visible)
    Connections {
        target: content.item
        enabled: root.isVisible
        function onImplicitHeightChanged() {
            root.targetImplicitHeight = content.item?.implicitHeight ?? 0
        }
    }
    
    // Behavior untuk animate implicitHeight
    Behavior on implicitHeight {
        Anim {
            duration: root.isOpening ? Appearance.anim.durations.expressiveDefaultSpatial : Appearance.anim.durations.normal
            easing.bezierCurve: root.isOpening ? Appearance.anim.curves.expressiveDefaultSpatial : Appearance.anim.curves.emphasized
        }
    }

    Timer {
        id: timer

        running: true
        interval: Appearance.anim.durations.extraLarge
        onTriggered: {
            content.active = Qt.binding(() => root.visibilities.overview && Config.overview.enabled);
            content.visible = true;
        }
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        visible: false
        active: root.visibilities.overview && Config.overview.enabled

        sourceComponent: Content {
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }
}
