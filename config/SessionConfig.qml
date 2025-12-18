import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool vimKeybinds: false
    property Commands commands: Commands {}

    property Sizes sizes: Sizes {}

    component Commands: JsonObject {
        property list<string> logout: ["loginctl", "terminate-user", ""]
        property list<string> shutdown: ["systemctl", "poweroff"]
        property list<string> hibernate: ["systemctl", "hibernate"]
        property list<string> reboot: ["systemctl", "reboot"]
        property list<string> sleep: ["systemctl", "suspend"]
    }

    component Sizes: JsonObject {
        property int button: 100
        property int countdownSecs: 10
    }
}