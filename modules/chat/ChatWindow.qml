import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../services" as Services
import "../../components" as Components

/**
 * ChatWindow - Main AI chat interface
 * 
 * This is a PURE UI component. All AI logic is in the x-ai daemon.
 * This component only:
 * - Displays data from Services.AI
 * - Sends user actions to Services.AI
 */
Item {
    id: root

    // Layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar - Conversation List
        Rectangle {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            color: "#1e1e2e"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Conversations"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: "#cdd6f4"
                    }

                    Item { Layout.fillWidth: true }

                    // New chat button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: newChatMouse.containsMouse ? "#45475a" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 20
                            color: "#a6adc8"
                        }

                        MouseArea {
                            id: newChatMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.AI.newConversation()
                        }
                    }
                }

                // Conversation list
                ListView {
                    id: convList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4

                    model: Services.AI.conversations

                    delegate: Rectangle {
                        width: convList.width
                        height: 48
                        radius: 8
                        color: model.id === Services.AI.activeConversationId 
                            ? "#45475a" 
                            : convItemMouse.containsMouse ? "#313244" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: model.title || "New Chat"
                                font.pixelSize: 14
                                color: "#cdd6f4"
                                elide: Text.ElideRight
                            }

                            // Delete button
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 4
                                color: deleteMouse.containsMouse ? "#f38ba8" : "transparent"
                                visible: convItemMouse.containsMouse

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    font.pixelSize: 16
                                    color: deleteMouse.containsMouse ? "#1e1e2e" : "#a6adc8"
                                }

                                MouseArea {
                                    id: deleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.AI.deleteConversation(model.id)
                                }
                            }
                        }

                        MouseArea {
                            id: convItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.AI.loadConversation(model.id)
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: convList.count === 0
                        text: "No conversations yet"
                        font.pixelSize: 14
                        color: "#6c7086"
                    }
                }

                // Connection status
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Services.AI.connected ? "#313244" : "#45475a"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: Services.AI.connected ? "#a6e3a1" : "#f38ba8"
                        }

                        Text {
                            text: Services.AI.connected 
                                ? Services.AI.currentModel 
                                : "Disconnected"
                            font.pixelSize: 12
                            color: "#a6adc8"
                        }
                    }
                }
            }
        }

        // Main chat area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#11111b"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Messages area
                ListView {
                    id: messageList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 16
                    clip: true
                    spacing: 16
                    verticalLayoutDirection: ListView.BottomToTop

                    model: Services.AI.currentMessages

                    delegate: MessageBubble {
                        width: messageList.width
                        role: model.role
                        content: model.content
                    }

                    // Streaming message
                    header: Services.AI.streaming ? streamingBubble : null

                    Component {
                        id: streamingBubble
                        MessageBubble {
                            width: messageList.width
                            role: "assistant"
                            content: Services.AI.streamingContent
                            isStreaming: true
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: messageList.count === 0 && !Services.AI.streaming
                        text: "Start a conversation"
                        font.pixelSize: 18
                        color: "#6c7086"
                    }
                }

                // Error banner
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Services.AI.hasError ? 48 : 0
                    color: "#f38ba8"
                    visible: Services.AI.hasError

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: Services.AI.errorMessage
                            font.pixelSize: 14
                            color: "#1e1e2e"
                            elide: Text.ElideRight
                        }

                        Text {
                            text: Services.AI.errorRetryable ? "Retry" : "Dismiss"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: "#1e1e2e"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Services.AI.errorRetryable) {
                                        Services.AI.retry()
                                    } else {
                                        Services.AI.clearError()
                                    }
                                }
                            }
                        }
                    }
                }

                // Input area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(inputField.contentHeight + 32, 200)
                    Layout.margins: 16
                    radius: 12
                    color: "#1e1e2e"
                    border.color: inputField.activeFocus ? "#89b4fa" : "#45475a"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            TextArea {
                                id: inputField
                                placeholderText: "Type a message..."
                                placeholderTextColor: "#6c7086"
                                color: "#cdd6f4"
                                font.pixelSize: 14
                                wrapMode: TextArea.Wrap
                                background: null

                                Keys.onReturnPressed: (event) => {
                                    if (event.modifiers & Qt.ShiftModifier) {
                                        event.accepted = false
                                    } else {
                                        sendMessage()
                                        event.accepted = true
                                    }
                                }
                            }
                        }

                        // Send button
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 8
                            color: canSend ? "#89b4fa" : "#45475a"

                            readonly property bool canSend: 
                                inputField.text.trim().length > 0 && 
                                Services.AI.connected && 
                                !Services.AI.loading

                            Text {
                                anchors.centerIn: parent
                                text: Services.AI.loading ? "..." : "→"
                                font.pixelSize: 18
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
        }
    }

    function sendMessage() {
        const text = inputField.text.trim()
        if (!text) return

        // Add user message to list immediately
        Services.AI.currentMessages.append({
            id: Date.now().toString(),
            role: "user",
            content: text,
            created_at: Date.now()
        })

        Services.AI.sendMessage(text)
        inputField.text = ""
    }
}
