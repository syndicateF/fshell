pragma Singleton
import Quickshell
import QtQuick

// AI Service - DISABLED
// To re-enable, rename AI.qml.disabled back to AI.qml
Singleton {
    id: root
    readonly property bool connected: false
    readonly property bool connecting: false
    readonly property bool loading: false
    readonly property bool streaming: false
    readonly property string currentProvider: ""
    readonly property string currentModel: ""
    readonly property string activeConversationId: ""
    readonly property string streamingContent: ""
    readonly property bool hasError: true
    readonly property string errorMessage: "AI service disabled"
    property ListModel conversations: ListModel {}
    property ListModel currentMessages: ListModel {}
    
    function sendMessage() {}
    function newConversation() {}
    function loadConversation() {}
    function refreshConversations() {}
}
