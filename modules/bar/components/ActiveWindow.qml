pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick

StyledRect {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    // Dynamic color dari icon
    property color colour: Colours.palette.m3primary

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.border.rounding

    readonly property int maxHeight: {
        const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
        const otherHeight = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimHeight ?? curr.height), 0);
        // Length - 2 cause repeater counts as a child
        return bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
    }
    property Title current: text1

    clip: true
    implicitWidth: Math.max(icon.implicitWidth, current.implicitHeight) + Config.bar.sizes.itemPadding * 2
    implicitHeight: icon.implicitHeight + current.implicitWidth + current.anchors.topMargin + Config.bar.sizes.itemPadding * 2

    // Timer untuk delay color extraction
    Timer {
        id: colorTimer
        interval: 16  // 1 frame delay - minimal
        repeat: false
        onTriggered: {
            if (icon.status === Image.Ready && icon.width > 0) {
                icon.grabToImage(result => {
                    if (!result) return;
                    colorCanvas.imageResult = result;
                    colorCanvas.requestPaint();
                });
            }
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
            
            // Sample pixels to find dominant color
            const imgData = ctx.getImageData(0, 0, width, height);
            const data = imgData.data;
            
            let r = 0, g = 0, b = 0, count = 0;
            
            for (let i = 0; i < data.length; i += 4) {
                const alpha = data[i + 3];
                if (alpha < 128) continue;
                
                const pr = data[i], pg = data[i + 1], pb = data[i + 2];
                // Skip near-white and near-black
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
                
                // Boost brightness for dark colors
                const lum = (r + g + b) / 3;
                if (lum < 100) {
                    const factor = 1.6;
                    r = Math.min(255, r * factor);
                    g = Math.min(255, g * factor);
                    b = Math.min(255, b * factor);
                }
                
                root.colour = Qt.rgba(r / 255, g / 255, b / 255, 1);
            }
        }
    }

    IconImage {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Config.bar.sizes.itemPadding

        implicitSize: Appearance.font.size.large * 1
        source: Icons.getAppIcon(Hypr.activeToplevel?.lastIpcObject.class ?? "", "desktop")

        onStatusChanged: {
            if (status === Image.Ready) {
                colorTimer.restart();
            }
        }

        // Jangan reset color - biar tetap warna lama sampai warna baru siap
        // onSourceChanged: {
        //     root.colour = Colours.palette.m3primary;
        //     colorCanvas.imageResult = null;
        // }
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
        // Style sesuai ii - pakai pointSize dan main font (sans)
        font.pointSize: Config.bar.sizes.font.windowTitle
        font.family: Appearance.font.family.sans
        elide: Qt.ElideRight
        elideWidth: root.maxHeight - icon.height

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    component Title: Text {
        id: text

        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Appearance.spacing.smaller

        // Style persis ii StyledText dengan variable font axes
        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        font.hintingPreference: Font.PreferDefaultHinting
        font.variableAxes: ({ "wght": 450, "wdth": 100 })
        color: root.colour
        opacity: root.current === this ? 1 : 0
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter

        transform: [
            Translate {
                x: Config.bar.activeWindow.inverted ? -implicitWidth + text.implicitHeight : 0
            },
            Rotation {
                angle: Config.bar.activeWindow.inverted ? 270 : 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: implicitHeight
        height: implicitWidth

        Behavior on opacity {
            Anim {}
        }
    }
}
