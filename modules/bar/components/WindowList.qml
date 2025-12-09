pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property var bar
    required property ShellScreen screen

    // Windows di workspace aktif (including special workspace)
    readonly property var workspaceWindows: {
        const mon = Hypr.monitorFor(screen);
        if (!mon) return [];
        
        // Check if we're in a special workspace first
        const special = mon.lastIpcObject.specialWorkspace;
        const wsId = special.name ? special.id : (mon.activeWorkspace?.id ?? Hypr.activeWsId);
        
        return Hypr.toplevels.values.filter(c => c.workspace?.id === wsId);
    }

    // Index window yang active (focused)
    readonly property int activeIndex: {
        if (!Hypr.activeToplevel) return -1;
        const addr = Hypr.activeToplevel.lastIpcObject.address;
        return workspaceWindows.findIndex(w => w.lastIpcObject.address === addr);
    }
    
    // Check if workspace has windows
    readonly property bool hasWindows: workspaceWindows.length > 0
    
    // Size for empty state icon
    readonly property real emptyIconSize: Config.bar.sizes.iconSize * 1.5

    clip: true
    implicitWidth: hasWindows ? windowColumn.implicitWidth : emptyState.implicitWidth
    implicitHeight: hasWindows ? windowColumn.implicitHeight : emptyState.implicitHeight

    // Empty state - no windows in workspace
    Item {
        id: emptyState
        visible: !root.hasWindows
        opacity: visible ? 1 : 0
        
        implicitWidth: root.emptyIconSize + Appearance.padding.small * 2
        implicitHeight: root.emptyIconSize + 120 + Appearance.spacing.small
        
        Behavior on opacity { Anim {} }
        
        Column {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small
            
            // Profile picture (circular)
            Item {
                id: emptyIconContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.emptyIconSize
                height: root.emptyIconSize
                
                Rectangle {
                    id: emptyIconBg
                    anchors.fill: parent
                    radius: width / 2
                    color: Colours.palette.m3surfaceContainerHigh
                    clip: true
                    
                    Image {
                        id: profileImage
                        anchors.fill: parent
                        source: `file://${Paths.home}/.face`
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    
                    // Fallback icon if no profile pic
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: profileImage.status !== Image.Ready
                        text: "person"
                        font.pointSize: root.emptyIconSize * 0.5
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
            
            // Fun text - rotated for vertical bar
            Item {
                id: emptyTextContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: emptyText.implicitHeight
                height: 100
                
                StyledText {
                    id: emptyText
                    text: "I use Arch BTW"
                    font.pointSize: Appearance.font.size.small
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                    
                    transform: [
                        Rotation {
                            angle: 90
                            origin.x: emptyText.implicitHeight / 2
                            origin.y: emptyText.implicitHeight / 2
                        }
                    ]
                }
            }
        }
        
        Behavior on implicitHeight {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

    Column {
        id: windowColumn
        visible: root.hasWindows

        spacing: Appearance.spacing.small

        Repeater {
            model: root.workspaceWindows

            delegate: WindowItem {
                required property HyprlandToplevel modelData
                required property int index

                window: modelData
                windowIndex: index
                isActive: index === root.activeIndex
                totalWindows: root.workspaceWindows.length
                activeWindowIndex: root.activeIndex

                onClicked: {
                    if (!isActive) {
                        // Focus window - cursor akan pindah (Hyprland behavior)
                        Hypr.dispatch(`focuswindow address:${window.lastIpcObject.address}`);
                    }
                }
            }
        }
    }

    component WindowItem: Item {
        id: windowItem

        required property HyprlandToplevel window
        required property int windowIndex
        required property bool isActive
        required property int totalWindows
        required property int activeWindowIndex

        signal clicked()

        // Divider logic: muncul di atas window active jika ada inactive di atas
        readonly property bool showDividerTop: isActive && windowIndex > 0
        // Divider logic: muncul di bawah window active jika ada inactive di bawah
        readonly property bool showDividerBottom: isActive && windowIndex < totalWindows - 1

        // Max title length (visual height setelah rotasi)
        readonly property real maxTitleLength: 150

        // Dynamic color dari icon
        property color dynamicColor: Colours.palette.m3primary

        // Trigger color extraction when becoming active
        onIsActiveChanged: {
            if (isActive && icon.status === Image.Ready) {
                colorTimer.restart();
            }
        }

        // Combined title: "AppName · WindowTitle" atau hanya "AppName"
        readonly property string appName: window.lastIpcObject.class ?? "Unknown"
        readonly property string displayTitle: {
            const t = window.title ?? "";
            // Gabungkan app name dan title jika berbeda
            if (t.length > 0 && t !== appName) {
                return appName + " · " + t;
            }
            return appName;
        }

        implicitWidth: Math.max(iconContainer.implicitWidth, isActive ? titleContainer.width : 0)
        implicitHeight: {
            let h = iconContainer.implicitHeight;
            if (showDividerTop) h += dividerTop.height + Appearance.spacing.small;
            if (showDividerBottom) h += dividerBottom.height + Appearance.spacing.small;
            if (isActive) h += titleContainer.height + Appearance.spacing.smaller;
            return h;
        }

        // Timer untuk color extraction - lebih cepat
        Timer {
            id: colorTimer
            interval: 16
            repeat: false
            onTriggered: {
                if (icon.status === Image.Ready && icon.width > 0 && icon.height > 0) {
                    icon.grabToImage(result => {
                        if (!result) return;
                        colorCanvas.imageResult = result;
                        colorCanvas.requestPaint();
                    });
                } else if (windowItem.isActive) {
                    // Retry jika belum ready
                    colorTimer.interval = 50;
                    colorTimer.restart();
                }
            }
        }
        
        Component.onCompleted: {
            if (isActive) {
                colorTimer.restart();
            }
        }

        Canvas {
            id: colorCanvas
            visible: false
            width: 24
            height: 24
            property var imageResult: null

            onPaint: {
                if (!imageResult) return;
                
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.drawImage(imageResult.url, 0, 0, width, height);
                
                const imgData = ctx.getImageData(0, 0, width, height);
                const data = imgData.data;
                
                let r = 0, g = 0, b = 0, count = 0;
                
                for (let i = 0; i < data.length; i += 4) {
                    const alpha = data[i + 3];
                    if (alpha < 128) continue;
                    
                    const pr = data[i], pg = data[i + 1], pb = data[i + 2];
                    if ((pr > 230 && pg > 230 && pb > 230) || (pr < 25 && pg < 25 && pb < 25)) continue;
                    
                    r += pr;
                    g += pg;
                    b += pb;
                    count++;
                }
                
                if (count > 0) {
                    r = Math.round(r / count);
                    g = Math.round(g / count);
                    b = Math.round(b / count);
                    
                    const lum = (r + g + b) / 3;
                    if (lum < 100) {
                        const factor = 1.6;
                        r = Math.min(255, r * factor);
                        g = Math.min(255, g * factor);
                        b = Math.min(255, b * factor);
                    }
                    
                    windowItem.dynamicColor = Qt.rgba(r / 255, g / 255, b / 255, 1);
                }
            }
        }

        // Divider Top
        Rectangle {
            id: dividerTop

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            visible: windowItem.showDividerTop
            width: icon.implicitSize * 0.8
            height: 1
            color: Colours.palette.m3outlineVariant
            opacity: visible ? 1 : 0

            Behavior on opacity { Anim {} }
        }

        // Icon dengan hover state layer (hanya untuk active)
        Item {
            id: iconContainer

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: windowItem.showDividerTop ? dividerTop.bottom : parent.top
            anchors.topMargin: windowItem.showDividerTop ? Appearance.spacing.small : 0

            implicitWidth: icon.implicitSize + Appearance.padding.small * 2
            implicitHeight: icon.implicitSize + Appearance.padding.small * 2

            // State layer untuk hover - HANYA untuk active window
            StateLayer {
                anchors.fill: parent
                radius: Appearance.rounding.small
                // Hover hanya enabled untuk active window
                enabled: windowItem.isActive
                hoverEnabled: windowItem.isActive

                function onClicked(): void {
                    windowItem.clicked();
                }
            }

            // Click area untuk inactive windows (tanpa hover effect)
            MouseArea {
                anchors.fill: parent
                visible: !windowItem.isActive
                cursorShape: Qt.PointingHandCursor
                onClicked: windowItem.clicked()
            }

            IconImage {
                id: icon

                anchors.centerIn: parent
                implicitSize: Config.bar.sizes.iconSize
                source: Icons.getAppIcon(windowItem.window.lastIpcObject.class ?? "", "application-x-executable")

                // Opacity: active = full, inactive = dimmed
                opacity: windowItem.isActive ? 1.0 : 0.5

                onStatusChanged: {
                    if (status === Image.Ready && windowItem.isActive) {
                        colorTimer.restart();
                    }
                }

                Behavior on opacity { Anim {} }
            }
        }

        // Title - single line dengan rotation
        TextMetrics {
            id: titleMetrics
            text: windowItem.displayTitle
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.sans
            font.weight: Font.Medium
            elide: Qt.ElideRight
            elideWidth: windowItem.maxTitleLength
        }
        
        Item {
            id: titleContainer
            
            anchors.horizontalCenter: iconContainer.horizontalCenter
            anchors.top: iconContainer.bottom
            anchors.topMargin: Appearance.spacing.smaller
            
            visible: windowItem.isActive
            opacity: visible ? 1 : 0
            
            // Setelah rotasi: visual width = text height, visual height = text width (capped)
            width: titleText.implicitHeight
            height: Math.min(titleText.implicitWidth, windowItem.maxTitleLength)
            
            StyledText {
                id: titleText
                text: titleMetrics.elidedText
                font: titleMetrics.font
                color: windowItem.dynamicColor
            }
            
            // Rotate untuk vertical bar
            transform: [
                Translate {
                    x: Config.bar.activeWindow.inverted ? -titleText.implicitWidth + titleText.implicitHeight : 0
                },
                Rotation {
                    angle: Config.bar.activeWindow.inverted ? 270 : 90
                    origin.x: titleText.implicitHeight / 2
                    origin.y: titleText.implicitHeight / 2
                }
            ]
            
            Behavior on opacity { Anim {} }
        }

        // Divider Bottom
        Rectangle {
            id: dividerBottom

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            visible: windowItem.showDividerBottom
            width: icon.implicitSize * 0.8
            height: 1
            color: Colours.palette.m3outlineVariant
            opacity: visible ? 1 : 0

            Behavior on opacity { Anim {} }
        }

        Behavior on implicitHeight {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }
}
