import QtQuick
import "../../services"

Item {
    id: sliderRoot

    property real from: 0.0
    property real to: 1.0
    property real value: 0.0
    property bool isMuted: false

    // Real-time Peak Level Meter (for microphone input)
    property bool showPeak: false
    property real peak: 0.0

    signal moved(real val)

    // Balanced 14px capsule bar - easily clickable, tactile, and sleek
    implicitHeight: 14
    implicitWidth: 280

    readonly property real progress: Math.max(0.0, Math.min(1.0, (value - from) / Math.max(0.001, to - from)))

    Rectangle {
        id: trackBg
        anchors.fill: parent
        radius: 7
        // Consistent with Output slider: pure Theme.surfaceHover background
        color: Theme.surfaceHover
        border.color: sliderMouse.containsMouse ? Theme.border : "transparent"
        border.width: 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 120 } }

        // =====================================================================
        // Layer 0: Infrastructure tick marks (25%, 50%, 75%) - Identical to Output
        // =====================================================================
        Row {
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.25
            anchors.rightMargin: parent.width * 0.25
            spacing: 0

            Rectangle {
                x: 0
                width: 1
                height: 5
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.border
                opacity: 0.35
            }
            Item { width: (trackBg.width * 0.5) - 2; height: 1 }
            Rectangle {
                width: 1
                height: 5
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.border
                opacity: 0.35
            }
        }

        // =====================================================================
        // Layer 1 (Base): Volume Gain Setting Capsule (fillBar)
        // 100% unified with Output slider in tone, luminosity, and solid presence
        // =====================================================================
        Rectangle {
            id: fillBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, parent.width * sliderRoot.progress)
            radius: 7

            // Exact 1:1 color match with Output slider: pure Theme.accent
            color: {
                if (sliderRoot.isMuted) return Theme.urgent;
                if (sliderRoot.value > 1.0) return Theme.warning;
                return sliderMouse.containsMouse ? Qt.tint(Theme.accent, Qt.rgba(1, 1, 1, 0.15)) : Theme.accent;
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // =====================================================================
        // Layer 2 (Top Interactive): Relative Dark Smoked Glass Overlay
        // Constrained strictly to the gain setting range (fillBar.width * peak).
        // A translucent smoked dark glass veil (0.30 opacity) overlays the bright base,
        // producing a rich depth and natural gradient without bleeding past the threshold.
        // =====================================================================
        Rectangle {
            id: peakGlassOverlay
            visible: sliderRoot.showPeak && !sliderRoot.isMuted && sliderRoot.peak > 0.01 && fillBar.width > 0
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            // Strictly relative to user gain setting: physically bounded by fillBar.width
            width: Math.max(0, fillBar.width * Math.min(1.0, sliderRoot.peak))
            radius: 7

            // Refined smoked dark glass: black veil in normal range, urgent red tint at clipping
            color: {
                if (sliderRoot.peak > 0.88) {
                    return Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.40);
                }
                return Qt.rgba(0, 0, 0, 0.30);
            }

            // Delicate 1px specular leading edge highlight on the wave crest
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1.5
                color: Qt.rgba(1, 1, 1, 0.4)
                visible: parent.width > 4
            }

            Behavior on width {
                NumberAnimation {
                    duration: 50
                    easing.type: Easing.OutQuad
                }
            }
            Behavior on color { ColorAnimation { duration: 80 } }
        }

        // =====================================================================
        // Layer 3 (Detail): Flush Curved Bottom Contour Neon Strip (2px)
        // Solves the corner radius clipping overhang with geometric perfection:
        // Uses a concentric 14px capsule (radius: 7) masked through a bottom 2px slit.
        // The bottom-left arc curves precisely along the slider's radius-7 pill boundary,
        // eliminating any protruding square corners or forward horizontal displacement.
        // =====================================================================
        Item {
            id: peakContourWindow
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            // Strictly synchronised with Layer 2: zero forward drift
            width: Math.max(0, fillBar.width * Math.min(1.0, sliderRoot.peak))
            visible: sliderRoot.showPeak && !sliderRoot.isMuted && width > 1
            clip: true

            // Slit window exposing strictly the bottom 2px
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                clip: true

                // Full 14px capsule matching the slider's exact pill geometry
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 14
                    radius: 7
                    color: "transparent"
                    border.width: 2
                    border.color: sliderRoot.peak > 0.88 ? Theme.urgent : (sliderRoot.peak > 0.65 ? Theme.warning : Theme.fg)

                    Behavior on border.color { ColorAnimation { duration: 80 } }
                }
            }
        }

        // =====================================================================
        // Layer 4: 100% Benchmark marker notch (When overdrive is enabled)
        // =====================================================================
        Rectangle {
            visible: sliderRoot.to > 1.0
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(parent.width * (1.0 / sliderRoot.to)) - 1
            width: 2
            height: 7
            radius: 1
            color: Theme.fgSoft
            opacity: 0.85
        }
    }

    MouseArea {
        id: sliderMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateFromX(mouseX) {
            var ratio = Math.max(0.0, Math.min(1.0, mouseX / trackBg.width));
            var newVal = sliderRoot.from + ratio * (sliderRoot.to - sliderRoot.from);
            sliderRoot.moved(newVal);
        }

        onPressed: (mouse) => updateFromX(mouse.x)
        onPositionChanged: (mouse) => {
            if (pressed) updateFromX(mouse.x)
        }

        onWheel: (wheel) => {
            var step = 0.02 * (sliderRoot.to - sliderRoot.from);
            var nextVal = sliderRoot.value;
            if (wheel.angleDelta.y > 0) {
                nextVal = Math.min(sliderRoot.to, sliderRoot.value + step);
            } else if (wheel.angleDelta.y < 0) {
                nextVal = Math.max(sliderRoot.from, sliderRoot.value - step);
            }
            sliderRoot.moved(nextVal);
        }
    }
}
