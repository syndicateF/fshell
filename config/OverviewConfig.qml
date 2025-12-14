import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool showOnHover: true
    property int mediaUpdateInterval: 500
    property int dragThreshold: 50
    property Sizes sizes: Sizes {}
    
    // Special workspaces config
    property var specialWorkspaces: ["sysmon", "music", "communication", "todo"]
    property var specialWorkspaceApps: ({
        "sysmon": { "icon": "net.nokyan.Resources", "command": "resources", "app": "Resources" },
        "music": { "icon": "spotify", "command": "spotify", "app": "Spotify" },
        "communication": { "icon": "discord", "command": "discord", "app": "Discord" },
        "todo": { "icon": "io.elementary.tasks", "command": "todoist", "app": "Todoist" }
    })

    component Sizes: JsonObject {
        property real scale: 0.13  // Scale for workspace overview thumbnails
        readonly property int workspacePreviewWidth: 200
        readonly property int tabIndicatorHeight: 3
        readonly property int tabIndicatorSpacing: 5
        readonly property int infoWidth: 200
        readonly property int infoIconSize: 25
        readonly property int dateTimeWidth: 110
        readonly property int mediaWidth: 200
        readonly property int mediaProgressSweep: 180
        readonly property int mediaProgressThickness: 8
        readonly property int resourceProgessThickness: 10
        readonly property int weatherWidth: 250
        readonly property int mediaCoverArtSize: 150
        readonly property int mediaVisualiserSize: 80
        readonly property int resourceSize: 200
        
        // Font sizes with DESCRIPTIVE names
        readonly property int workspaceNumberWatermark: 15  // Faded workspace number (was 20px → 15pt)
    }
}
