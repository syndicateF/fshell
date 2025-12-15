import qs.config
import qs.services
import Caelestia
import Quickshell
import Quickshell.Services.UPower
import QtQuick

// BatteryMonitor - low battery warnings and hibernate trigger
Scope {
    id: root

    readonly property list<var> warnLevels: [...Config.general.battery.warnLevels].sort((a, b) => b.level - a.level)

    Connections {
        target: UPower.displayDevice

        function onStateChanged(): void {
            if (UPower.displayDevice.state === UPowerDeviceState.Charging) {
                if (Config.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                for (const level of root.warnLevels)
                    level.warned = false;
            } else if (UPower.displayDevice.state === UPowerDeviceState.Discharging) {
                if (Config.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
            }
        }

        function onPercentageChanged(): void {
            if (UPower.displayDevice.state === UPowerDeviceState.Charging || 
                UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
                return;

            // UPower.displayDevice.percentage is 0.0-1.0, convert to 0-100
            const p = UPower.displayDevice.percentage * 100;
            for (const level of root.warnLevels) {
                if (p <= level.level && !level.warned) {
                    level.warned = true;
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                }
            }

            if (!hibernateTimer.running && p <= Config.general.battery.criticalLevel) {
                Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
                hibernateTimer.start();
            }
        }
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
    }
}
