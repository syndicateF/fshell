import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset
    
    // Control visibility of icons and text separately (for Colouriser mask separation)
    property bool showIcons: true
    property bool showText: true

    readonly property bool isWorkspace: true // Flag for finding workspace children
    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows
    readonly property bool isActive: activeWsId === ws
    
    // Hide label jika hideActiveLabel enabled DAN workspace punya windows
    // Berlaku untuk SEMUA workspace (active maupun inactive) yang punya windows
    readonly property bool shouldHideLabel: Config.bar.workspaces.hideActiveLabel && hasWindows
    
    // Normal label width
    readonly property real labelWidth: Config.bar.sizes.innerWidth - Appearance.padding.small * 2
    
    // Icons width from loader
    readonly property real iconsWidth: windows.item ? windows.item.implicitWidth : 0
    
    // Overlap amount (icons overlap ke kiri label)
    readonly property real overlap: Config.bar.sizes.innerWidth / 10
    
    // Calculate size based on label visibility
    // Unanimated prop for others to use as reference (horizontal version uses width)
    readonly property int size: {
        if (shouldHideLabel) {
            // Label hidden: icons centered, use max of icons width or label width for consistency
            return Math.max(iconsWidth + Appearance.padding.normal * 2, labelWidth)
        } else if (hasWindows) {
            // Label visible dengan windows: label + icons (dengan overlap di kiri, padding di kanan)
            // labelWidth + iconsWidth - overlap + rightPadding
            return labelWidth + iconsWidth - overlap + Appearance.padding.normal
        } else {
            // Tidak ada windows: hanya label
            return labelWidth
        }
    }

    implicitWidth: size
    implicitHeight: Config.bar.workspaces.topWorkspacesHeight

    // Label - visible when showText=true (hidden in icons-only overlay)
    StyledText {
        id: indicator

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        
        visible: root.showText
        width: root.shouldHideLabel ? 0 : root.labelWidth
        clip: true
        opacity: root.shouldHideLabel ? 0 : 1
        
        Behavior on width {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
        
        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.small
            }
        }

        animate: true
        text: {
            const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
            const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
            let displayName = wsName.toString();
            if (Config.bar.workspaces.capitalisation.toLowerCase() === "upper") {
                displayName = displayName.toUpperCase();
            } else if (Config.bar.workspaces.capitalisation.toLowerCase() === "lower") {
                displayName = displayName.toLowerCase();
            }
            const label = Config.bar.workspaces.label || displayName;
            const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
            const activeLabel = Config.bar.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label);
            return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
        }
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
        horizontalAlignment: Qt.AlignHCenter
    }

    Loader {
        id: windows
        
        // Calculate x position based on label visibility
        // Saat label hidden: center icons dalam parent
        // Saat label visible: posisi di kanan label (dengan overlap)
        x: {
            if (root.shouldHideLabel) {
                // Center in parent - use root.iconsWidth for accurate centering
                return (root.width - root.iconsWidth) / 2
            } else {
                // Position after label with overlap
                return root.labelWidth - root.overlap
            }
        }
        anchors.verticalCenter: parent.verticalCenter
        
        Behavior on x {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        // Icons only visible when showIcons=true (hidden for Colouriser mask)
        visible: active && root.showIcons
        active: root.hasWindows
        asynchronous: true

        sourceComponent: Row {
            spacing: 0

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                model: ScriptModel {
                    values: Hypr.toplevels.values.filter(c => c.workspace?.id === root.ws)
                }

                Loader {
                    id: windowIconLoader
                    required property var modelData
                    
                    property string appClass: modelData.lastIpcObject.class
                    
                    sourceComponent: {
                        switch (Config.bar.workspaces.windowIconStyle) {
                            case "icon": return appIconComp
                            case "category": return categoryComp
                            case "custom": return customComp
                            default: return appIconComp
                        }
                    }
                    
                    Component {
                        id: categoryComp
                        MaterialIcon {
                            grade: 0
                            text: Icons.getAppCategoryIcon(windowIconLoader.appClass, "terminal")
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Config.bar.sizes.font.materialIcon
                        }
                    }
                    
                    Component {
                        id: customComp
                        StyledText {
                            text: Config.bar.workspaces.windowIconCustomSymbol
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Config.bar.sizes.font.materialIcon
                            horizontalAlignment: Text.AlignHCenter
                            width: contentWidth
                        }
                    }
                    
                    Component {
                        id: appIconComp
                        IconImage {
                            source: Icons.getAppIcon(windowIconLoader.appClass, "application-x-executable")
                            implicitSize: Config.bar.sizes.font.materialIcon
                            // Colorization only when iconColorization > 0
                            layer.enabled: Config.bar.workspaces.iconColorization > 0
                            layer.effect: MultiEffect {
                                colorization: Config.bar.workspaces.iconColorization
                                colorizationColor: Colours.palette.m3onPrimary
                            }
                        }
                    }
                }
            }
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }
}
