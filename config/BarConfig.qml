import Quickshell.Io

JsonObject {
    property bool persistent: true
    property bool showOnHover: true
    property int dragThreshold: 20
    property ScrollActions scrollActions: ScrollActions {}
    property Popouts popouts: Popouts {}
    property Workspaces workspaces: Workspaces {}
    property ActiveWindow activeWindow: ActiveWindow {}
    property Tray tray: Tray {}
    property Status status: Status {}
    property Clock clock: Clock {}
    property Sizes sizes: Sizes {}

    // Bar layout dengan 3 section: top (anchored ke atas), center (anchored ke tengah), bottom (anchored ke bawah)
    // NOTE: workspaces dipindahkan ke TopWorkspacesPanel (horizontal, top center screen)
    property list<var> topEntries: [
        { id: "networkIcon", enabled: true },
        { id: "networkTraffic", enabled: true },
    ]
    
    property list<var> centerEntries: [
        { id: "dashboardIcons", enabled: true },
        { id: "activeWindow", enabled: true },
        { id: "clock", enabled: true }
    ]
    
    property list<var> bottomEntries: [
        { id: "tray", enabled: true },
        { id: "statusIcons", enabled: true },
        { id: "powerMode", enabled: true },
        { id: "batteryIcon", enabled: true },
        { id: "power", enabled: false }
    ]

    component ScrollActions: JsonObject {
        property bool workspaces: true
        property bool volume: true
        property bool brightness: true
    }

    component Popouts: JsonObject {
        property bool activeWindow: true
        property bool tray: true
        property bool statusIcons: true
    }

    component Workspaces: JsonObject {
        property int shown: 10
        property int topWorkspacesHeight: 31  // Height untuk occupied bg dan active indicator
        property int topWorkspacesContainerHeight: 40  // Height untuk container/content
        property int topWorkspacesSpacing: 5  // Horizontal spacing antar workspace items
        property int topWorkspacesHPadding: 5  // Horizontal padding kiri-kanan container
        property bool activeIndicator: true
        property bool occupiedBg: true
        property bool hideActiveLabel: true  // Hide label untuk workspace yang aktif
        property bool showWindows: true
        property bool showWindowsOnSpecialWorkspaces: showWindows
        property string windowIconStyle: "icon"  // "icon" = app icons, "category" = category symbols, "custom" = custom symbol
        property string windowIconCustomSymbol: "•"  //"⚫"  // custom symbol when windowIconStyle is "custom"
        property bool activeTrail: true
        property bool perMonitorWorkspaces: true
        property string label: ""//"⚫"//"•"//"●" // if empty, will show workspace name's first letter
        property string occupiedLabel: "" //"󰮯"
        property string activeLabel: ""  //"󰮯"
        property string capitalisation: "preserve" // upper, lower, or preserve - relevant only if label is empty
        property list<var> specialWorkspaceIcons: []
    }

    component ActiveWindow: JsonObject {
        property bool inverted: false
    }

    component Tray: JsonObject {
        property bool background: false
        property bool recolour: false
        property bool compact: false
        property list<var> iconSubs: []
    }

    component Status: JsonObject {
        property bool showAudio: false
        property bool showMicrophone: false
        property bool showKbLayout: false
        property bool showNetwork: true
        property bool showBluetooth: true
        property bool showBattery: true
        property bool showLockStatus: true
    }

    component Clock: JsonObject {
        property bool showIcon: true
    }

    component Sizes: JsonObject {
        property int innerWidth: 40
        property int itemPadding: 10  // Vertical padding untuk items (kecuali workspaces)
        property int iconSize: 22  // Icon size for app icons (pixelSize)
        property int materialIconSize: 15  // Material icon size (pointSize) - same as Appearance.font.size.larger
        property int windowPreviewSize: 400
        property int trayMenuWidth: 300
        property int batteryWidth: 250
        property int networkWidth: 320
        
        // Bar text style (PowerMode style) - untuk semua teks di bar
        property int textPixelSize: 15  // font.pixelSize
        property int textWeight: 450    // font.variableAxes wght
        property int textWidth: 100     // font.variableAxes wdth
    }
}
