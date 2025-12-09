pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.modules.windowinfo
import qs.modules.controlcenter
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Item {
    id: root

    required property ShellScreen screen

    readonly property real nonAnimWidth: {
        // For loading, use loadingComp's item size
        if (loadingActive && loadingComp.item) {
            return loadingComp.item.implicitWidth;
        }
        // Normal logic - return width when there's something to show
        if (x > 0 || hasCurrent) {
            return children.find(c => c.shouldBeActive)?.implicitWidth ?? content.implicitWidth;
        }
        return 0;
    }
    readonly property real nonAnimHeight: {
        // For loading, use loadingComp's item size
        if (loadingActive && loadingComp.item) {
            return loadingComp.item.implicitHeight;
        }
        // Normal logic
        return children.find(c => c.shouldBeActive)?.implicitHeight ?? content.implicitHeight;
    }
    readonly property Item current: content.item?.current ?? null

    property string currentName
    property real currentCenter
    property bool hasCurrent

    property string detachedMode
    property string queuedMode
    readonly property bool isDetached: detachedMode.length > 0

    // Loading state
    property string loadingWsName: ""
    property var loadingAppInfo: ({})
    property bool loadingMinDurationMet: false
    property bool loadingAppReady: false
    property bool loadingActive: false  // True while loading is visible (open -> close animation complete)

    property int animLength: Appearance.anim.durations.normal
    property list<real> animCurve: Appearance.anim.curves.emphasized

    function detach(mode: string): void {
        animLength = Appearance.anim.durations.large;
        if (mode === "winfo") {
            detachedMode = mode;
        } else if (mode === "loading") {
            // Single duration for all loading animation
            animLength = Appearance.anim.durations.extraLarge;
            loadingActive = true;
            hasCurrent = true;
            currentCenter = QsWindow.window.height / 2;
            loadingMinDurationMet = false;
            loadingAppReady = false;
            minDurationTimer.restart();
            // Long delay to test - stay at bar first
            loadingDetachTimer.start();
        } else {
            detachedMode = "any";
            queuedMode = mode;
        }
        focus = true;
    }

    function closeLoading(): void {
        if (detachedMode === "loading") {
            loadingAppReady = true;
            if (loadingMinDurationMet) {
                close();
            }
        }
    }

    function close(): void {
        animCurve = Appearance.anim.curves.emphasizedAccel;
        animLength = Appearance.anim.durations.large;
        
        // For loading mode, we need to animate back to bar first before clearing
        if (detachedMode === "loading") {
            // First, keep hasCurrent true but clear detachedMode
            // This makes x go back to 0 (bar position) while keeping width
            detachedMode = "";
            // Then after animation, clear everything
            loadingCloseTimer.start();
        } else {
            // Normal close for other modes
            hasCurrent = false;
            detachedMode = "";
            loadingWsName = "";
            loadingAppInfo = {};
            animCurve = Appearance.anim.curves.emphasized;
        }
    }

    Timer {
        id: loadingCloseTimer
        interval: Appearance.anim.durations.large
        onTriggered: {
            root.hasCurrent = false;
            root.loadingActive = false;
            root.loadingWsName = "";
            root.loadingAppInfo = {};
            root.animCurve = Appearance.anim.curves.emphasized;
        }
    }

    Timer {
        id: loadingDetachTimer
        interval: 2000  // 2 detik delay di bar sebelum animate ke tengah - TESTING
        onTriggered: {
            root.detachedMode = "loading";
        }
    }

    Timer {
        id: minDurationTimer
        interval: 2000
        onTriggered: {
            root.loadingMinDurationMet = true;
            if (root.loadingAppReady) root.close();
        }
    }

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Keys.onEscapePressed: close()

    HyprlandFocusGrab {
        active: root.isDetached
        windows: [QsWindow.window]
        onCleared: root.close()
    }

    Binding {
        when: root.isDetached

        target: QsWindow.window
        property: "WlrLayershell.keyboardFocus"
        value: WlrKeyboardFocus.OnDemand
    }

    Comp {
        id: content

        shouldBeActive: root.hasCurrent && !root.detachedMode
        asynchronous: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        sourceComponent: Content {
            wrapper: root
        }
    }

    Comp {
        shouldBeActive: root.detachedMode === "winfo"
        asynchronous: true
        anchors.centerIn: parent

        sourceComponent: WindowInfo {
            screen: root.screen
            client: Hypr.activeToplevel
        }
    }

    // Loading uses Loader directly (not Comp) to avoid opacity fade animation
    // Animation is purely from position (x) and size (width/height)
    Loader {
        id: loadingComp
        
        property bool shouldBeActive: root.loadingActive
        
        // Return the actual content size for nonAnimWidth/Height calculation
        readonly property real contentWidth: item?.implicitWidth ?? 0
        readonly property real contentHeight: item?.implicitHeight ?? 0

        active: shouldBeActive
        asynchronous: false  // Load synchronously so width is available immediately
        anchors.centerIn: parent

        sourceComponent: LoadingInfo {
            wsName: root.loadingWsName
            appInfo: root.loadingAppInfo
        }
    }

    Comp {
        shouldBeActive: root.detachedMode === "any"
        asynchronous: true
        anchors.centerIn: parent

        sourceComponent: ControlCenter {
            screen: root.screen
            active: root.queuedMode

            function close(): void {
                root.close();
            }
        }
    }

    Behavior on x {
        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on y {
        enabled: root.implicitWidth > 0

        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on implicitHeight {
        enabled: root.implicitWidth > 0

        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    component Comp: Loader {
        id: comp

        property bool shouldBeActive

        asynchronous: true
        active: false
        opacity: 0

        states: State {
            name: "active"
            when: comp.shouldBeActive

            PropertyChanges {
                comp.opacity: 1
                comp.active: true
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                    Anim {
                        property: "opacity"
                    }
                }
            },
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        property: "opacity"
                    }
                    PropertyAction {
                        property: "active"
                    }
                }
            }
        ]
    }
}
