pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    // Adaptive Resolution Scaling (Baseline: 2560x1440 WQHD)
    // Automatically adapts popups & modals to 1080p (0.75), 1440p (1.0), and 4K (1.5)
    readonly property real uiScale: {
        if (Quickshell.screens && Quickshell.screens.length > 0) {
            var s = Quickshell.screens[0];
            return Math.max(0.7, Math.min(s.width / 2560, s.height / 1440));
        }
        return 1.0;
    }

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
    property color targetWarning: "#d19a66"
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
    readonly property color warning: isGridDip ? dipUrgent : targetWarning
    readonly property color bgDark: targetBg
    readonly property color colorSun: isGridDip ? dipUrgent : targetSun
    readonly property color colorSat: isGridDip ? dipAccent : targetSat
    readonly property color tempHot: isGridDip ? dipUrgent : "#f07178" // Vivid coral-red clearly visible in dark room
    readonly property color tempCold: isGridDip ? dipAccent : "#6cb6ff" // Crisp sky-blue clearly visible in dark room

    readonly property color wsActive: isGridDip ? dipAccent : targetAccent
    readonly property color wsDisplayed: isGridDip ? dipFg : fgSoft // "Current white": high-clarity soft white for displayed sub-monitors
    readonly property color wsOccupied: isGridDip ? dipSubtext : Qt.tint(targetBg, Qt.rgba(1, 1, 1, 0.48)) // Subtly white, clearly distinguished from empty
    readonly property color wsEmpty: isGridDip ? dipEmpty : Qt.tint(targetBg, Qt.rgba(1, 1, 1, 0.18)) // Quiet/dim baseline for empty workspaces

    // Metrics & Typography
    property int barHeight: 48
    property int islandHeight: 40
    property int islandPaddingH: 20
    property int islandPaddingV: 10
    property int radiusIsland: 20
    property int radiusWindow: 14
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

    // Safety watchdog: ensure shell never gets trapped in darkness if file I/O or cat fails
    property var gridDipWatchdog: Timer {
        interval: 800
        repeat: false
        onTriggered: {
            if (theme.isGridDip) {
                console.warn("Theme: Grid Dip watchdog triggered after 800ms - forcing power restoral");
                theme.isGridDip = false;
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
            theme.gridDipWatchdog.restart();
        }
    }

    // Process-based reader: executes 'cat' directly to completely bypass QML FileView caching bugs
    property var walProc: Process {
        command: ["cat", theme.walPath]
        onExited: {
            theme.gridDipWatchdog.stop();
            if (theme.isGridDip) {
                theme.isGridDip = false;
            }
        }
        stdout: StdioCollector {
            onDataChanged: {
                theme.gridDipWatchdog.stop();
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

    // --- WCAG 2.1 Contrast & Chromatic Resilience Engineering ---
    function relativeLuminance(col) {
        function channel(v) {
            return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        }
        var c = Qt.color(col);
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
    }

    function contrastRatio(col1, col2) {
        var l1 = relativeLuminance(col1);
        var l2 = relativeLuminance(col2);
        return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
    }

    // Pick the most red-dominant color that meets contrast requirements against background
    function pickReddest(candidates, fallback) {
        var best = null;
        var bestScore = -1;
        for (var i = 0; i < candidates.length; i++) {
            var hex = candidates[i];
            if (!hex) continue;
            var c = Qt.color(hex);
            // Redness metric: positive when red channel significantly exceeds green & blue
            var rDominance = c.r - Math.max(c.g, c.b);
            var cr = contrastRatio(hex, theme.targetBg);
            if (cr >= 3.0 && rDominance > 0.05) {
                var score = rDominance * 2.0 + (cr >= 4.5 ? 1.0 : 0.0);
                if (score > bestScore) {
                    bestScore = score;
                    best = hex;
                }
            }
        }
        if (!best || contrastRatio(best, theme.targetBg) < 4.5) {
            return fallback;
        }
        return best;
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

                // Axis 4 Refinement: Guard urgent & red against smart-sort navy collapse
                theme.targetUrgent = pickReddest([c.color9, c.color1, c.color3], "#e06c75");
                theme.targetSun = pickReddest([c.color9, c.color1, c.color3], "#d9544d");

                theme.targetWarning = (c.color3 && contrastRatio(c.color3, theme.targetBg) >= 3.0) ? c.color3 : "#d19a66";
                theme.targetSat = (c.color12 || c.color4) || "#5e81ac";

                // Axis 4 Refinement: Collision guard between accent and subtext
                // In monochromatic/low-saturation schemes, color4 (accent) and color8 (subtext) can converge below 1.35:1
                var crAccentSub = contrastRatio(theme.targetAccent, theme.targetSubtext);
                if (crAccentSub < 1.35) {
                    console.log("Theme: Accent and subtext collision detected (" + crAccentSub.toFixed(2) + ":1). Applying hardened neutral subtext.");
                    theme.targetSubtext = theme.subtextDim;
                }
            }
            console.log("Fresh wal colors applied via cat: wallpaper=" + (parsed.wallpaper || "") + " accent=" + theme.targetAccent + " urgent=" + theme.targetUrgent);
        } catch (e) {
            console.log("Failed to parse fresh colors:", e);
        }
    }
}
