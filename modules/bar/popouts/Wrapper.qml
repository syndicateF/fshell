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
        // Normal logic - return width when there's something to show
        if (x > 0 || hasCurrent) {
            return children.find(c => c.shouldBeActive)?.implicitWidth ?? content.implicitWidth;
        }
        return 0;
    }
    readonly property real nonAnimHeight: {
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

    property int animLength: Appearance.anim.durations.normal
    property list<real> animCurve: Appearance.anim.curves.emphasized
    
    // Height animation enabled only during open/close, not content changes
    property bool heightAnimEnabled: false

    function detach(mode: string): void {
        animLength = Appearance.anim.durations.large;
        
        // Loading - SAMA PERSIS dengan winfo!
        // 1. Set currentName dan hasCurrent dulu (Content Popout "loading" muncul)
        // 2. Baru set detachedMode (trigger animate ke center)
        if (mode === "loading") {
            currentName = "loading";  // Content Popout "loading" active!
            currentCenter = QsWindow.window.height / 2;
            hasCurrent = true;  // Content visible di bar
            loadingMinDurationMet = false;
            loadingAppReady = false;
            minDurationTimer.restart();
            detachedMode = mode;  // WindowInfo Comp active, Content inactive
        } else if (mode === "winfo") {
            detachedMode = mode;
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
        // Enable height animation for close transition
        heightAnimEnabled = true;
        animCurve = Appearance.anim.curves.emphasizedAccel;
        animLength = Appearance.anim.durations.large;
        hasCurrent = false;
        detachedMode = "";
        loadingWsName = "";
        loadingAppInfo = {};
        animCurve = Appearance.anim.curves.emphasized;
    }
    
    // Disable height animation after open transition completes
    // Content handles its own height changes (e.g., calendar expand/collapse)
    onHasCurrentChanged: {
        if (hasCurrent) {
            heightAnimEnabled = true;  // Enable for open
            heightAnimDisableTimer.restart();
        }
    }
    
    // Re-enable height animation when switching between popouts
    onCurrentNameChanged: {
        if (hasCurrent && currentName.length > 0) {
            heightAnimEnabled = true;  // Enable for popout switch
            heightAnimDisableTimer.restart();
        }
    }
    
    Timer {
        id: heightAnimDisableTimer
        interval: animLength + 50  // Wait for open animation to finish
        onTriggered: heightAnimEnabled = false
    }

    Timer {
        id: minDurationTimer
        interval: 2000
        onTriggered: {
            root.loadingMinDurationMet = true;
            if (root.loadingAppReady) {
                root.close();  // SAMA!
            }
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

    // Loading - SAMA PERSIS seperti WindowInfo, pakai Comp!
    Comp {
        id: loadingComp
        shouldBeActive: root.detachedMode === "loading"
        asynchronous: true
        anchors.centerIn: parent

        sourceComponent: LoadingInfo {
            wsName: root.loadingWsName
            appInfo: root.loadingAppInfo
        }
    }

    Comp {
        shouldBeActive: root.detachedMode === "any"
        asynchronous: false  // Sync load to prevent first-open shrink
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
            // 350ms matches CalendarPopout rootWrapper Behavior for content height changes
            // animLength for open/close transitions
            duration: root.heightAnimEnabled ? root.animLength : 350
            easing.bezierCurve: root.heightAnimEnabled ? root.animCurve : Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on implicitHeight {
        // Only animate during open/close, not during content changes
        enabled: root.implicitWidth > 0 && root.heightAnimEnabled

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
