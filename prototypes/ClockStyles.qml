import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

ShellRoot {
    id: root
    
    // Current time
    property string currentHour: {
        const d = new Date();
        return String(d.getHours()).padStart(2, "0");
    }
    property string currentMinute: {
        const d = new Date();
        return String(d.getMinutes()).padStart(2, "0");
    }
    property string currentDay: {
        const days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        return days[new Date().getDay()];
    }
    property string currentDate: String(new Date().getDate()).padStart(2, "0")
    property string currentMonth: {
        const months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        return months[new Date().getMonth()];
    }
    
    // Refresh timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const d = new Date();
            root.currentHour = String(d.getHours()).padStart(2, "0");
            root.currentMinute = String(d.getMinutes()).padStart(2, "0");
        }
    }
    
    // Theme colors
    readonly property color bgColor: "#1a1a2e"
    readonly property color surfaceColor: "#252542"
    readonly property color accentColor: "#7c3aed"
    readonly property color textColor: "#e2e8f0"
    readonly property color dimColor: "#64748b"
    readonly property string fontFamily: "Inter"
    
    PanelWindow {
        id: previewWindow
        
        anchors {
            top: true
            left: true
            right: true
        }
        height: 140
        color: root.bgColor
        
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "clock-prototype"
        
        Row {
            anchors.centerIn: parent
            spacing: 40
            
            // ============ STYLE 1: Current (Diagonal Date) ============
            Rectangle {
                width: 80
                height: 120
                color: root.surfaceColor
                radius: 12
                
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Current"
                        font.pixelSize: 10
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                    
                    // Time stacked
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentHour
                            font.pixelSize: 22
                            font.weight: Font.Medium
                            font.family: root.fontFamily
                            color: root.accentColor
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentMinute
                            font.pixelSize: 22
                            font.weight: Font.Medium
                            font.family: root.fontFamily
                            color: root.accentColor
                        }
                    }
                    
                    Rectangle {
                        width: 40
                        height: 1
                        color: root.accentColor
                        opacity: 0.5
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    // Diagonal date
                    Item {
                        width: 30
                        height: 28
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Shape {
                            anchors.fill: parent
                            ShapePath {
                                strokeWidth: 1
                                strokeColor: root.accentColor
                                fillColor: "transparent"
                                startX: 26; startY: 4
                                PathLine { x: 4; y: 24 }
                            }
                        }
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            text: root.currentDate
                            font.pixelSize: 11
                            font.family: root.fontFamily
                            color: root.accentColor
                        }
                        Text {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            text: root.currentMonth.substring(0, 2)
                            font.pixelSize: 11
                            font.family: root.fontFamily
                            color: root.accentColor
                        }
                    }
                }
            }
            
            // ============ STYLE 2: Minimal Dots ============
            Rectangle {
                width: 80
                height: 120
                color: root.surfaceColor
                radius: 12
                
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Dots"
                        font.pixelSize: 10
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                    
                    // Time with colon dot
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentHour
                            font.pixelSize: 24
                            font.weight: Font.Light
                            font.family: root.fontFamily
                            color: root.textColor
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "•"
                            font.pixelSize: 8
                            color: root.accentColor
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentMinute
                            font.pixelSize: 24
                            font.weight: Font.Light
                            font.family: root.fontFamily
                            color: root.textColor
                        }
                    }
                    
                    // Date minimal
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentDay
                        font.pixelSize: 10
                        font.family: root.fontFamily
                        font.letterSpacing: 2
                        color: root.dimColor
                    }
                }
            }
            
            // ============ STYLE 3: Boxed/Flip ============
            Rectangle {
                width: 80
                height: 120
                color: root.surfaceColor
                radius: 12
                
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Flip"
                        font.pixelSize: 10
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                    
                    // Flip clock style boxes
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        
                        Rectangle {
                            width: 44
                            height: 28
                            color: "#0f0f1a"
                            radius: 4
                            border.width: 1
                            border.color: root.accentColor
                            
                            Text {
                                anchors.centerIn: parent
                                text: root.currentHour
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                font.family: "JetBrains Mono"
                                color: root.accentColor
                            }
                        }
                        
                        Rectangle {
                            width: 44
                            height: 28
                            color: "#0f0f1a"
                            radius: 4
                            border.width: 1
                            border.color: root.accentColor
                            
                            Text {
                                anchors.centerIn: parent
                                text: root.currentMinute
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                font.family: "JetBrains Mono"
                                color: root.accentColor
                            }
                        }
                    }
                    
                    // Date
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentDate + " " + root.currentMonth
                        font.pixelSize: 9
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                }
            }
            
            // ============ STYLE 4: Arc Progress ============
            Rectangle {
                width: 80
                height: 120
                color: root.surfaceColor
                radius: 12
                
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Arc"
                        font.pixelSize: 10
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                    
                    // Arc with time
                    Item {
                        width: 50
                        height: 50
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        // Background arc
                        Shape {
                            anchors.fill: parent
                            
                            ShapePath {
                                strokeWidth: 3
                                strokeColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                
                                PathAngleArc {
                                    centerX: 25; centerY: 25
                                    radiusX: 22; radiusY: 22
                                    startAngle: 135
                                    sweepAngle: 270
                                }
                            }
                            
                            // Progress arc (minute progress)
                            ShapePath {
                                strokeWidth: 3
                                strokeColor: root.accentColor
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                
                                PathAngleArc {
                                    centerX: 25; centerY: 25
                                    radiusX: 22; radiusY: 22
                                    startAngle: 135
                                    sweepAngle: (parseInt(root.currentMinute) / 60) * 270
                                }
                            }
                        }
                        
                        // Time in center
                        Column {
                            anchors.centerIn: parent
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.currentHour
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                font.family: root.fontFamily
                                color: root.textColor
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.currentMinute
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                font.family: root.fontFamily
                                color: root.textColor
                            }
                        }
                    }
                    
                    // Day
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentDay
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: root.fontFamily
                        color: root.accentColor
                    }
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentDate + " " + root.currentMonth
                        font.pixelSize: 9
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                }
            }
            
            // ============ STYLE 5: Neon/Glow ============
            Rectangle {
                width: 80
                height: 120
                color: root.surfaceColor
                radius: 12
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Neon"
                        font.pixelSize: 10
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                    
                    // Neon glow time
                    Item {
                        width: 50
                        height: 60
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Column {
                            anchors.centerIn: parent
                            
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.currentHour
                                font.pixelSize: 26
                                font.weight: Font.Bold
                                font.family: root.fontFamily
                                color: "#a855f7"
                                
                                layer.enabled: true
                                layer.effect: Item {
                                    // Glow simulation via drop shadow-like effect
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.currentMinute
                                font.pixelSize: 26
                                font.weight: Font.Bold
                                font.family: root.fontFamily
                                color: "#6366f1"
                            }
                        }
                    }
                    
                    // Date with icon feel
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4
                        
                        Text {
                            text: "📅"
                            font.pixelSize: 10
                        }
                        Text {
                            text: root.currentDate
                            font.pixelSize: 10
                            font.family: root.fontFamily
                            color: root.dimColor
                        }
                    }
                }
            }
            
            // ============ STYLE 6: Words ============
            Rectangle {
                width: 80
                height: 120
                color: root.surfaceColor
                radius: 12
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Words"
                        font.pixelSize: 10
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                    
                    // Time as words
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0
                        
                        property var hourWords: ["TWELVE", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE"]
                        property int h: parseInt(root.currentHour) % 12
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.hourWords[parent.h === 0 ? 12 : parent.h]
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.family: root.fontFamily
                            font.letterSpacing: 1
                            color: root.textColor
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: ":"
                            font.pixelSize: 8
                            color: root.accentColor
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentMinute
                            font.pixelSize: 20
                            font.weight: Font.Light
                            font.family: root.fontFamily
                            color: root.textColor
                        }
                    }
                    
                    Rectangle {
                        width: 50
                        height: 1
                        color: root.accentColor
                        opacity: 0.3
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentDay + " " + root.currentDate
                        font.pixelSize: 9
                        font.family: root.fontFamily
                        color: root.dimColor
                    }
                }
            }
        }
        
        // Label
        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Click anywhere to close • Clock Style Prototypes"
            font.pixelSize: 11
            font.family: root.fontFamily
            color: root.dimColor
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
    }
}
