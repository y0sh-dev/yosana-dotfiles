import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../services"

ColumnLayout {
    id: masterViewRoot

    property var defaultSink: null
    property var defaultSource: null
    property bool overdriveUnlocked: false

    signal selectOutputRequested()
    signal selectInputRequested()
    signal appStreamsRequested()
    signal toggleOverdrive()

    spacing: 14

    readonly property real outVolume: defaultSink && defaultSink.audio ? defaultSink.audio.volume : 0.0
    readonly property bool outMuted: defaultSink && defaultSink.audio ? defaultSink.audio.muted : false
    readonly property string outName: defaultSink ? (defaultSink.description || defaultSink.name || "Default Output") : "No Output Device"

    readonly property real inVolume: defaultSource && defaultSource.audio ? defaultSource.audio.volume : 0.0
    readonly property bool inMuted: defaultSource && defaultSource.audio ? defaultSource.audio.muted : false
    readonly property string inName: defaultSource ? (defaultSource.description || defaultSource.name || "Default Input") : "No Input Device"

    // Real-time microphone peak level monitor (active only when panel is visible)
    PwNodePeakMonitor {
        id: micPeakMonitor
        node: masterViewRoot.defaultSource
        enabled: masterViewRoot.visible && (masterViewRoot.defaultSource != null)
    }

    // Strict filter for audio playback streams (filters out microphone capture streams)
    function isPlaybackStream(n) {
        if (!n || !n.isStream || !n.audio) return false;
        var tStr = PwNodeType.toString(n.type);
        if (tStr.indexOf("InStream") !== -1 || tStr.indexOf("Source") !== -1) return false;
        var props = n.properties || {};
        if (props["media.class"] === "Stream/Input/Audio") return false;
        return true;
    }

    // Active unique application count: deduplicates multi-stream apps (Discord WebRTC, multi-tab browsers)
    readonly property int activeStreamsCount: {
        var rawList = Pipewire.nodes.values.filter(masterViewRoot.isPlaybackStream);
        var appMap = {};
        var count = 0;
        for (var i = 0; i < rawList.length; i++) {
            var node = rawList[i];
            var props = node.properties || {};
            var appKey = props["application.name"] || props["application.process.binary"] || node.description || node.name || ("app_" + node.id);
            if (!appMap[appKey]) {
                appMap[appKey] = true;
                count++;
            }
        }
        return count;
    }

    // =========================================================================
    // Header Bar: Title + Quick Action Badges (Apps, Equalizer)
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            spacing: 8
            Text {
                text: "󰓃"
                color: Theme.accent
                font.pixelSize: 16
                font.family: Theme.fontFamily
            }
            Text {
                text: "AUDIO CONTROLLER"
                color: Theme.fgSoft
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1.2
                font.family: Theme.fontFamily
            }
        }

        Item { Layout.fillWidth: true }

        // Application Streams Quick Action Pill (with active count badge)
        Rectangle {
            implicitHeight: 30
            implicitWidth: appBtnLayout.implicitWidth + 18
            radius: 15
            color: appBtnMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            border.color: appBtnMouse.containsMouse ? Theme.accent : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                id: appBtnLayout
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰘳"
                    color: masterViewRoot.activeStreamsCount > 0 ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Apps (" + masterViewRoot.activeStreamsCount + ")"
                    color: appBtnMouse.containsMouse ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.fontFamily
                }
            }

            MouseArea {
                id: appBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: masterViewRoot.appStreamsRequested()
            }
        }

        // EasyEffects Equalizer Pill
        Rectangle {
            implicitHeight: 30
            implicitWidth: eqLayout.implicitWidth + 18
            radius: 15
            color: eqMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            border.color: eqMouse.containsMouse ? Theme.accent : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                id: eqLayout
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰓃"
                    color: eqMouse.containsMouse ? Theme.accent : Theme.fgSoft
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Equalizer"
                    color: eqMouse.containsMouse ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.fontFamily
                }
            }

            MouseArea {
                id: eqMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["easyeffects"]);
                }
            }
        }
    }

    // =========================================================================
    // 1. Output Control Card (Master Volume & Sink Selector)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: outCardLayout.implicitHeight + 28
        radius: 12
        color: Theme.surface
        border.color: masterViewRoot.overdriveUnlocked ? Theme.warning : Theme.border
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        ColumnLayout {
            id: outCardLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Card Header: Category + Device Pill Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: masterViewRoot.overdriveUnlocked ? Theme.warning : (outMuted ? Theme.urgent : Theme.accent)
                    }
                    Text {
                        text: "OUTPUT"
                        color: Theme.subtextDim
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.1
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }

                // Modern Sink Selector Pill Button: [*1: AT-UMX3 ›]
                Rectangle {
                    implicitHeight: 32
                    implicitWidth: devPillLayout.implicitWidth + 20
                    radius: 16
                    color: devPillMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.45)
                    border.color: devPillMouse.containsMouse ? Theme.accent : Theme.border
                    border.width: 1

                    scale: devPillMouse.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: devPillLayout
                        anchors.centerIn: parent
                        spacing: 7

                        Text {
                            text: "󰋋"
                            color: devPillMouse.containsMouse ? Theme.accent : Theme.fgSoft
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: outName
                            color: devPillMouse.containsMouse ? Theme.fg : Theme.fgSoft
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.maximumWidth: 240
                        }

                        Text {
                            text: "›"
                            color: devPillMouse.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: devPillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: masterViewRoot.selectOutputRequested()
                    }
                }
            }

            // Row: [Vol Icon (R-Click: Mute, Dbl-Click: Burst)] [Vol %]
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Muteable & Burst-Unlockable Volume Icon Pill
                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 32
                    radius: 8
                    color: outMuted ? Theme.urgent : (volIconMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.35))
                    border.color: volIconMouse.containsMouse ? Theme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: outMuted ? "󰖁" : (masterViewRoot.overdriveUnlocked ? "󰕾⚡" : "󰕾")
                        color: outMuted ? Theme.bgDark : (masterViewRoot.overdriveUnlocked ? Theme.warning : (volIconMouse.containsMouse ? Theme.accent : Theme.fg))
                        font.pixelSize: 18
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: volIconMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        // Right click: Instant Mute
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                if (defaultSink && defaultSink.audio) {
                                    defaultSink.audio.muted = !defaultSink.audio.muted;
                                }
                            }
                        }

                        // Double click: Toggle Overdrive (Burst 200%) Max Unlock
                        onDoubleClicked: {
                            masterViewRoot.toggleOverdrive();
                        }
                    }
                }

                // Volume Percentage (Legible 18px Bold)
                Text {
                    text: Math.round(outVolume * 100) + "%"
                    color: outVolume > 1.0 ? Theme.warning : (outMuted ? Theme.urgent : Theme.fg)
                    font.pixelSize: 18
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: masterViewRoot.overdriveUnlocked
                    text: "OVERDRIVE 200%"
                    color: Theme.warning
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.8
                    font.family: Theme.fontFamily
                }
            }

            // Modern 14px Capsule Slider
            ModernSlider {
                Layout.fillWidth: true
                from: 0.0
                to: masterViewRoot.overdriveUnlocked ? 2.0 : 1.0
                value: outVolume
                isMuted: outMuted

                onMoved: (val) => {
                    if (defaultSink && defaultSink.audio) {
                        defaultSink.audio.volume = val;
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. Input Control Card (Microphone Volume & Source Selector)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inCardLayout.implicitHeight + 28
        radius: 12
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            id: inCardLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Card Header: Category + Device Pill Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: inMuted ? Theme.urgent : (micPeakMonitor.peak > 0.04 ? (micPeakMonitor.peak > 0.88 ? Theme.urgent : (micPeakMonitor.peak > 0.68 ? Theme.warning : Theme.accent)) : Theme.subtextDim)
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                    Text {
                        text: "INPUT"
                        color: Theme.subtextDim
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.1
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }

                // Modern Source Selector Pill Button: [*2: AT-UMX3 ›]
                Rectangle {
                    implicitHeight: 32
                    implicitWidth: micPillLayout.implicitWidth + 20
                    radius: 16
                    color: micPillMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.45)
                    border.color: micPillMouse.containsMouse ? Theme.accent : Theme.border
                    border.width: 1

                    scale: micPillMouse.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: micPillLayout
                        anchors.centerIn: parent
                        spacing: 7

                        Text {
                            text: "󰍬"
                            color: micPillMouse.containsMouse ? Theme.accent : Theme.fgSoft
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: inName
                            color: micPillMouse.containsMouse ? Theme.fg : Theme.fgSoft
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.maximumWidth: 240
                        }

                        Text {
                            text: "›"
                            color: micPillMouse.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: micPillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: masterViewRoot.selectInputRequested()
                    }
                }
            }

            // Row: [Mic Icon (R-Click: Mute)] [Mic %]
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Muteable Mic Icon Pill
                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 32
                    radius: 8
                    color: inMuted ? Theme.urgent : (micIconMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.35))
                    border.color: micIconMouse.containsMouse ? Theme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: inMuted ? "󰍭" : "󰍬"
                        color: inMuted ? Theme.bgDark : (micIconMouse.containsMouse ? Theme.accent : Theme.fg)
                        font.pixelSize: 18
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: micIconMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        // Right click: Instant Mic Mute
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                if (defaultSource && defaultSource.audio) {
                                    defaultSource.audio.muted = !defaultSource.audio.muted;
                                }
                            }
                        }
                    }
                }

                // Mic Percentage (Legible 18px Bold)
                Text {
                    text: Math.round(inVolume * 100) + "%"
                    color: inMuted ? Theme.urgent : Theme.fg
                    font.pixelSize: 18
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                // Dynamic Input VU Active Badge (Harmonized Pywal palette)
                Text {
                    visible: !inMuted && micPeakMonitor.peak > 0.04
                    text: "● LIVE"
                    color: micPeakMonitor.peak > 0.88 ? Theme.urgent : (micPeakMonitor.peak > 0.68 ? Theme.warning : Theme.accent)
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.8
                    font.family: Theme.fontFamily
                    opacity: 0.85
                }

                Item { Layout.fillWidth: true }
            }

            // Modern 14px Capsule Slider with Real-time Peak Level Meter
            ModernSlider {
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: inVolume
                isMuted: inMuted
                showPeak: true
                peak: inMuted ? 0.0 : micPeakMonitor.peak

                onMoved: (val) => {
                    if (defaultSource && defaultSource.audio) {
                        defaultSource.audio.volume = val;
                    }
                }
            }
        }
    }

    // =========================================================================
    // Footer: Status & PipeWire Telemetry (Effortless 12px legibility)
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: masterViewRoot.overdriveUnlocked 
                  ? "⚡ OVERDRIVE ACTIVE (200% MAX) • DBL-CLICK ICON TO LOCK"
                  : "󰓅 PipeWire 48kHz / 512 (~10.6ms) • Wannamaker-3"
            color: masterViewRoot.overdriveUnlocked ? Theme.warning : Theme.subtextDim
            font.pixelSize: 12
            font.bold: masterViewRoot.overdriveUnlocked
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }
    }
}
