pragma Singleton

import ".."
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    function transformSearch(search: string): string {
        // No longer need to strip prefix since we use tabs now
        return search;
    }

    list: variants.instances
    useFuzzy: Config.launcher.useFuzzy.actions

    Variants {
        id: variants

        model: Config.launcher.actions.filter(a => (a.enabled ?? true) && (Config.launcher.enableDangerousActions || !(a.dangerous ?? false)))

        Action {}
    }

    component Action: QtObject {
        required property var modelData
        readonly property string name: modelData.name ?? qsTr("Unnamed")
        readonly property string desc: modelData.description ?? qsTr("No description")
        readonly property string icon: modelData.icon ?? "help_outline"
        readonly property list<string> command: modelData.command ?? []
        readonly property bool enabled: modelData.enabled ?? true
        readonly property bool dangerous: modelData.dangerous ?? false

        function onClicked(gridContent: var): void {
            if (command.length === 0)
                return;

            // Handle autocomplete commands by switching to Tools tab with appropriate mode
            if (command[0] === "autocomplete" && command.length > 1) {
                const toolType = command[1];
                if (gridContent && gridContent.content) {
                    gridContent.content.currentTab = 2; // Switch to Tools tab
                    gridContent.content.toolsMode = toolType; // Set the tool mode
                }
            } else if (command[0] === "setMode" && command.length > 1) {
                // Don't close launcher for mode change - let user see the change
                Colours.setMode(command[1]);
            } else if (dangerous && command.length >= 2) {
                // Route dangerous power actions through SessionManager service
                // force=true because user clicked action directly (no separate confirmation)
                gridContent.visibilities.launcher = false;
                
                const cmd0 = command[0];
                const cmd1 = command[1];
                
                if (cmd0 === "systemctl" && cmd1 === "poweroff") {
                    SessionManager.shutdown(true);  // force=true
                } else if (cmd0 === "systemctl" && cmd1 === "reboot") {
                    SessionManager.reboot(true);  // force=true
                } else if (cmd0 === "loginctl" && cmd1 === "terminate-user") {
                    // Logout - fallback to direct command (SessionManager doesn't handle logout yet)
                    Quickshell.execDetached(command);
                } else {
                    // Other dangerous commands - direct exec
                    Quickshell.execDetached(command);
                }
            } else {
                // Non-dangerous system commands (lock, sleep, etc)
                gridContent.visibilities.launcher = false;
                
                // Route suspend through SessionManager for consistency
                if (command[0] === "systemctl" && (command[1] === "suspend" || command[1] === "suspend-then-hibernate")) {
                    SessionManager.suspend();
                } else {
                    Quickshell.execDetached(command);
                }
            }
        }
    }
}
