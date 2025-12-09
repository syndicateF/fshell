import qs.components
import qs.components.effects
import qs.services
import qs.utils
import qs.config
import QtQuick

Item {
    id: root

    required property string wsName
    required property var appInfo

    // Pacman yellow color
    readonly property color pacmanYellow: "#FFCC00"
    readonly property color dotColor: "#FFB8A8"  // Soft pink/peach dots

    implicitWidth: content.implicitWidth + Appearance.padding.large * 4
    implicitHeight: content.implicitHeight + Appearance.padding.large * 4

    Column {
        id: content
        anchors.centerIn: parent
        spacing: Appearance.spacing.large

        // App icon + name - horizontal layout
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Appearance.spacing.large

            ColouredIcon {
                source: Icons.getAppIcon(root.appInfo.icon ?? "", "application-x-executable")
                implicitSize: 72
                colour: Colours.palette.m3primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.small

                StyledText {
                    text: root.wsName
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: "Launching..."
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3outline
                }
            }
        }

        // Pacman loading animation - BIGGER!
        Item {
            id: pacmanContainer
            anchors.horizontalCenter: parent.horizontalCenter
            width: 350
            height: 70

            // Background track
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 40
                height: 3
                radius: 1.5
                color: Colours.palette.m3surfaceContainerHighest
            }

            // Dots that get eaten
            Repeater {
                id: dotsRepeater
                model: 10

                Rectangle {
                    id: dot
                    required property int index

                    readonly property real spacing: (pacmanContainer.width - 80) / 10
                    readonly property real baseX: 55 + index * spacing
                    // Dot is eaten when pacman passes it
                    readonly property bool isEaten: pacman.x + pacman.width / 2 > baseX

                    x: baseX - width / 2
                    y: (pacmanContainer.height - height) / 2
                    width: index === 9 ? 18 : 12  // Last dot is bigger (power pellet)
                    height: width
                    radius: width / 2
                    color: index === 9 ? root.pacmanYellow : root.dotColor
                    opacity: isEaten ? 0 : 1
                    scale: isEaten ? 0.5 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                }
            }

            // Pacman - BIGGER!
            Canvas {
                id: pacman
                width: 56
                height: 56
                y: (parent.height - height) / 2

                property real mouthAngle: 0.2
                property real progress: 0

                x: 15 + progress * (pacmanContainer.width - 80)

                onMouthAngleChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    const cx = width / 2
                    const cy = height / 2
                    const r = width / 2 - 2

                    // Pacman body (yellow)
                    ctx.fillStyle = root.pacmanYellow

                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.arc(cx, cy, r, mouthAngle, Math.PI * 2 - mouthAngle)
                    ctx.closePath()
                    ctx.fill()

                    // Eye
                    ctx.fillStyle = "#000000"
                    ctx.beginPath()
                    ctx.arc(cx + 4, cy - r * 0.4, 5, 0, Math.PI * 2)
                    ctx.fill()
                }

                // Mouth chomp animation
                SequentialAnimation on mouthAngle {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { to: 0.5; duration: 100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.05; duration: 100; easing.type: Easing.InOutSine }
                }

                // Movement animation
                SequentialAnimation on progress {
                    loops: Animation.Infinite
                    running: true

                    NumberAnimation {
                        from: 0
                        to: 1
                        duration: 2000
                        easing.type: Easing.Linear
                    }

                    // Brief pause at end before reset
                    PauseAnimation { duration: 300 }

                    // Instant reset
                    PropertyAction { value: 0 }
                }
            }
        }

        // Workspace info
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `special:${root.wsName}`
            font.family: Appearance.font.family.mono
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3outline
        }
    }
}
