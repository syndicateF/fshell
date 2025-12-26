import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services" as Services

/**
 * AITestWidget - Floating test window for AI chat
 * 
 * PURE UI - Zero AI logic.
 * For testing the x-ai daemon integration.
 * 
 * Toggle with: caelestia toggle aitest
 */
PanelWindow {
    id: root

    // Window config
    anchors {
        top: true
        right: true
    }

    margins {
        top: 50
        right: 20
    }

    width: visible ? 450 : 0
    height: visible ? 600 : 0

    visible: false
    color: "transparent"

    // Animations
    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Main container
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#1e1e2e"
        border.color: "#45475a"
        border.width: 1

        // Header
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 48
            radius: 16
            color: "#181825"

            // Flatten bottom corners
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 16
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Status indicator
                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: Services.AI.connected ? "#a6e3a1" : "#f38ba8"
                }

                // Title
                Text {
                    Layout.fillWidth: true
                    text: "AI Chat"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#cdd6f4"
                }

                // Provider badge
                Rectangle {
                    visible: Services.AI.connected
                    padding: 6
                    height: 24
                    width: providerText.width + 12
                    radius: 4
                    color: "#313244"

                    Text {
                        id: providerText
                        anchors.centerIn: parent
                        text: Services.AI.currentProvider.toUpperCase()
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: "#89b4fa"
                    }
                }

                // Close button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 4
                    color: closeMouse.containsMouse ? "#f38ba8" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: 18
                        color: closeMouse.containsMouse ? "#1e1e2e" : "#a6adc8"
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }
            }
        }

        // Chat content area
        Rectangle {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: inputArea.top
            anchors.margins: 1
            color: "#11111b"
            clip: true

            // Messages
            ListView {
                id: messageList
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                clip: true

                model: Services.AI.currentMessages

                delegate: Rectangle {
                    width: messageList.width
                    height: msgContent.height + 16
                    radius: 12
                    color: model.role === "user" ? "#45475a" : "#313244"

                    // Align based on role
                    anchors.right: model.role === "user" ? parent?.right : undefined
                    anchors.left: model.role === "assistant" ? parent?.left : undefined

                    Text {
                        id: msgContent
                        anchors.fill: parent
                        anchors.margins: 8
                        text: model.content
                        font.pixelSize: 13
                        color: "#cdd6f4"
                        wrapMode: Text.Wrap
                    }
                }

                // Streaming indicator
                Rectangle {
                    visible: Services.AI.streaming
                    width: messageList.width
                    height: streamText.height + 16
                    radius: 12
                    color: "#313244"
                    border.color: "#89b4fa"
                    border.width: 1

                    Text {
                        id: streamText
                        anchors.fill: parent
                        anchors.margins: 8
                        text: Services.AI.streamingContent || "..."
                        font.pixelSize: 13
                        color: "#cdd6f4"
                        wrapMode: Text.Wrap
                    }
                }

                // Empty state
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: messageList.count === 0 && !Services.AI.streaming

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "💬"
                        font.pixelSize: 32
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Services.AI.connected ? "Ask me anything" : "Connecting..."
                        font.pixelSize: 14
                        color: "#6c7086"
                    }
                }
            }
        }

        // Error banner
        Rectangle {
            id: errorBanner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: inputArea.top
            height: Services.AI.hasError ? 40 : 0
            color: "#f38ba833"
            visible: Services.AI.hasError

            Behavior on height {
                NumberAnimation { duration: 150 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8

                Text {
                    Layout.fillWidth: true
                    text: "⚠ " + Services.AI.errorMessage
                    font.pixelSize: 12
                    color: "#f38ba8"
                    elide: Text.ElideRight
                }

                Text {
                    text: Services.AI.errorRetryable ? "Retry" : "✕"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#f38ba8"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.AI.errorRetryable ? Services.AI.retry() : Services.AI.clearError()
                    }
                }
            }
        }

        // Input area
        Rectangle {
            id: inputArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            height: 48
            radius: 12
            color: "#181825"
            border.color: inputField.activeFocus ? "#89b4fa" : "#45475a"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                TextField {
                    id: inputField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Type a message..."
                    placeholderTextColor: "#6c7086"
                    color: "#cdd6f4"
                    font.pixelSize: 13
                    background: null
                    enabled: Services.AI.connected && !Services.AI.loading

                    Keys.onReturnPressed: sendMessage()
                }

                // Send button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: canSend ? "#89b4fa" : "#45475a"

                    readonly property bool canSend:
                        inputField.text.trim().length > 0 &&
                        Services.AI.connected &&
                        !Services.AI.loading

                    Text {
                        anchors.centerIn: parent
                        text: Services.AI.loading ? "..." : "→"
                        font.pixelSize: 16
                        color: parent.canSend ? "#1e1e2e" : "#6c7086"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.canSend ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (parent.canSend) sendMessage()
                    }
                }
            }
        }
    }

    function sendMessage() {
        const text = inputField.text.trim()
        if (!text) return

        // Add user message immediately for responsiveness
        Services.AI.currentMessages.append({
            id: Date.now().toString(),
            role: "user",
            content: text,
            created_at: Date.now()
        })

        // Send to daemon
        Services.AI.sendMessage(text)
        inputField.text = ""
    }

    // Auto-create conversation if needed when widget opens
    onVisibleChanged: {
        if (visible && Services.AI.connected && !Services.AI.activeConversationId) {
            Services.AI.newConversation("Quick Chat")
        }
    }
}
