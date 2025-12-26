pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * AI Service - Data binding layer between x-ai daemon and QML UI.
 * 
 * IMPORTANT: This service contains ZERO AI logic.
 * All intelligence resides in the x-ai daemon.
 * This is purely for IPC and state synchronization.
 */
Singleton {
    id: root

    // === Connection State ===
    readonly property bool connected: socket.connected
    readonly property bool connecting: _connecting
    readonly property int reconnectAttempts: _reconnectAttempts

    // === Loading State ===
    readonly property bool loading: _loading
    readonly property bool streaming: _streaming

    // === Provider State ===
    readonly property string currentProvider: _provider  // "openai" | "ollama"
    readonly property string currentModel: _model

    // === Conversation State ===
    readonly property var conversations: _conversations
    readonly property string activeConversationId: _activeConvId
    readonly property var currentMessages: _messages
    readonly property string streamingContent: _streamContent

    // === Error State ===
    readonly property bool hasError: _error !== ""
    readonly property string errorMessage: _error
    readonly property bool errorRetryable: _errorRetryable

    // === Internal State ===
    property bool _connecting: false
    property int _reconnectAttempts: 0
    property bool _loading: false
    property bool _streaming: false
    property string _provider: "openai"
    property string _model: "gpt-4o-mini"
    property string _activeConvId: ""
    property string _streamContent: ""
    property string _error: ""
    property bool _errorRetryable: false

    // Pending requests for response matching
    property var _pendingRequests: ({})

    // Conversation list model
    property ListModel _conversations: ListModel {}

    // Message list model
    property ListModel _messages: ListModel {}

    // === Public Actions ===

    /**
     * Send a message to the AI
     */
    function sendMessage(text: string, attachments: var = []): void {
        if (!connected || loading || !text.trim()) return

        _loading = true
        _streaming = true
        _streamContent = ""
        _error = ""

        const payload = {
            conversation_id: _activeConvId,
            content: text.trim(),
            attachments: attachments || []
        }

        _send("chat", payload)
    }

    /**
     * Create a new conversation
     */
    function newConversation(title: string = ""): void {
        _send("new_conv", { title: title })
    }

    /**
     * Load a conversation by ID
     */
    function loadConversation(id: string): void {
        if (id === _activeConvId) return

        _loading = true
        _messages.clear()
        _send("load_conv", { id: id })
    }

    /**
     * Delete a conversation
     */
    function deleteConversation(id: string): void {
        _send("delete_conv", { id: id })
    }

    /**
     * Refresh conversation list
     */
    function refreshConversations(): void {
        _send("list_convs", {})
    }

    /**
     * Switch AI provider
     */
    function setProvider(provider: string): void {
        _send("set_provider", { provider: provider })
    }

    /**
     * Set model
     */
    function setModel(model: string): void {
        _send("set_model", { model: model })
    }

    /**
     * Retry last failed request
     */
    function retry(): void {
        _error = ""
        _send("retry", {})
    }

    /**
     * Clear error
     */
    function clearError(): void {
        _error = ""
        _errorRetryable = false
    }

    /**
     * Get daemon status
     */
    function getStatus(): void {
        _send("status", {})
    }

    // === Socket Connection ===

    Socket {
        id: socket
        path: "/tmp/x-ai.sock"
        
        onConnectedChanged: {
            if (connected) {
                console.log("[AI] Connected to daemon")
                root._connecting = false
                root._reconnectAttempts = 0
                root._error = ""
                // Request initial state
                root.refreshConversations()
                root.getStatus()
            } else {
                console.log("[AI] Disconnected from daemon")
                root._scheduleReconnect()
            }
        }

        onDataReceived: (data) => {
            root._handleMessage(data)
        }

        onError: (error) => {
            console.error("[AI] Socket error:", error)
            root._error = "Connection error: " + error
        }
    }

    // === Internal Methods ===

    function _send(type: string, payload: var): void {
        if (!socket.connected) {
            console.warn("[AI] Cannot send, not connected")
            _error = "Not connected to AI daemon"
            return
        }

        const requestId = _generateId()
        const msg = {
            type: type,
            request_id: requestId,
            payload: payload,
            timestamp: Date.now()
        }

        // Track pending request
        _pendingRequests[requestId] = { type: type, time: Date.now() }

        socket.write(JSON.stringify(msg) + "\n")
    }

    function _handleMessage(data: string): void {
        try {
            const msg = JSON.parse(data)
            // console.log("[AI] Received:", msg.type)

            switch (msg.type) {
                case "chat_chunk":
                    _handleChatChunk(msg)
                    break
                case "chat_complete":
                    _handleChatComplete(msg)
                    break
                case "error":
                    _handleError(msg)
                    break
                case "conv_list":
                    _handleConvList(msg)
                    break
                case "conv_data":
                    _handleConvData(msg)
                    break
                case "status":
                    _handleStatus(msg)
                    break
                case "ack":
                    _handleAck(msg)
                    break
                case "heartbeat":
                    // Just confirms connection is alive
                    break
                default:
                    console.warn("[AI] Unknown message type:", msg.type)
            }

            // Clean up pending request
            if (msg.request_id && _pendingRequests[msg.request_id]) {
                delete _pendingRequests[msg.request_id]
            }

        } catch (e) {
            console.error("[AI] Failed to parse message:", e)
        }
    }

    function _handleChatChunk(msg: var): void {
        const payload = msg.payload
        
        // Accumulate streaming content
        if (payload.content) {
            _streamContent += payload.content
        }

        if (payload.done) {
            // Add complete message to list
            _messages.append({
                id: payload.message_id || _generateId(),
                role: "assistant",
                content: _streamContent,
                created_at: Date.now()
            })
            _streamContent = ""
            _streaming = false
            _loading = false
        }
    }

    function _handleChatComplete(msg: var): void {
        _streaming = false
        _loading = false
    }

    function _handleError(msg: var): void {
        const payload = msg.payload
        _error = payload.message || "Unknown error"
        _errorRetryable = payload.retryable || false
        _loading = false
        _streaming = false
        console.error("[AI] Error:", _error)
    }

    function _handleConvList(msg: var): void {
        _conversations.clear()
        const convs = msg.payload || []
        for (const conv of convs) {
            _conversations.append({
                id: conv.id,
                title: conv.title,
                provider: conv.provider,
                model: conv.model,
                updated_at: conv.updated_at
            })
        }
    }

    function _handleConvData(msg: var): void {
        const payload = msg.payload
        
        if (payload.conversation) {
            _activeConvId = payload.conversation.id
            _provider = payload.conversation.provider
            _model = payload.conversation.model
        }

        if (payload.messages) {
            _messages.clear()
            for (const m of payload.messages) {
                _messages.append({
                    id: m.id,
                    role: m.role,
                    content: m.content,
                    created_at: m.created_at
                })
            }
        }

        _loading = false
    }

    function _handleStatus(msg: var): void {
        const payload = msg.payload
        _provider = payload.provider || _provider
        _model = payload.model || _model
    }

    function _handleAck(msg: var): void {
        const payload = msg.payload
        if (payload && payload.conversation_id) {
            _activeConvId = payload.conversation_id

            // Add user message to list immediately
            // (We add it here after getting the conv ID)
        }
    }

    function _scheduleReconnect(): void {
        if (_reconnectAttempts >= 5) {
            _error = "Failed to connect to AI daemon after 5 attempts"
            return
        }

        _connecting = true
        _reconnectAttempts++
        const delay = Math.min(1000 * Math.pow(2, _reconnectAttempts - 1), 30000)
        
        console.log("[AI] Reconnecting in", delay, "ms (attempt", _reconnectAttempts, ")")
        
        reconnectTimer.interval = delay
        reconnectTimer.start()
    }

    function _generateId(): string {
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 9)
    }

    Timer {
        id: reconnectTimer
        repeat: false
        onTriggered: {
            if (!socket.connected) {
                socket.connect()
            }
        }
    }

    // Auto-connect on creation
    Component.onCompleted: {
        console.log("[AI] Service initialized, connecting...")
        socket.connect()
    }
}
