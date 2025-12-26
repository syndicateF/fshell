import QtQuick
import QtQuick.Layouts

/**
 * MessageBubble - Single chat message display
 */
Item {
    id: root

    required property string role
    required property string content
    property bool isStreaming: false

    height: bubble.height

    Rectangle {
        id: bubble
        width: Math.min(contentText.implicitWidth + 32, parent.width * 0.8)
        height: contentText.implicitHeight + 24
        radius: 16
        
        // User messages on right, assistant on left
        anchors.right: role === "user" ? parent.right : undefined
        anchors.left: role !== "user" ? parent.left : undefined

        color: role === "user" ? "#89b4fa" : "#313244"

        Text {
            id: contentText
            anchors.fill: parent
            anchors.margins: 12
            text: root.content + (root.isStreaming ? "▌" : "")
            font.pixelSize: 14
            color: role === "user" ? "#1e1e2e" : "#cdd6f4"
            wrapMode: Text.Wrap
            textFormat: Text.MarkdownText
        }

        // Streaming animation
        SequentialAnimation on opacity {
            running: root.isStreaming
            loops: Animation.Infinite
            NumberAnimation { to: 0.7; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
        }
    }
}
