import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: implicitHeight + (hasWindows ? Appearance.padding.small : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    StyledText {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: Config.bar.sizes.innerWidth - Appearance.padding.small * 2

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
        verticalAlignment: Qt.AlignVCenter
    }

    Loader {
        id: windows

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: -Config.bar.sizes.innerWidth / 10

        visible: active
        active: root.hasWindows
        asynchronous: true

        sourceComponent: Column {
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
                            font.pointSize: Config.bar.sizes.materialIconSize
                        }
                    }
                    
                    Component {
                        id: customComp
                        StyledText {
                            text: Config.bar.workspaces.windowIconCustomSymbol
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Config.bar.sizes.materialIconSize
                            horizontalAlignment: Text.AlignHCenter
                            width: contentWidth
                        }
                    }
                    
                    Component {
                        id: appIconComp
                        IconImage {
                            source: Icons.getAppIcon(windowIconLoader.appClass, "application-x-executable")
                            implicitSize: Config.bar.sizes.materialIconSize
                        }
                    }
                }
            }
        }
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }
}
