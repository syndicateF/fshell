//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import qs.services
import Quickshell
import QtQuick

ShellRoot {
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }
    
    // Initialize RGB keyboard on shell start
    // Only calls RGB connect, doesn't load all Hardware refreshes
    // Uses small delay to let shell fully initialize first
    Timer {
        id: rgbInitTimer
        interval: 500
        running: true
        repeat: false
        onTriggered: Hardware.refreshRgb()
    }
}
