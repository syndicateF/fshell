pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import qs.utils
import QtQuick

Item {
    id: root

    property var groups: []   // list<{ id, name, icon, apps: string[] }>

    readonly property string _configPath: Paths.config + "/launcher-groups.json"

    FileView {
        id: fileView
        path:       root._configPath
        watchChanges: true

        onLoaded: {
            if (!text || text.trim() === "") { root.groups = []; return; }
            try {
                const parsed = JSON.parse(text);
                root.groups = parsed.groups || [];
            } catch (e) {
                console.warn("[GroupsConfig] JSON parse error:", e);
                root.groups = [];
            }
        }

        onLoadFailed: {
            root.groups = [];
        }
    }

    Component.onCompleted: fileView.reload()

    Process {
        id: _writer
    }

    function _save() {
        const json = JSON.stringify({ groups: root.groups }, null, 2);
        const escaped = json.replace(/'/g, "'\\''");
        _writer.command = [
            "bash", "-c",
            `mkdir -p "$(dirname '${root._configPath}')" && printf '%s' '${escaped}' > '${root._configPath}'`
        ];
        _writer.startDetached();
    }

    function _genId(name) {
        return name.toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-|-$/g, "")
            .slice(0, 20)
            + "-" + Date.now().toString(36);
    }

    function addGroup(name, icon) {
        if (!name || !name.trim()) return "";
        const g = { id: _genId(name), name: name.trim(), icon: icon || "folder", apps: [] };
        root.groups = root.groups.concat([g]);
        _save();
        return g.id;
    }

    function removeGroup(id) {
        root.groups = root.groups.filter(g => g.id !== id);
        _save();
    }

    function renameGroup(id, newName) {
        if (!newName || !newName.trim()) return;
        root.groups = root.groups.map(g => g.id === id ? Object.assign({}, g, { name: newName.trim() }) : g);
        _save();
    }

    function setGroupIcon(id, icon) {
        root.groups = root.groups.map(g => g.id === id ? Object.assign({}, g, { icon: icon }) : g);
        _save();
    }

    function addAppToGroup(groupId, appId) {
        root.groups = root.groups.map(g => {
            if (g.id !== groupId || g.apps.includes(appId)) return g;
            return Object.assign({}, g, { apps: g.apps.concat([appId]) });
        });
        _save();
    }

    function removeAppFromGroup(groupId, appId) {
        root.groups = root.groups.map(g =>
            g.id !== groupId ? g : Object.assign({}, g, { apps: g.apps.filter(a => a !== appId) })
        );
        _save();
    }

    function getAppsForGroup(groupId) {
        const g = root.groups.find(g => g.id === groupId);
        return g ? g.apps : [];
    }
}
