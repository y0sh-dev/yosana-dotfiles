pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: theme

    // Dedicated trigger file touched immediately when wallpaper workflow completes
    property string triggerPath: "/home/yukkkk1/.cache/wal_quickshell_reload"
    property string walPath: "/home/yukkkk1/.cache/wal/colors.json"

    // --- Grid Dip State (Power Outage & Restoral Animation) ---
    // true: Instant power cut / dimming while switching
    // false: Normal power grid operational, luminescent illumination
    property bool isGridDip: false

    // Transition timing: rapid cut (120ms InQuad), calm majestic restoral (500ms OutCubic)
    readonly property int animDuration: isGridDip ? 120 : 500
    readonly property int animEasing: isGridDip ? Easing.InQuad : Easing.OutCubic

    // Target Colors from Pywal
    property color targetBg: "#000000"
    property color targetFg: "#98beda"
    property color targetSubtext: "#6a8598"
    property color targetAccent: "#887c8d"
    property color targetSurface: "#0e1117"
    property color targetBorder: "#252b38"
    property color targetUrgent: "#a05042"
    property color targetSun: "#d9544d" // Red for Sunday (color9 / color1)
    property color targetSat: "#5e81ac" // Blue for Saturday (color12 / color4)

    // Dip / Emergency Standby Colors (Dystopian Minimal Infrastructure)
    readonly property color dipFg: "#364152"
    readonly property color dipSubtext: "#202633"
    readonly property color dipAccent: "#262f3d"
    readonly property color dipBorder: "#141820"
    readonly property color dipUrgent: "#452424"
    readonly property color dipEmpty: "#1f2533"

    // Active Exposed Colors
    readonly property color bg: targetBg
    readonly property color bgIsland: targetBg
    readonly property color surface: targetSurface
    readonly property color surfaceHover: isGridDip ? "#10141c" : Qt.tint(targetBg, Qt.rgba(1, 1, 1, 0.10))

    readonly property color fg: isGridDip ? dipFg : targetFg
    readonly property color fgSoft: isGridDip ? dipFg : "#c2cbd6" // Gentle, eye-friendly soft off-white (prevents glare in dark rooms)
    readonly property color subtext: isGridDip ? dipSubtext : targetSubtext
    readonly property color subtextDim: isGridDip ? dipSubtext : "#788796" // Calm uniform secondary tone
    readonly property color accent: isGridDip ? dipAccent : targetAccent
    readonly property color border: isGridDip ? dipBorder : targetBorder
    readonly property color urgent: isGridDip ? dipUrgent : targetUrgent
    readonly property color colorSun: isGridDip ? dipUrgent : targetSun
    readonly property color colorSat: isGridDip ? dipAccent : targetSat
    readonly property color tempHot: isGridDip ? dipUrgent : "#f07178" // Vivid coral-red clearly visible in dark room
    readonly property color tempCold: isGridDip ? dipAccent : "#6cb6ff" // Crisp sky-blue clearly visible in dark room

    readonly property color wsActive: isGridDip ? dipAccent : targetAccent
    readonly property color wsDisplayed: isGridDip ? dipFg : targetFg
    readonly property color wsOccupied: isGridDip ? dipSubtext : targetSubtext
    readonly property color wsEmpty: isGridDip ? dipEmpty : Qt.tint(targetBg, Qt.rgba(targetSubtext.r, targetSubtext.g, targetSubtext.b, 0.45))

    // Metrics & Typography
    property int barHeight: 48
    property int islandHeight: 40
    property int islandPaddingH: 20
    property int islandPaddingV: 10
    property int radiusIsland: 20
    property int radiusPill: 10
    property int radiusSmall: 6
    property int wsFontSize: 16
    property int clockFontSize: 20
    property string fontFamily: "FiraCode Nerd Font"

    // Grid Dip sequence timer:
    // 1) Trigger signal received -> isGridDip = true (instant drop in 120ms)
    // 2) 120ms later (at full darkness) -> execute fresh cat command
    property var gridDipTimer: Timer {
        interval: 120
        repeat: false
        onTriggered: {
            if (!walProc.running) {
                walProc.running = true;
            }
        }
    }

    // Trigger file watcher (never stale, zero polling overhead)
    readonly property FileView triggerView: FileView {
        path: theme.triggerPath
        blockLoading: true
        watchChanges: true
        onFileChanged: {
            theme.isGridDip = true;
            theme.gridDipTimer.restart();
        }
    }

    // Process-based reader: executes 'cat' directly to completely bypass QML FileView caching bugs
    property var walProc: Process {
        command: ["cat", theme.walPath]
        stdout: StdioCollector {
            onDataChanged: {
                var raw = (data || "").toString().trim();
                if (raw.length > 0) {
                    theme.applyColors(raw);
                }
                // Restore power with freshly loaded palette
                theme.isGridDip = false;
            }
        }
    }

    Component.onCompleted: {
        walProc.running = true;
    }

    function applyColors(raw) {
        try {
            const parsed = JSON.parse(raw);
            if (parsed.special) {
                if (parsed.special.background) theme.targetBg = parsed.special.background;
                if (parsed.special.foreground) theme.targetFg = parsed.special.foreground;
            }
            if (parsed.colors) {
                const c = parsed.colors;
                if (c.color0) theme.targetSurface = c.color0;
                if (c.color4) theme.targetAccent = c.color4;
                if (c.color8) theme.targetSubtext = c.color8;
                theme.targetUrgent = c.color1 || c.color3 || "#a05042";
                theme.targetSun = c.color9 || c.color1 || "#d9544d";
                theme.targetSat = c.color12 || c.color4 || "#5e81ac";
            }
            console.log("Fresh wal colors applied via cat: wallpaper=" + (parsed.wallpaper || "") + " accent=" + theme.targetAccent);
        } catch (e) {
            console.log("Failed to parse fresh colors:", e);
        }
    }
}
