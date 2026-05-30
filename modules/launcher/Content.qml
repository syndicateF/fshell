pragma ComponentBehavior: Bound

import "items"
import "services"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities
    required property ShellScreen screen

    // Current mode: "apps" | "schemes" | "variants" | "wallpapers"
    property string currentMode: "apps"
    property string searchText: ""

    readonly property int contentWidth: 500
    readonly property int maxResultsHeight: 550
    readonly property int searchBarHeight: 48

    implicitWidth: contentWidth + searchBarPadding * 2
    implicitHeight: searchWrapper.implicitHeight + (resultsWrapper.visible ? resultsWrapper.implicitHeight + Appearance.spacing.normal : 0)

    // Smooth animation for height changes
    Behavior on implicitHeight {
        enabled: root.visibilities.launcher
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    readonly property int searchBarPadding: 8

    // Reset when launcher opens
    Connections {
        target: root.visibilities

        function onLauncherChanged(): void {
            if (root.visibilities.launcher) {
                root.currentMode = "apps";
                search.text = "";
                root.searchText = "";
                search.forceActiveFocus();
            }
        }
    }

    // Reload schemes when entering schemes mode
    onCurrentModeChanged: {
        if (currentMode === "schemes")
            Schemes.reload();
        // Clear search when switching modes
        search.text = "";
        root.searchText = "";
    }

    // ═══════════════════════════════════════════════════════════════
    // SEARCH BAR CONTAINER (pill-shaped, with shadow)
    // ═══════════════════════════════════════════════════════════════
    Elevation {
        anchors.fill: searchWrapper
        radius: searchWrapper.radius
        level: 3
    }

    StyledRect {
        id: searchWrapper

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        implicitHeight: searchRow.implicitHeight + searchBarPadding * 2

        Row {
            id: searchRow

            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.normal
            anchors.topMargin: root.searchBarPadding
            anchors.bottomMargin: root.searchBarPadding

            spacing: Appearance.spacing.small

            // ═══════════════════════════════════════════════════════════════
            // DYNAMIC SEARCH ICON (morphs based on mode)
            // ═══════════════════════════════════════════════════════════════
            MaterialIcon {
                id: searchIcon

                anchors.verticalCenter: parent.verticalCenter

                text: {
                    switch (root.currentMode) {
                        case "schemes": return "palette";
                        case "variants": return "colors";
                        case "wallpapers": return "image";
                        default: return "search";
                    }
                }
                font.pointSize: Config.launcher.sizes.font.searchBarIcon
                color: {
                    if (root.currentMode !== "apps")
                        return Colours.palette.m3primary;
                    return Colours.palette.m3onSurfaceVariant;
                }

                Behavior on color {
                    CAnim {
                        duration: Appearance.anim.durations.small
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // SEARCH TEXT FIELD
            // ═══════════════════════════════════════════════════════════════
            StyledTextField {
                id: search

                width: parent.width - searchIcon.implicitWidth - utilityButtons.implicitWidth - clearIcon.implicitWidth - parent.spacing * 4
                anchors.verticalCenter: parent.verticalCenter

                topPadding: Appearance.padding.small
                bottomPadding: Appearance.padding.small

                placeholderText: {
                    switch (root.currentMode) {
                        case "schemes": return qsTr("Search schemes...");
                        case "variants": return qsTr("Search variants...");
                        case "wallpapers": return qsTr("Search wallpapers...");
                        default: return qsTr("Search apps...");
                    }
                }

                onTextChanged: root.searchText = text

                onAccepted: {
                    if (root.currentMode === "apps") {
                        // Launch the first/selected app
                        if (appResultsList.currentItem?.modelData) {
                            Apps.launch(appResultsList.currentItem.modelData);
                            root.visibilities.launcher = false;
                        }
                    } else if (root.currentMode === "schemes") {
                        if (schemesGrid.currentItem?.modelData) {
                            schemesGrid.currentItem.modelData.onClicked(root);
                        }
                    } else if (root.currentMode === "variants") {
                        if (variantsGrid.currentItem?.modelData) {
                            variantsGrid.currentItem.modelData.onClicked(root);
                        }
                    } else if (root.currentMode === "wallpapers") {
                        if (wallpapersList.currentItem?.modelData) {
                            if (Colours.scheme === "dynamic" && wallpapersList.currentItem.modelData.path !== Wallpapers.actualCurrent)
                                Wallpapers.previewColourLock = true;
                            Wallpapers.setWallpaper(wallpapersList.currentItem.modelData.path);
                        }
                    }
                }

                // List navigation
                Keys.onUpPressed: {
                    if (root.currentMode === "apps" && appResultsList.currentIndex > 0)
                        appResultsList.currentIndex--;
                    else if (root.currentMode === "schemes" && schemesGrid.currentIndex > 0)
                        schemesGrid.currentIndex--;
                    else if (root.currentMode === "variants" && variantsGrid.currentIndex > 0)
                        variantsGrid.currentIndex--;
                }
                Keys.onDownPressed: {
                    if (root.currentMode === "apps" && appResultsList.currentIndex < appResultsList.count - 1)
                        appResultsList.currentIndex++;
                    else if (root.currentMode === "schemes" && schemesGrid.currentIndex < schemesGrid.count - 1)
                        schemesGrid.currentIndex++;
                    else if (root.currentMode === "variants" && variantsGrid.currentIndex < variantsGrid.count - 1)
                        variantsGrid.currentIndex++;
                }

                Keys.onEscapePressed: {
                    if (root.currentMode !== "apps") {
                        root.currentMode = "apps";
                        search.text = "";
                    } else {
                        root.visibilities.launcher = false;
                    }
                }

                // Vim keybinds
                Keys.onPressed: event => {
                    if (Config.launcher.vimKeybinds && (event.modifiers & Qt.ControlModifier)) {
                        if (event.key === Qt.Key_J) {
                            if (root.currentMode === "apps" && appResultsList.currentIndex < appResultsList.count - 1)
                                appResultsList.currentIndex++;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_K) {
                            if (root.currentMode === "apps" && appResultsList.currentIndex > 0)
                                appResultsList.currentIndex--;
                            event.accepted = true;
                        }
                    }
                }

                Component.onCompleted: forceActiveFocus()

                Connections {
                    target: root.visibilities

                    function onLauncherChanged(): void {
                        if (root.visibilities.launcher)
                            search.forceActiveFocus();
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // CLEAR BUTTON
            // ═══════════════════════════════════════════════════════════════
            MaterialIcon {
                id: clearIcon

                anchors.verticalCenter: parent.verticalCenter

                width: search.text ? implicitWidth : 0
                opacity: search.text ? 1 : 0
                visible: opacity > 0
                clip: true

                text: "close"
                font.pointSize: Config.launcher.sizes.font.searchBarIcon
                color: Colours.palette.m3onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: search.text = ""
                }

                Behavior on width {
                    Anim { duration: Appearance.anim.durations.small }
                }
                Behavior on opacity {
                    Anim { duration: Appearance.anim.durations.small }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // UTILITY BUTTONS (Schemes, Variants, Wallpapers)
            // ═══════════════════════════════════════════════════════════════
            Row {
                id: utilityButtons

                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                // Separator
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 24
                    color: Colours.palette.m3outlineVariant
                    opacity: 0.5
                }

                UtilityButton {
                    icon: "palette"
                    tooltip: qsTr("Color Schemes")
                    isActive: root.currentMode === "schemes"
                    onClicked: root.currentMode = root.currentMode === "schemes" ? "apps" : "schemes"
                }

                UtilityButton {
                    icon: "colors"
                    tooltip: qsTr("M3 Variants")
                    isActive: root.currentMode === "variants"
                    onClicked: root.currentMode = root.currentMode === "variants" ? "apps" : "variants"
                }

                UtilityButton {
                    icon: "image"
                    tooltip: qsTr("Wallpapers")
                    isActive: root.currentMode === "wallpapers"
                    onClicked: root.currentMode = root.currentMode === "wallpapers" ? "apps" : "wallpapers"
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // RESULTS AREA (below search bar)
    // ═══════════════════════════════════════════════════════════════
    Elevation {
        anchors.fill: resultsWrapper
        radius: resultsWrapper.radius
        level: 2
        visible: resultsWrapper.visible
    }

    StyledRect {
        id: resultsWrapper

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchWrapper.bottom
        anchors.topMargin: Appearance.spacing.normal

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large

        visible: hasContent
        readonly property bool hasContent: {
            if (root.currentMode !== "apps") return true;
            return root.searchText.length > 0;
        }

        implicitHeight: resultsContent.implicitHeight

        Behavior on implicitHeight {
            enabled: root.visibilities.launcher
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        clip: true

        Item {
            id: resultsContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            implicitHeight: Math.min(root.maxResultsHeight, innerContent.implicitHeight + Appearance.padding.normal * 2)

            Item {
                id: innerContent

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                implicitHeight: {
                    switch (root.currentMode) {
                        case "apps": return appResultsList.contentHeight;
                        case "schemes": return schemesGrid.contentHeight;
                        case "variants": return variantsGrid.contentHeight;
                        case "wallpapers": return wallpapersList.contentHeight;
                        default: return appResultsList.contentHeight;
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // APP RESULTS (Vertical List)
                // ═══════════════════════════════════════════════════════════════
                ListView {
                    id: appResultsList

                    anchors.fill: parent
                    visible: root.currentMode === "apps"

                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 100

                    model: ScriptModel {
                        values: root.currentMode === "apps" ? Apps.search(root.searchText) : []
                        onValuesChanged: appResultsList.currentIndex = 0
                    }

                    delegate: SearchResultItem {
                        id: resultDelegate

                        width: appResultsList.width
                        isSelected: ListView.isCurrentItem
                        searchQuery: root.searchText

                        onClicked: {
                            appResultsList.currentIndex = resultDelegate.index;
                            Apps.launch(resultDelegate.modelData);
                            root.visibilities.launcher = false;
                        }

                        onHovered: appResultsList.currentIndex = resultDelegate.index
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // SCHEMES GRID
                // ═══════════════════════════════════════════════════════════════
                GridView {
                    id: schemesGrid

                    anchors.fill: parent
                    visible: root.currentMode === "schemes"

                    cellWidth: Config.launcher.sizes.itemWidth
                    cellHeight: Config.launcher.sizes.itemHeight

                    clip: true
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: ScriptModel {
                        values: root.currentMode === "schemes" ? Schemes.query(root.searchText) : []
                        onValuesChanged: schemesGrid.currentIndex = 0
                    }

                    highlight: StyledRect {
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3primaryContainer
                        x: schemesGrid.currentItem?.x ?? 0
                        y: schemesGrid.currentItem?.y ?? 0
                        width: Config.launcher.sizes.itemWidth
                        height: Config.launcher.sizes.itemHeight

                        Behavior on x { Anim { duration: Appearance.anim.durations.expressiveDefaultSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                        Behavior on y { Anim { duration: Appearance.anim.durations.expressiveDefaultSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                    }
                    highlightFollowsCurrentItem: false

                    delegate: GridSchemeItem {
                        id: schemeDelegate
                        width: Config.launcher.sizes.itemWidth
                        height: Config.launcher.sizes.itemHeight
                        isSelected: GridView.isCurrentItem
                        visibilities: root.visibilities

                        onClicked: {
                            schemesGrid.currentIndex = schemeDelegate.index;
                            schemeDelegate.modelData.onClicked(root);
                        }
                        onHovered: schemesGrid.currentIndex = schemeDelegate.index
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // VARIANTS GRID
                // ═══════════════════════════════════════════════════════════════
                GridView {
                    id: variantsGrid

                    anchors.fill: parent
                    visible: root.currentMode === "variants"

                    cellWidth: Config.launcher.sizes.itemWidth
                    cellHeight: Config.launcher.sizes.itemHeight

                    clip: true
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: ScriptModel {
                        values: root.currentMode === "variants" ? M3Variants.query(root.searchText) : []
                        onValuesChanged: variantsGrid.currentIndex = 0
                    }

                    highlight: StyledRect {
                        radius: Appearance.rounding.small
                        color: Colours.palette.m3primaryContainer
                        x: variantsGrid.currentItem?.x ?? 0
                        y: variantsGrid.currentItem?.y ?? 0
                        width: Config.launcher.sizes.itemWidth
                        height: Config.launcher.sizes.itemHeight

                        Behavior on x { Anim { duration: Appearance.anim.durations.expressiveDefaultSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                        Behavior on y { Anim { duration: Appearance.anim.durations.expressiveDefaultSpatial; easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial } }
                    }
                    highlightFollowsCurrentItem: false

                    delegate: GridVariantItem {
                        id: variantDelegate
                        width: Config.launcher.sizes.itemWidth
                        height: Config.launcher.sizes.itemHeight
                        isSelected: GridView.isCurrentItem
                        visibilities: root.visibilities

                        onClicked: {
                            variantsGrid.currentIndex = variantDelegate.index;
                            variantDelegate.modelData.onClicked(root);
                        }
                        onHovered: variantsGrid.currentIndex = variantDelegate.index
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // WALLPAPERS LIST
                // ═══════════════════════════════════════════════════════════════
                GridView {
                    id: wallpapersList

                    anchors.fill: parent
                    visible: root.currentMode === "wallpapers"

                    readonly property int wpWidth: 160
                    readonly property int wpHeight: 100

                    cellWidth: wpWidth + Appearance.padding.normal
                    cellHeight: wpHeight + Appearance.font.size.normal * 3

                    clip: true
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: ScriptModel {
                        values: root.currentMode === "wallpapers" ? Wallpapers.query(root.searchText) : []
                    }

                    delegate: Item {
                        id: wpDelegate

                        required property var modelData
                        required property int index

                        width: wallpapersList.cellWidth
                        height: wallpapersList.cellHeight

                        StyledRect {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Appearance.rounding.normal
                            color: wpMouse.containsMouse ? Colours.tPalette.m3primaryContainer : "transparent"

                            Behavior on color { CAnim { duration: Appearance.anim.durations.small } }

                            Column {
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.small
                                spacing: Appearance.spacing.small / 2

                                StyledClippingRect {
                                    width: wallpapersList.wpWidth - Appearance.padding.normal
                                    height: wallpapersList.wpHeight - Appearance.padding.normal
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: Appearance.rounding.small
                                    color: Colours.tPalette.m3surfaceContainer

                                    CachingImage {
                                        path: wpDelegate.modelData.path
                                        anchors.fill: parent
                                    }
                                }

                                StyledText {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: wpDelegate.modelData.relativePath
                                    font.pointSize: Appearance.font.size.small
                                }
                            }

                            MouseArea {
                                id: wpMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Colours.scheme === "dynamic" && wpDelegate.modelData.path !== Wallpapers.actualCurrent)
                                        Wallpapers.previewColourLock = true;
                                    Wallpapers.setWallpaper(wpDelegate.modelData.path);
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // EMPTY STATE
                // ═══════════════════════════════════════════════════════════════
                Row {
                    id: emptyState

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small
                    visible: {
                        if (root.currentMode === "apps")
                            return appResultsList.count === 0 && root.searchText.length > 0;
                        if (root.currentMode === "schemes")
                            return schemesGrid.count === 0;
                        if (root.currentMode === "variants")
                            return variantsGrid.count === 0;
                        if (root.currentMode === "wallpapers")
                            return wallpapersList.count === 0;
                        return false;
                    }
                    opacity: visible ? 1 : 0

                    MaterialIcon {
                        text: "manage_search"
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.large
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: qsTr("No results")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.normal
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Behavior on opacity { Anim {} }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // UTILITY BUTTON COMPONENT
    // ═══════════════════════════════════════════════════════════════
    component UtilityButton: Item {
        id: utilBtn

        required property string icon
        required property string tooltip
        required property bool isActive

        signal clicked()

        implicitWidth: 36
        implicitHeight: 36

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: {
                if (utilBtn.isActive)
                    return Colours.palette.m3primary;
                if (utilMouse.containsMouse)
                    return Colours.tPalette.m3surfaceContainerHigh;
                return "transparent";
            }

            Behavior on color {
                CAnim {
                    duration: Appearance.anim.durations.small
                }
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: utilBtn.icon
            font.pointSize: 12
            color: utilBtn.isActive ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant

            Behavior on color {
                CAnim {
                    duration: Appearance.anim.durations.small
                }
            }
        }

        MouseArea {
            id: utilMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: utilBtn.clicked()
        }

        // Tooltip on hover
        StyledRect {
            id: tooltipRect
            visible: utilMouse.containsMouse
            anchors.top: parent.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colours.palette.m3inverseSurface
            radius: Appearance.rounding.small
            implicitWidth: tooltipText.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: tooltipText.implicitHeight + Appearance.padding.small * 2
            z: 100

            StyledText {
                id: tooltipText
                anchors.centerIn: parent
                text: utilBtn.tooltip
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3inverseOnSurface
            }
        }
    }
}
