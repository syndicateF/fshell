pragma ComponentBehavior: Bound

import qs.components
import qs.components.filedialog
import qs.config
import qs.utils
import Caelestia
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property var popouts
    readonly property PersistentProperties dashState: PersistentProperties {
        property int currentTab
        property date currentDate: new Date()

        reloadableId: "dashboardState"
    }
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property real nonAnimHeight: isVisible ? (content.item?.nonAnimHeight ?? 0) : 0
    
    // Track visibility tanpa State untuk hindari binding loop
    readonly property bool isVisible: visibilities.overview && Config.overview.enabled
    property real targetImplicitHeight: 0
    
    // Track apakah sedang opening atau closing untuk animasi yang benar
    property bool isOpening: false

    visible: height > 0
    implicitHeight: targetImplicitHeight
    // Pakai content.implicitWidth (dari Loader) untuk width yang benar
    implicitWidth: content.implicitWidth
    
    // Update targetImplicitHeight saat visibility atau content berubah
    onIsVisibleChanged: {
        if (isVisible) {
            isOpening = true
            // Delay sedikit untuk pastikan content sudah loaded
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
            // Opening: pakai expressiveDefaultSpatial, Closing: pakai emphasized
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
            state: root.dashState
            facePicker: root.facePicker
        }
    }
}
