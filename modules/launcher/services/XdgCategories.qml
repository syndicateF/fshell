pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

/**
 * XdgCategories — mapping XDG desktop categories ke display info.
 *
 * Drop ke: modules/launcher/services/XdgCategories.qml
 *
 * API:
 *   XdgCategories.buildAutoCategories(appList)
 *       → list<{id, name, icon}> hanya kategori yang punya ≥1 app
 *   XdgCategories.filterApps(appList, categoryId)
 *       → list app yang cocok, "home" return semua
 *   XdgCategories.primaryFor(app)
 *       → {id, name, icon} kategori terbaik, atau null
 */
QtObject {
    id: root

    // ── XDG category table ────────────────────────────────────────────
    // Urutan = prioritas (primaryFor ambil yang pertama cocok)
    readonly property var _table: [
        { id: "Development",  name: qsTr("Development"),  icon: "code",           xdg: ["Development","IDE","Debugger","Building","RevisionControl","WebDevelopment","Translation"] },
        { id: "Game",         name: qsTr("Games"),        icon: "sports_esports", xdg: ["Game","ActionGame","AdventureGame","ArcadeGame","BoardGame","BlocksGame","CardGame","KidsGame","LogicGame","RolePlaying","Shooter","Simulation","SportsGame","StrategyGame"] },
        { id: "Graphics",     name: qsTr("Graphics"),     icon: "palette",        xdg: ["Graphics","2DGraphics","3DGraphics","Photography","RasterGraphics","VectorGraphics","Viewer","ImageProcessing"] },
        { id: "AudioVideo",   name: qsTr("Multimedia"),   icon: "movie",          xdg: ["AudioVideo","Audio","Video","Music","Player","Recorder"] },
        { id: "Network",      name: qsTr("Internet"),     icon: "public",         xdg: ["Network","Chat","Email","Feed","FileTransfer","InstantMessaging","IRCClient","News","WebBrowser","VideoConference","RemoteAccess"] },
        { id: "Office",       name: qsTr("Office"),       icon: "description",    xdg: ["Office","Calendar","ContactManagement","Database","Dictionary","Finance","Presentation","Spreadsheet","WordProcessor","FlowChart"] },
        { id: "Science",      name: qsTr("Science"),      icon: "biotech",        xdg: ["Science","Astronomy","Biology","Chemistry","Math","Physics","Geography","MedicalSoftware"] },
        { id: "Settings",     name: qsTr("Settings"),     icon: "settings",       xdg: ["Settings","Accessibility","DesktopSettings","HardwareSettings","Security","Printing"] },
        { id: "System",       name: qsTr("System"),       icon: "computer",       xdg: ["System","FileManager","Filesystem","TerminalEmulator","PackageManager","Emulator"] },
        { id: "Utility",      name: qsTr("Utilities"),    icon: "build",          xdg: ["Utility","Archiving","Compression","Clock","TextEditor","FileTools","Calculator"] },
        { id: "Education",    name: qsTr("Education"),    icon: "school",         xdg: ["Education","Languages","Literature"] },
    ]

    // ── Helpers ───────────────────────────────────────────────────────

    function _toCatArray(app) {
        const raw = app.categories;
        if (!raw) return [];
        if (Array.isArray(raw)) return raw.map(s => String(s).trim()).filter(Boolean);
        return String(raw).split(";").map(s => s.trim()).filter(Boolean);
    }

    function primaryFor(app) {
        const cats = _toCatArray(app);
        for (let i = 0; i < root._table.length; i++) {
            if (root._table[i].xdg.some(tag => cats.includes(tag)))
                return root._table[i];
        }
        return null;
    }

    /**
     * Dari appList, return hanya kategori XDG yang punya ≥1 app,
     * dalam urutan yang sama seperti _table.
     */
    function buildAutoCategories(appList) {
        const seen = new Set();
        for (let i = 0; i < appList.length; i++) {
            const p = primaryFor(appList[i]);
            if (p) seen.add(p.id);
        }
        return root._table
            .filter(e => seen.has(e.id))
            .map(e => ({ id: e.id, name: e.name, icon: e.icon }));
    }

    /**
     * Filter appList untuk category id tertentu.
     * "home" → return semua (non-null).
     */
    function filterApps(appList, categoryId) {
        if (categoryId === "home") return appList.filter(Boolean);
        const entry = root._table.find(e => e.id === categoryId);
        if (!entry) return [];
        return appList.filter(app => {
            if (!app) return false;
            const cats = _toCatArray(app);
            return entry.xdg.some(tag => cats.includes(tag));
        });
    }
}
