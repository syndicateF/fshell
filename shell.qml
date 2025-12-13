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
    // Uses a longer delay on cold boot because OpenRGB server 
    // may take 5-10 seconds to fully initialize after boot.
    // The Hardware service has exponential backoff retry mechanism
    // if initial connection fails.
    Timer {
        id: rgbInitTimer
        interval: 2000  // 2 second initial delay
        running: true
        repeat: false
        onTriggered: Hardware.refreshRgb()
    }
}
