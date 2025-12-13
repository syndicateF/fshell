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
            } else {
                // Close launcher for system commands (shutdown, reboot, lock, etc)
                gridContent.visibilities.launcher = false;
                Quickshell.execDetached(command);
            }
        }
    }
}
