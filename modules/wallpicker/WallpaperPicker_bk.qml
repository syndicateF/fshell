pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.services
import qs.config
import qs.modules.launcher.services as LauncherServices
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities
    required property ShellScreen screen

    anchors.fill: parent

    // ─── Constants ───────────────────────────────────────────────
    readonly property real cardWidth: 400
    readonly property real cardHeight: 420
    readonly property real cardSpacing: 10
    readonly property real skewFactor: -0.35
    readonly property real selectedScale: 1.4
    readonly property real unselectedScale: 0.325   // ≈ 130 / 400, matches the old hardcoded "130" pixel value
    readonly property real delegateWidth: cardWidth + cardSpacing

    property bool initialFocusSet: false

    // Reset when overlay opens
    Connections {
        target: root.visibilities

        function onWallpickerChanged(): void {
            if (root.visibilities.wallpicker) {
                root.initialFocusSet = false;
                LauncherServices.Schemes.reload();
                focusOnCurrent();
                carousel.forceActiveFocus();
            }
        }
    }

    // Karena Loader di Wrapper pakai active:root.visible, WallpaperPicker
    // baru dibuat SETELAH wallpicker sudah true — sehingga onWallpickerChanged
    // sudah terlewat.  onCompleted menjadi fallback yang reliable.
    Component.onCompleted: {
        root.initialFocusSet = false;
        LauncherServices.Schemes.reload();
        focusOnCurrent();
        carousel.forceActiveFocus();
    }

    // Find and focus the current wallpaper.
    // PENTING: initialFocusSet harus di-set SETELAH satu frame render selesai.
    // Kalau di-set synchronous bersamaan dengan currentIndex, delegate belum
    // punya "nilai lama" untuk dianimasikan FROM → sehingga Behavior tidak
    // pernah jalan.  Qt.callLater menunda flag ke iterasi event-loop berikutnya
    // sehingga QML punya satu pass layout untuk render posisi awal dulu.
    function focusOnCurrent(): void {
        const current = Wallpapers.actualCurrent;
        if (!current) {
            Qt.callLater(function() { root.initialFocusSet = true; });
            return;
        }
        for (let i = 0; i < Wallpapers.list.length; i++) {
            if (Wallpapers.list[i].path === current) {
                carousel.currentIndex = i;
                carousel.positionViewAtIndex(i, ListView.Center);
                Qt.callLater(function() { root.initialFocusSet = true; });
                return;
            }
        }
        Qt.callLater(function() { root.initialFocusSet = true; });
    }

    // ═══════════════════════════════════════════════════════════════
    // WALLPAPER NAME LABEL (above carousel)
    // ═══════════════════════════════════════════════════════════════
    StyledText {
        id: wallpaperLabel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: carousel.top
        anchors.bottomMargin: Appearance.spacing.large * 2

        text: {
            if (carousel.currentIndex >= 0 && carousel.currentIndex < Wallpapers.list.length)
                return Wallpapers.list[carousel.currentIndex].relativePath;
            return "";
        }

        font.pointSize: Appearance.font.size.large
        font.family: Appearance.font.family.sans
        color: "white"
        opacity: 0.9
    }

    // ═══════════════════════════════════════════════════════════════
    // WALLPAPER CAROUSEL (horizontal skewed cards)
    // ═══════════════════════════════════════════════════════════════
    ListView {
        id: carousel

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -bottomBar.height / 2

        height: root.cardHeight * root.selectedScale + 80

        orientation: ListView.Horizontal
        spacing: 0
        clip: false

        // Focus management — critical for arrow keys
        focus: true
        activeFocusOnTab: true
        keyNavigationEnabled: true

        highlightRangeMode: ListView.StrictlyEnforceRange
        // Center window matches the selected card's animated targetWidth
        preferredHighlightBegin: (width / 2) - ((root.cardWidth * root.selectedScale + root.cardSpacing) / 2)
        preferredHighlightEnd:   (width / 2) + ((root.cardWidth * root.selectedScale + root.cardSpacing) / 2)

        highlightMoveDuration: root.initialFocusSet ? Appearance.anim.durations.expressiveDefaultSpatial : 0
        cacheBuffer: 3000
        boundsBehavior: Flickable.StopAtBounds

        model: Wallpapers.list

        Component.onCompleted: forceActiveFocus()

        // Keyboard navigation
        Keys.onLeftPressed: {
            if (carousel.currentIndex > 0)
                carousel.currentIndex--;
        }
        Keys.onRightPressed: {
            if (carousel.currentIndex < carousel.count - 1)
                carousel.currentIndex++;
        }
        Keys.onEscapePressed: root.visibilities.wallpicker = false
        Keys.onReturnPressed: {
            if (carousel.currentIndex >= 0 && carousel.currentIndex < Wallpapers.list.length) {
                const wp = Wallpapers.list[carousel.currentIndex];
                if (Colours.scheme === "dynamic" && wp.path !== Wallpapers.actualCurrent)
                    Wallpapers.previewColourLock = true;
                Wallpapers.setWallpaper(wp.path);
            }
        }

        // Mouse wheel navigation
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true

            property int scrollAccum: 0

            onWheel: wheel => {
                const dx = wheel.angleDelta.x;
                const dy = wheel.angleDelta.y;
                const delta = Math.abs(dx) > Math.abs(dy) ? dx : dy;

                scrollAccum += delta;

                if (Math.abs(scrollAccum) >= 200) {
                    if (scrollAccum > 0 && carousel.currentIndex > 0)
                        carousel.currentIndex--;
                    else if (scrollAccum < 0 && carousel.currentIndex < carousel.count - 1)
                        carousel.currentIndex++;
                    scrollAccum = 0;
                }

                wheel.accepted = true;
            }
        }

        delegate: Item {
            id: delegateRoot

            required property var modelData
            required property int index

            readonly property bool isCurrent: ListView.isCurrentItem

            // ── FIX: use explicit targetWidth so the Behavior always has a
            //         numeric value to animate FROM and TO.  When width was
            //         written as a ternary directly, QML often skips the
            //         Behavior because the binding re-evaluates to the same
            //         object reference rather than triggering a value change. ──
            readonly property real targetWidth: isCurrent
                ? (root.cardWidth * root.selectedScale + root.cardSpacing)
                : (root.cardWidth * root.unselectedScale + root.cardSpacing)

            width: targetWidth
            height: carousel.height

            z: isCurrent ? 10 : 1

            Behavior on width {
                enabled: root.initialFocusSet
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.InOutQuad
                }
            }

            // Visual card — width tracks targetWidth minus spacing so it
            // also animates smoothly when the parent width changes.
            Item {
                id: cardVisual

                anchors.centerIn: parent
                // FIX: bind to parent.width (which is already animated) so
                //      cardVisual follows the live interpolated value instead
                //      of jumping between two hard-coded sizes.
                width: parent.width - root.cardSpacing
                height: root.cardHeight
                opacity: delegateRoot.isCurrent ? 1.0 : 0.5

                Behavior on opacity {
                    enabled: root.initialFocusSet
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
                    }
                }

                // Skew transform (parallelogram)
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(
                        1, root.skewFactor, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1
                    )
                }

                // Click to select + apply
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (delegateRoot.isCurrent) {
                            // Already selected — apply wallpaper
                            if (Colours.scheme === "dynamic" && delegateRoot.modelData.path !== Wallpapers.actualCurrent)
                                Wallpapers.previewColourLock = true;
                            Wallpapers.setWallpaper(delegateRoot.modelData.path);
                        } else {
                            // Not selected — just navigate to it
                            carousel.currentIndex = delegateRoot.index;
                        }
                    }
                }

                // Border layer (blurred dominant color from image)
                Image {
                    anchors.fill: parent
                    source: "file://" + (delegateRoot.modelData?.path ?? "")
                    sourceSize: Qt.size(1, 1)
                    fillMode: Image.Stretch
                    asynchronous: true
                }

                // Main image content (clipped inside border)
                Item {
                    anchors.fill: parent
                    anchors.margins: 3
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        color: Colours.palette.m3surfaceContainer
                    }

                    Image {
                        anchors.centerIn: parent
                        // Counter-skew offset so image looks straight
                        anchors.horizontalCenterOffset: -(root.cardHeight * Math.abs(root.skewFactor)) / 2
                        // Oversize to fill the parallelogram shape after counter-skew
                        width: root.cardWidth + (root.cardHeight * Math.abs(root.skewFactor)) + 40
                        height: root.cardHeight
                        fillMode: Image.PreserveAspectCrop
                        source: "file://" + (delegateRoot.modelData?.path ?? "")
                        asynchronous: true
                        sourceSize: Qt.size(800, 600)

                        // Counter-skew to make image appear straight
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(
                                1, -root.skewFactor, 0, 0,
                                0, 1, 0, 0,
                                0, 0, 1, 0,
                                0, 0, 0, 1
                            )
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // BOTTOM BAR (Schemes + Variants)
    // ═══════════════════════════════════════════════════════════════
    StyledRect {
        id: bottomBar

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.spacing.large * 2

        color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 0.85)
        radius: Appearance.rounding.large

        implicitWidth: bottomBarContent.implicitWidth + Appearance.padding.large * 2
        implicitHeight: bottomBarContent.implicitHeight + Appearance.padding.normal * 2

        // Clamp to screen width
        width: Math.min(implicitWidth, root.width - Appearance.spacing.large * 4)

        Column {
            id: bottomBarContent

            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            // ─── Scheme Row ──────────────────────────────────────
            Row {
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "palette"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3primary
                }

                ListView {
                    id: schemesRow

                    width: Math.min(implicitWidth, root.width - Appearance.spacing.large * 8)
                    height: 32
                    orientation: ListView.Horizontal
                    spacing: Appearance.spacing.small
                    clip: true
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds

                    implicitWidth: contentWidth

                    model: LauncherServices.Schemes.list

                    delegate: Item {
                        id: schemeChip

                        required property var modelData
                        required property int index

                        readonly property string schemeName: `${modelData?.name ?? ""} ${modelData?.flavour ?? ""}`
                        readonly property bool isCurrentScheme: schemeName === LauncherServices.Schemes.currentScheme

                        width: chipRow.implicitWidth + Appearance.padding.normal * 2
                        height: 32

                        StyledRect {
                            anchors.fill: parent
                            radius: Appearance.rounding.full
                            color: schemeChip.isCurrentScheme ? Colours.palette.m3primaryContainer : Qt.rgba(Colours.palette.m3surfaceContainerHigh.r, Colours.palette.m3surfaceContainerHigh.g, Colours.palette.m3surfaceContainerHigh.b, 0.7)
                            border.width: schemeChip.isCurrentScheme ? 2 : 0
                            border.color: Colours.palette.m3primary

                            Behavior on color { CAnim { duration: Appearance.anim.durations.small } }
                        }

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small / 2

                            // Color preview dot
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                radius: 7
                                color: `#${schemeChip.modelData?.colours?.primary ?? "888888"}`
                                border.width: 1
                                border.color: Qt.rgba(0, 0, 0, 0.2)
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: `${schemeChip.modelData?.name ?? ""} ${schemeChip.modelData?.flavour ?? ""}`
                                font.pointSize: Appearance.font.size.small
                                color: schemeChip.isCurrentScheme ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                font.family: Appearance.font.family.sans
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: schemeChip.modelData.onClicked(root)
                        }
                    }
                }
            }

            // ─── Separator ───────────────────────────────────────
            Rectangle {
                width: bottomBarContent.width
                height: 1
                color: Colours.palette.m3outlineVariant
                opacity: 0.3
            }

            // ─── Variant Row ─────────────────────────────────────
            Row {
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "colors"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3primary
                }

                Row {
                    id: variantsRow
                    spacing: Appearance.spacing.small / 2

                    Repeater {
                        model: LauncherServices.M3Variants.list

                        delegate: Item {
                            id: variantChip

                            required property var modelData
                            required property int index

                            readonly property bool isCurrentVariant: modelData.variant === LauncherServices.Schemes.currentVariant

                            width: variantChipRow.implicitWidth + Appearance.padding.normal * 2
                            height: 32

                            StyledRect {
                                anchors.fill: parent
                                radius: Appearance.rounding.full
                                color: variantChip.isCurrentVariant ? Colours.palette.m3primaryContainer : Qt.rgba(Colours.palette.m3surfaceContainerHigh.r, Colours.palette.m3surfaceContainerHigh.g, Colours.palette.m3surfaceContainerHigh.b, 0.7)
                                border.width: variantChip.isCurrentVariant ? 2 : 0
                                border.color: Colours.palette.m3primary

                                Behavior on color { CAnim { duration: Appearance.anim.durations.small } }
                            }

                            Row {
                                id: variantChipRow
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.small / 2

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: variantChip.modelData.icon
                                    font.pointSize: Appearance.font.size.small
                                    color: variantChip.isCurrentVariant ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: variantChip.modelData.name
                                    font.pointSize: Appearance.font.size.small
                                    color: variantChip.isCurrentVariant ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                    font.family: Appearance.font.family.sans
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: variantChip.modelData.onClicked(root)
                            }
                        }
                    }
                }
            }
        }
    }
}
