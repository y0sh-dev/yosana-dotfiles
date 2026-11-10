import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import "../services"

Item {
    id: mediaRoot

    // Dynamically tracked active player (Reactive across multiple players and rapid stream changes)
    property var activePlayer: null

    function updateActivePlayer() {
        const players = Mpris.players.values;
        if (!players || players.length === 0) {
            activePlayer = null;
            return;
        }

        // 1. Prioritize actively playing player with valid track metadata
        for (let i = 0; i < players.length; i++) {
            const p = players[i];
            if (p && p.isPlaying && p.trackTitle && p.trackTitle.length > 0) {
                activePlayer = p;
                return;
            }
        }

        // 2. Fallback to any player with track metadata
        for (let i = 0; i < players.length; i++) {
            const p = players[i];
            if (p && p.trackTitle && p.trackTitle.length > 0) {
                activePlayer = p;
                return;
            }
        }

        // 3. Fallback to first registered player
        activePlayer = players[0] || null;
    }

    // Dynamic Multi-Player Signal Watcher
    Instantiator {
        model: Mpris.players.values
        delegate: QtObject {
            required property var modelData

            readonly property Connections conn: Connections {
                target: modelData
                function onIsPlayingChanged() { mediaRoot.updateActivePlayer(); }
                function onPlaybackStateChanged() { mediaRoot.updateActivePlayer(); }
                function onTrackTitleChanged() { mediaRoot.updateActivePlayer(); }
                function onTrackArtUrlChanged() { mediaRoot.updateActivePlayer(); }
            }
        }
        onCountChanged: mediaRoot.updateActivePlayer()
    }

    Component.onCompleted: updateActivePlayer()

    readonly property bool hasTrack: activePlayer && activePlayer.trackTitle && activePlayer.trackTitle.length > 0
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property string displayTitle: hasTrack ? (activePlayer.trackArtist ? (activePlayer.trackTitle + " • " + activePlayer.trackArtist) : activePlayer.trackTitle) : ""
    readonly property string trackTitle: hasTrack ? (activePlayer.trackTitle || "Unknown Track") : ""
    readonly property string trackArtist: hasTrack ? (activePlayer.trackArtist || "Unknown Artist") : ""
    readonly property string artUrl: (hasTrack && activePlayer.trackArtUrl) ? activePlayer.trackArtUrl : ""
    // Real-Time Progress Interpolation Engine (Dead Reckoning)
    property real basePosition: 0.0
    property real lastUpdateTime: 0.0
    property real smoothPosition: 0.0

    readonly property real positionRatio: (activePlayer && activePlayer.length > 0) 
        ? Math.min(1.0, Math.max(0.0, smoothPosition / activePlayer.length)) 
        : 0.0

    Connections {
        target: mediaRoot.activePlayer
        function onPositionChanged() {
            if (!mediaRoot.activePlayer) return;
            mediaRoot.basePosition = mediaRoot.activePlayer.position;
            mediaRoot.lastUpdateTime = Date.now();
            mediaRoot.smoothPosition = mediaRoot.basePosition;
        }
        function onPlaybackStateChanged() {
            if (!mediaRoot.activePlayer) return;
            mediaRoot.basePosition = mediaRoot.activePlayer.position;
            mediaRoot.lastUpdateTime = Date.now();
            mediaRoot.smoothPosition = mediaRoot.basePosition;
        }
    }

    onActivePlayerChanged: {
        if (activePlayer) {
            basePosition = activePlayer.position;
            lastUpdateTime = Date.now();
            smoothPosition = basePosition;
        }
    }

    // 30fps lightweight interpolation timer (active only when expanded & playing)
    Timer {
        id: progressInterpolationTimer
        interval: 33
        running: mediaRoot.isExpanded && mediaRoot.isPlaying && mediaRoot.hasTrack
        repeat: true
        onTriggered: {
            if (!mediaRoot.activePlayer || mediaRoot.activePlayer.length <= 0) return;
            const elapsedSec = (Date.now() - mediaRoot.lastUpdateTime) / 1000.0;
            const rate = (mediaRoot.activePlayer.rate && mediaRoot.activePlayer.rate > 0) ? mediaRoot.activePlayer.rate : 1.0;
            const estimated = mediaRoot.basePosition + (elapsedSec * rate);
            mediaRoot.smoothPosition = Math.min(mediaRoot.activePlayer.length, estimated);
        }
    }

    // Smart Island Expansion State
    property bool isExpanded: false

    onHasTrackChanged: {
        if (!hasTrack) isExpanded = false;
    }

    // Auto-collapse timer when mouse leaves expanded island
    Timer {
        id: autoCollapseTimer
        interval: 6000
        repeat: false
        onTriggered: {
            if (mediaRoot.isExpanded && !globalPillHover.hovered) {
                mediaRoot.isExpanded = false;
            }
        }
    }

    HoverHandler {
        id: globalPillHover
        onHoveredChanged: {
            if (!hovered && mediaRoot.isExpanded) {
                autoCollapseTimer.restart();
            }
        }
    }

    implicitHeight: Theme.islandHeight
    implicitWidth: isExpanded ? expandedWidth : compactWidth

    readonly property int compactWidth: pillContainer.implicitWidth + 12
    // Generously expanded width (520px) for rich channel and title presentation
    readonly property int expandedWidth: Math.round(520 * Theme.uiScale)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    // Continuous smooth animation for idle breathing
    property real animPhase: 0.0
    NumberAnimation on animPhase {
        from: 0.0
        to: Math.PI * 2
        duration: 2600
        loops: Animation.Infinite
    }

    // Vinyl record rotation animation (playing only, 12s per revolution)
    property real diskRotation: 0.0
    NumberAnimation on diskRotation {
        from: 0.0
        to: 360.0
        duration: 12000
        loops: Animation.Infinite
        running: mediaRoot.isPlaying && mediaRoot.isExpanded
    }

    // Main Outer Container
    Rectangle {
        id: pillContainer
        anchors.centerIn: parent
        implicitHeight: 30
        implicitWidth: isExpanded ? (mediaRoot.expandedWidth - 12) : (contentRow.implicitWidth + 18)
        radius: height / 2

        color: isExpanded 
            ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.65)
            : (compactMouse.containsMouse ? Theme.surfaceHover : "transparent")

        border.color: isExpanded 
            ? Theme.accent 
            : (compactMouse.containsMouse ? Theme.border : "transparent")
        border.width: 1

        scale: (isExpanded || !compactMouse.pressed) ? 1.0 : 0.96
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        // =====================================================================
        // MODE 1: COMPACT VIEW (Normal TopBar Pill)
        // =====================================================================
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 7
            visible: !mediaRoot.isExpanded
            opacity: !mediaRoot.isExpanded ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 140 } }

            // Active Track State
            Row {
                visible: mediaRoot.hasTrack
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: mediaRoot.isPlaying ? "󰎈" : "󰏤"
                    color: Theme.accent
                    font.pixelSize: 16
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter

                    scale: mediaRoot.isPlaying ? (1.0 + Math.sin(mediaRoot.animPhase * 2) * 0.08) : 1.0
                    Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
                }

                Text {
                    text: mediaRoot.displayTitle
                    color: Theme.fg
                    font.pixelSize: 14
                    font.bold: true
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 180)
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
                }
            }

            // Idle State
            Row {
                visible: !mediaRoot.hasTrack
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "󰋋"
                    color: Theme.accent
                    font.pixelSize: 16
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter

                    transform: Rotation {
                        origin.x: 8; origin.y: 8
                        angle: Math.sin(mediaRoot.animPhase) * 6
                    }
                }

                Text {
                    text: "Listening"
                    color: Theme.fg
                    opacity: 0.72
                    font.pixelSize: 14
                    font.bold: true
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }

                Repeater {
                    model: 3
                    delegate: Text {
                        text: "•"
                        font.pixelSize: 14
                        color: Theme.fg
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: (0.30 + 0.60 * Math.max(0, Math.sin(mediaRoot.animPhase * 2 + index * 0.9))) * 0.72
                    }
                }

                Text {
                    text: "🎶"
                    font.pixelSize: 15
                    anchors.verticalCenter: parent.verticalCenter
                    transform: [
                        Translate { y: Math.sin(mediaRoot.animPhase) * 1.8 },
                        Rotation { origin.x: 7; origin.y: 7; angle: Math.cos(mediaRoot.animPhase) * 4 }
                    ]
                }
            }
        }

        // =====================================================================
        // MODE 2: EXPANDED SMART ISLAND
        // =====================================================================
        RowLayout {
            id: expandedRow
            anchors.fill: parent
            anchors.leftMargin: 42 // Leaves perfect room for the overlapping circular disk
            anchors.rightMargin: 10
            spacing: 12
            visible: mediaRoot.isExpanded
            opacity: mediaRoot.isExpanded ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // Track Info & Minimalist Progress Line (Perfect Vertical Center + Marquee)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Single-line combined track and artist marquee (Snake chasing tail)
                MarqueeText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -2 // Balanced vertical center considering bottom progress line
                    height: 16
                    text: mediaRoot.trackArtist.length > 0 
                        ? (mediaRoot.trackTitle + "  —  " + mediaRoot.trackArtist)
                        : mediaRoot.trackTitle
                    color: Theme.fg
                    pixelSize: 12
                    fontBold: true
                    running: mediaRoot.isExpanded || globalPillHover.hovered
                    speed: 30
                    gap: 40
                }

                // Micro Progress Bar (Cleanly anchored to the bottom with interactive seek)
                Rectangle {
                    id: progressTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    implicitHeight: 2
                    radius: 1
                    color: Qt.rgba(255, 255, 255, 0.12)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * mediaRoot.positionRatio
                        radius: 1
                        color: Theme.accent

                        Behavior on width {
                            NumberAnimation { duration: 50; easing.type: Easing.Linear }
                        }
                    }

                    // Interactive Seek Area
                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -6
                        anchors.bottomMargin: -6
                        cursorShape: Qt.PointingHandCursor
                        z: 2
                        onClicked: function(mouse) {
                            if (!mediaRoot.activePlayer || mediaRoot.activePlayer.length <= 0) return;
                            const targetRatio = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            mediaRoot.activePlayer.position = targetRatio * mediaRoot.activePlayer.length;
                            mediaRoot.basePosition = mediaRoot.activePlayer.position;
                            mediaRoot.lastUpdateTime = Date.now();
                            mediaRoot.smoothPosition = mediaRoot.basePosition;
                            autoCollapseTimer.restart();
                        }
                    }
                }

                // Click track info area to toggle collapse
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mediaRoot.isExpanded = false;
                    }
                }
            }

            // Large, Prominent Playback Controls (No Close Button)
            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                // Previous Track (Large 28px)
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: prevMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: prevMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: prevMouse.containsMouse ? Theme.accent : Theme.fgSoft
                        font.pixelSize: 15
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaRoot.activePlayer) mediaRoot.activePlayer.previous();
                            autoCollapseTimer.restart();
                        }
                    }
                }

                // Play / Pause Toggle (Prominent 28px)
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: playMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                    border.color: Theme.accent
                    border.width: 1

                    scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: mediaRoot.isPlaying ? "󰏤" : "󰐊"
                        color: playMouse.containsMouse ? Theme.bgDark : Theme.accent
                        font.pixelSize: 16
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaRoot.activePlayer) mediaRoot.activePlayer.togglePlaying();
                            autoCollapseTimer.restart();
                        }
                    }
                }

                // Next Track (Large 28px)
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: nextMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: nextMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: nextMouse.containsMouse ? Theme.accent : Theme.fgSoft
                        font.pixelSize: 15
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaRoot.activePlayer) mediaRoot.activePlayer.next();
                            autoCollapseTimer.restart();
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // OVERLAPPING CIRCULAR DISK (Flawless Vinyl Record with VRAM & State Guard)
    // =========================================================================
    Item {
        id: circularArtDisk
        visible: mediaRoot.isExpanded
        opacity: mediaRoot.isExpanded ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        // Diameter: 34px (overlaps the 30px pill by 2px on top/bottom)
        width: 34
        height: 34

        anchors.left: pillContainer.left
        anchors.leftMargin: -4 // Intentionally overlaps and breaks out of the pill's left border
        anchors.verticalCenter: pillContainer.verticalCenter

        // 1. Offscreen Stationary Art Source
        // Positioned offscreen (x: -9999) with visible: true so Qt scene graph keeps actively
        // updating textures even on rapid asynchronous network changes.
        Item {
            id: staticArtSource
            width: 34
            height: 34
            visible: true
            x: -9999

            // Obsidian vinyl record base: ensures disc is never a blank hole
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#12131b"
            }

            Image {
                id: artImage
                anchors.fill: parent
                source: mediaRoot.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                // CRITICAL VRAM GUARD: Decodes thumbnail to 68x68 (2x HiDPI).
                // Prevents VRAM exhaustion when cycling through dozens of 1080p/4K YouTube/browser streams!
                sourceSize.width: 68
                sourceSize.height: 68
                visible: status === Image.Ready && mediaRoot.artUrl.length > 0
            }

            // Fallback musical glyph displayed whenever artwork is loading, unavailable, or errored
            Text {
                anchors.centerIn: parent
                visible: !artImage.visible
                text: "󰎈"
                color: Theme.accent
                font.pixelSize: 18
                font.family: Theme.fontFamily
            }
        }

        // 2. Offscreen Pure Circle Mask
        Rectangle {
            id: circleMaskSource
            width: 34
            height: 34
            radius: 17
            color: "black"
            visible: true
            x: -9999
        }

        // Active Texture Feeds with live update guarantees
        ShaderEffectSource {
            id: artTextureSource
            sourceItem: staticArtSource
            live: true
            hideSource: false
        }

        ShaderEffectSource {
            id: maskTextureSource
            sourceItem: circleMaskSource
            live: false
            hideSource: false
        }

        // 3. Rotating Vinyl Record (Pure GPU transformed presentation layer)
        Item {
            id: rotatingVinylRecord
            anchors.fill: parent
            rotation: mediaRoot.diskRotation

            // OpacityMask: Guaranteed smooth anti-aliased circular rendering
            OpacityMask {
                anchors.fill: parent
                source: artTextureSource
                maskSource: maskTextureSource
            }

            // Center Vinyl Spindle Hole (Authentic turntable cutout)
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: Theme.bgDark
                border.color: Qt.rgba(255, 255, 255, 0.4)
                border.width: 1
                visible: artImage.visible
            }

            // Outer Ring Border of the Vinyl Disk
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: Theme.accent
                border.width: 1.5
            }
        }

        // Click disk to toggle collapse
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                mediaRoot.isExpanded = false;
            }
        }
    }

    // Compact Mode Click Trigger (Safe Left-Click only: avoids accidental track skipping)
    MouseArea {
        id: compactMouse
        anchors.fill: parent
        enabled: !mediaRoot.isExpanded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        onClicked: function(mouse) {
            if (!mediaRoot.activePlayer) return;
            if (mediaRoot.hasTrack) {
                mediaRoot.isExpanded = true;
                autoCollapseTimer.restart();
            } else {
                mediaRoot.activePlayer.togglePlaying();
            }
        }
    }
}
