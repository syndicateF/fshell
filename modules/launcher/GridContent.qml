pragma ComponentBehavior: Bound

import "items"
import "services"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var content
    required property PersistentProperties visibilities
    required property var panels
    required property StyledTextField search
    required property int currentTab
    required property int padding
    required property int rounding

    readonly property int columns: Config.launcher.columns
    readonly property int rows: Config.launcher.rows ?? 7
    readonly property int itemWidth: Config.launcher.sizes.itemWidth
    readonly property int itemHeight: Config.launcher.sizes.itemHeight
    readonly property int gridSpacing: 0  // No spacing between items

    // Fixed width = always columns, but height WRAPS to content
    readonly property int fixedWidth: itemWidth * columns
    readonly property int fixedWallpaperWidth: Config.launcher.sizes.wallpaperWidth * 5

    // Track previous tab for animation direction
    property int previousTab: 0

    // Track which tabs have been visited (for lazy loading)
    // Using individual bools because JS Set is not reactive in QML
    property bool tab1Visited: false
    property bool tab2Visited: false
    property bool tab3Visited: false
    property bool tab4Visited: false
    property bool tab5Visited: false
    
    // 6 tabs: 0=Apps, 1=Commands, 2=Calc, 3=Schemes, 4=Wallpapers, 5=Variants
    readonly property var currentList: {
        switch (currentTab) {
            case 0: return appsGrid;
            case 1: return commandsLoader.item;
            case 2: return calcLoader.item;
            case 3: return schemesLoader.item;
            case 4: return wallpapersLoader.item;
            case 5: return variantsLoader.item;
            default: return appsGrid;
        }
    }

    // Wallpapers height constant - only this needs to be different
    readonly property int wallpapersHeight: Config.launcher.sizes.wallpaperHeight + Appearance.font.size.normal * 3

    // Single function to calculate height - avoids 6 separate bindings
    function getTabHeight(tab: int, count: int): int {
        if (tab === 2) return itemHeight; // Calc is always 1 row
        if (tab === 4) return wallpapersHeight;
        const rowCount = Math.max(1, Math.min(rows, Math.ceil(count / columns)));
        return itemHeight * rowCount;
    }

    // Current dimensions based on active tab
    readonly property int currentWidth: currentTab === 4 ? fixedWallpaperWidth : fixedWidth
    readonly property int currentHeight: getTabHeight(currentTab, currentList?.count ?? 0)

    implicitWidth: currentWidth
    implicitHeight: currentHeight

    // Smooth animation for dimension changes (like original launcher)
    Behavior on implicitWidth {
        enabled: visibilities.launcher
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Behavior on implicitHeight {
        enabled: visibilities.launcher
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    // Smooth scroll helper - calculate target contentY and let Behavior animate
    function ensureVisible(grid: GridView, index: int): void {
        if (!grid || index < 0) return;
        
        const row = Math.floor(index / columns);
        const itemY = row * itemHeight;
        const viewHeight = grid.height;
        const currentY = grid.contentY;
        
        // Check if item is above visible area
        if (itemY < currentY) {
            grid.contentY = itemY;
        }
        // Check if item is below visible area
        else if (itemY + itemHeight > currentY + viewHeight) {
            grid.contentY = itemY + itemHeight - viewHeight;
        }
        // Item is already visible - no scroll needed
    }

    // Navigation functions with smooth auto-scroll
    function navigateUp(): void {
        if (currentTab === 4) {
            return;
        }
        const grid = currentList;
        if (!grid) return;
        const newIndex = grid.currentIndex - columns;
        if (newIndex >= 0) {
            grid.currentIndex = newIndex;
            ensureVisible(grid, newIndex);
        }
    }

    function navigateDown(): void {
        if (currentTab === 4) {
            return;
        }
        const grid = currentList;
        if (!grid) return;
        const newIndex = grid.currentIndex + columns;
        if (newIndex < grid.count) {
            grid.currentIndex = newIndex;
            ensureVisible(grid, newIndex);
        }
    }

    function navigateLeft(): void {
        const list = currentList;
        if (!list) return;
        if (currentTab === 4) {
            list.decrementCurrentIndex();
        } else if (list.currentIndex > 0) {
            list.currentIndex--;
            ensureVisible(list, list.currentIndex);
        }
    }

    function navigateRight(): void {
        const list = currentList;
        if (!list) return;
        if (currentTab === 4) {
            list.incrementCurrentIndex();
        } else if (list.currentIndex < list.count - 1) {
            list.currentIndex++;
            ensureVisible(list, list.currentIndex);
        }
    }

    // Handle tab change animation
    onCurrentTabChanged: {
        previousTab = currentTab;
        // Mark tab as visited for lazy loading
        if (currentTab === 1) tab1Visited = true;
        else if (currentTab === 2) tab2Visited = true;
        else if (currentTab === 3) tab3Visited = true;
        else if (currentTab === 4) tab4Visited = true;
        else if (currentTab === 5) tab5Visited = true;
        
        if (currentTab === 3) {
            Schemes.reload();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // HORIZONTAL SLIDING CONTAINER FOR TABS
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: tabContainer
        anchors.fill: parent
        clip: true

        RowLayout {
            id: tabRow
            spacing: 0
            
            // Slide to active tab - use fixedWidth for all tabs except wallpapers
            x: {
                const widths = [root.fixedWidth, root.fixedWidth, root.fixedWidth, root.fixedWidth, root.fixedWallpaperWidth, root.fixedWidth];
                let offset = 0;
                for (let i = 0; i < root.currentTab; i++) {
                    offset += widths[i];
                }
                return -offset;
            }

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.anim.durations.large
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.8
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // TAB 0: APPS
            // ═══════════════════════════════════════════════════════════════
            Item {
                Layout.preferredWidth: root.fixedWidth
                Layout.preferredHeight: root.currentHeight

                GridView {
                    id: appsGrid
                    anchors.fill: parent

                    cellWidth: root.itemWidth
                    cellHeight: root.itemHeight

                    model: ScriptModel {
                        // Only query when Apps tab is active - avoid unnecessary searches
                        values: root.currentTab === 0 ? Apps.search(root.search.text) : Apps.search("")
                        onValuesChanged: appsGrid.currentIndex = 0
                    }

                    clip: true
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    // Only animate scroll when this tab is active
                    Behavior on contentY {
                        enabled: root.currentTab === 0
                        Anim {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }

                    highlight: GridHighlight { targetGrid: appsGrid }
                    highlightFollowsCurrentItem: false

                    delegate: GridAppItem {
                        id: appDelegate
                        width: root.itemWidth
                        height: root.itemHeight
                        isSelected: GridView.isCurrentItem
                        visibilities: root.visibilities

                        onClicked: {
                            appsGrid.currentIndex = appDelegate.index;
                            Apps.launch(appDelegate.modelData);
                            root.visibilities.launcher = false;
                        }

                        onHovered: appsGrid.currentIndex = appDelegate.index
                    }

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: appsGrid
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // TAB 1: COMMANDS (Lazy loaded)
            // ═══════════════════════════════════════════════════════════════
            Item {
                Layout.preferredWidth: root.fixedWidth
                Layout.preferredHeight: root.currentHeight

                Loader {
                    id: commandsLoader
                    anchors.fill: parent
                    active: root.tab1Visited || root.currentTab === 1
                    
                    sourceComponent: GridView {
                        id: commandsGrid
                        
                        cellWidth: root.itemWidth
                        cellHeight: root.itemHeight

                        model: ScriptModel {
                            values: root.currentTab === 1 ? Actions.query(root.search.text) : []
                            onValuesChanged: commandsGrid.currentIndex = 0
                        }

                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds

                        Behavior on contentY {
                            enabled: root.currentTab === 1
                            Anim {
                                duration: Appearance.anim.durations.expressiveDefaultSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                            }
                        }

                        highlight: GridHighlight { targetGrid: commandsGrid }
                        highlightFollowsCurrentItem: false

                        delegate: GridCommandItem {
                            id: commandDelegate
                            width: root.itemWidth
                            height: root.itemHeight
                            isSelected: GridView.isCurrentItem
                            gridContent: root

                            onClicked: {
                                commandsGrid.currentIndex = commandDelegate.index;
                                commandDelegate.modelData.onClicked(root);
                            }

                            onHovered: commandsGrid.currentIndex = commandDelegate.index
                        }

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: commandsGrid
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // TAB 2: CALCULATOR (Lazy loaded)
            // ═══════════════════════════════════════════════════════════════
            Item {
                Layout.preferredWidth: root.fixedWidth
                Layout.preferredHeight: root.currentHeight

                Loader {
                    id: calcLoader
                    anchors.fill: parent
                    active: root.tab2Visited || root.currentTab === 2
                    
                    sourceComponent: GridView {
                        id: calcGrid
                        
                        cellWidth: root.fixedWidth
                        cellHeight: root.itemHeight

                        model: 1
                        clip: true

                        delegate: GridCalcItem {
                            width: root.fixedWidth
                            height: root.itemHeight
                            isSelected: GridView.isCurrentItem
                            search: root.search
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // TAB 3: SCHEMES (Lazy loaded)
            // ═══════════════════════════════════════════════════════════════
            Item {
                Layout.preferredWidth: root.fixedWidth
                Layout.preferredHeight: root.currentHeight

                Loader {
                    id: schemesLoader
                    anchors.fill: parent
                    active: root.tab3Visited || root.currentTab === 3
                    
                    sourceComponent: GridView {
                        id: schemesGrid
                        
                        cellWidth: root.itemWidth
                        cellHeight: root.itemHeight

                        model: ScriptModel {
                            values: root.currentTab === 3 ? Schemes.query(root.search.text) : []
                            onValuesChanged: schemesGrid.currentIndex = 0
                        }

                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds

                        Behavior on contentY {
                            enabled: root.currentTab === 3
                            Anim {
                                duration: Appearance.anim.durations.expressiveDefaultSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                            }
                        }

                        highlight: GridHighlight { targetGrid: schemesGrid }
                        highlightFollowsCurrentItem: false

                        delegate: GridSchemeItem {
                            id: schemeDelegate
                            width: root.itemWidth
                            height: root.itemHeight
                            isSelected: GridView.isCurrentItem
                            visibilities: root.visibilities

                            onClicked: {
                                schemesGrid.currentIndex = schemeDelegate.index;
                                schemeDelegate.modelData.onClicked(root);
                            }

                            onHovered: schemesGrid.currentIndex = schemeDelegate.index
                        }

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: schemesGrid
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // TAB 4: WALLPAPERS (Lazy loaded)
            // ═══════════════════════════════════════════════════════════════
            Item {
                Layout.preferredWidth: root.fixedWallpaperWidth
                Layout.preferredHeight: root.currentHeight

                Loader {
                    id: wallpapersLoader
                    anchors.fill: parent
                    active: root.tab4Visited || root.currentTab === 4
                    
                    sourceComponent: PathView {
                        id: wallpapersPathView
                        
                        readonly property int wallpaperItemWidth: Config.launcher.sizes.wallpaperWidth + Appearance.padding.normal * 2

                        model: ScriptModel {
                            id: wallpaperModel
                            readonly property string searchText: root.currentTab === 4 ? root.search.text : ""

                            values: Wallpapers.query(searchText)
                            onValuesChanged: wallpapersPathView.currentIndex = searchText ? 0 : values.findIndex(w => w.path === Wallpapers.actualCurrent)
                        }

                        Component.onCompleted: currentIndex = Wallpapers.list.findIndex(w => w.path === Wallpapers.actualCurrent)

                        onCurrentItemChanged: {
                            if (currentItem && root.currentTab === 4)
                                Wallpapers.preview(currentItem.modelData.path);
                        }

                        pathItemCount: Math.min(Math.floor(root.width / wallpaperItemWidth), count) | 1
                        cacheItemCount: 2  // Reduced from 4

                        snapMode: PathView.SnapToItem
                        preferredHighlightBegin: 0.5
                        preferredHighlightEnd: 0.5
                        highlightRangeMode: PathView.StrictlyEnforceRange

                        delegate: WallpaperPathItem {
                            visibilities: root.visibilities
                        }

                        path: Path {
                            startY: wallpapersPathView.height / 2

                            PathAttribute {
                                name: "z"
                                value: 0
                            }
                            PathLine {
                                x: wallpapersPathView.width / 2
                                relativeY: 0
                            }
                            PathAttribute {
                                name: "z"
                                value: 1
                            }
                            PathLine {
                                x: wallpapersPathView.width
                                relativeY: 0
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // TAB 5: VARIANTS (Lazy loaded)
            // ═══════════════════════════════════════════════════════════════
            Item {
                Layout.preferredWidth: root.fixedWidth
                Layout.preferredHeight: root.currentHeight

                Loader {
                    id: variantsLoader
                    anchors.fill: parent
                    active: root.tab5Visited || root.currentTab === 5
                    
                    sourceComponent: GridView {
                        id: variantsGrid
                        
                        cellWidth: root.itemWidth
                        cellHeight: root.itemHeight

                        model: ScriptModel {
                            values: root.currentTab === 5 ? M3Variants.query(root.search.text) : []
                            onValuesChanged: variantsGrid.currentIndex = 0
                        }

                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds

                        Behavior on contentY {
                            enabled: root.currentTab === 5
                            Anim {
                                duration: Appearance.anim.durations.expressiveDefaultSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                            }
                        }

                        highlight: GridHighlight { targetGrid: variantsGrid }
                        highlightFollowsCurrentItem: false

                        delegate: GridVariantItem {
                            id: variantDelegate
                            width: root.itemWidth
                            height: root.itemHeight
                            isSelected: GridView.isCurrentItem
                            visibilities: root.visibilities

                            onClicked: {
                                variantsGrid.currentIndex = variantDelegate.index;
                                variantDelegate.modelData.onClicked(root);
                            }

                            onHovered: variantsGrid.currentIndex = variantDelegate.index
                        }

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: variantsGrid
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SHARED COMPONENTS
    // ═══════════════════════════════════════════════════════════════
    component GridHighlight: StyledRect {
        required property GridView targetGrid

        radius: Appearance.rounding.small
        color: Colours.palette.m3primaryContainer

        x: targetGrid.currentItem?.x ?? 0
        y: targetGrid.currentItem?.y ?? 0
        width: root.itemWidth
        height: root.itemHeight

        // Smooth animation like original launcher
        Behavior on x {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        Behavior on y {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

    // Wallpaper PathView item with zoom animation
    component WallpaperPathItem: Item {
        id: wpItem

        required property var modelData
        required property PersistentProperties visibilities

        scale: 0.5
        opacity: 0
        z: PathView.z ?? 0

        Component.onCompleted: {
            scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
            opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
        }

        implicitWidth: wpImage.width + Appearance.padding.larger * 2
        implicitHeight: wpImage.height + wpLabel.height + Appearance.spacing.small / 2 + Appearance.padding.large + Appearance.padding.normal

        StateLayer {
            radius: Appearance.rounding.normal

            function onClicked(): void {
                if (Colours.scheme === "dynamic" && wpItem.modelData.path !== Wallpapers.actualCurrent)
                    Wallpapers.previewColourLock = true;
                Wallpapers.setWallpaper(wpItem.modelData.path);
                // Don't close launcher - let user see the wallpaper change
            }
        }

        Elevation {
            anchors.fill: wpImage
            radius: wpImage.radius
            opacity: wpItem.PathView.isCurrentItem ? 1 : 0
            level: 4

            Behavior on opacity {
                Anim {}
            }
        }

        StyledClippingRect {
            id: wpImage

            anchors.horizontalCenter: parent.horizontalCenter
            y: Appearance.padding.large
            color: Colours.tPalette.m3surfaceContainer
            radius: Appearance.rounding.normal

            implicitWidth: Config.launcher.sizes.wallpaperWidth
            implicitHeight: implicitWidth / 16 * 9

            MaterialIcon {
                anchors.centerIn: parent
                text: "image"
                color: Colours.tPalette.m3outline
                font.pointSize: Appearance.font.size.extraLarge * 2
                font.weight: 600
            }

            CachingImage {
                path: wpItem.modelData.path
                smooth: !wpItem.PathView.view.moving

                anchors.fill: parent
            }
        }

        StyledText {
            id: wpLabel

            anchors.top: wpImage.bottom
            anchors.topMargin: Appearance.spacing.small / 2
            anchors.horizontalCenter: parent.horizontalCenter

            width: wpImage.width - Appearance.padding.normal * 2
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            renderType: Text.QtRendering
            text: wpItem.modelData.relativePath
            font.pointSize: Appearance.font.size.normal
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {}
        }
    }
}
