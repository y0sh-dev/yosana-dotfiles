import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../services"
import "../../components"

ColumnLayout {
    id: effectsRoot

    signal backClicked()

    spacing: 14

    // Live state tracking
    property string activeOutputPreset: "My-EasyEQ_2+Black"
    property string activeInputPreset: "Voice_Clean"
    property bool isAudioSharingActive: false
    property bool isSidetoneActive: false
    property bool isBypassActive: false

    // Asynchronous state synchronization via EasyEffects CLI
    Process {
        id: refreshStatusProc
        command: ["sh", "-c", "QT_QPA_PLATFORM=offscreen easyeffects -s 2>/dev/null; echo \"sharing: $(QT_QPA_PLATFORM=offscreen easyeffects --audio-sharing 3 2>/dev/null)\"; echo \"sidetone: $(QT_QPA_PLATFORM=offscreen easyeffects --microphone-monitoring 3 2>/dev/null)\"; echo \"bypass: $(QT_QPA_PLATFORM=offscreen easyeffects -b 3 2>/dev/null)\""]
        stdout: StdioCollector {
            onDataChanged: {
                var lines = (data || "").toString().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i].trim();
                    if (l.startsWith("input:")) {
                        var inVal = l.replace("input:", "").trim();
                        if (inVal.length > 0) effectsRoot.activeInputPreset = inVal;
                    } else if (l.startsWith("output:")) {
                        var outVal = l.replace("output:", "").trim();
                        if (outVal.length > 0) effectsRoot.activeOutputPreset = outVal;
                    } else if (l.startsWith("sharing:")) {
                        effectsRoot.isAudioSharingActive = l.includes("1");
                    } else if (l.startsWith("sidetone:")) {
                        effectsRoot.isSidetoneActive = l.includes("1");
                    } else if (l.startsWith("bypass:")) {
                        effectsRoot.isBypassActive = l.includes("1");
                    }
                }
            }
        }
    }

    // Delayed verification sync after user toggle action
    property var syncTimer: Timer {
        interval: 250
        repeat: false
        onTriggered: {
            if (!refreshStatusProc.running) {
                refreshStatusProc.running = true;
            }
        }
    }

    onVisibleChanged: {
        if (visible && !refreshStatusProc.running) {
            refreshStatusProc.running = true;
        }
    }

    Component.onCompleted: {
        if (!refreshStatusProc.running) {
            refreshStatusProc.running = true;
        }
    }

    // Helper functions for actions
    function setOutputPreset(name) {
        activeOutputPreset = name;
        Quickshell.execDetached(["easyeffects", "-l", name]);
        syncTimer.restart();
    }

    function setInputPreset(name) {
        activeInputPreset = name;
        Quickshell.execDetached(["easyeffects", "-l", name]);
        syncTimer.restart();
    }

    function toggleAudioSharing() {
        isAudioSharingActive = !isAudioSharingActive;
        Quickshell.execDetached(["easyeffects", "--audio-sharing-toggle"]);
        syncTimer.restart();
    }

    function toggleSidetone() {
        isSidetoneActive = !isSidetoneActive;
        Quickshell.execDetached(["easyeffects", "--microphone-monitoring-toggle"]);
        syncTimer.restart();
    }

    function toggleBypass() {
        isBypassActive = !isBypassActive;
        Quickshell.execDetached(["easyeffects", "--bypass-toggle"]);
        syncTimer.restart();
    }

    // =========================================================================
    // Header: Back button + Title + Open App button
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // [‹ Back] Button
        Rectangle {
            implicitWidth: 84
            implicitHeight: 32
            radius: 8
            color: backMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            border.color: backMouse.containsMouse ? Theme.accent : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "‹"
                    color: backMouse.containsMouse ? Theme.accent : Theme.fg
                    font.pixelSize: 15
                    font.bold: true
                    font.family: Theme.fontFamily
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "Back"
                    color: backMouse.containsMouse ? Theme.accent : Theme.fgSoft
                    font.pixelSize: 13
                    font.bold: true
                    font.family: Theme.fontFamily
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: effectsRoot.backClicked()
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "DSP & EFFECTS"
            color: Theme.fg
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 1.2
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }

        // [Open App ↗] Button
        Rectangle {
            implicitWidth: openAppLayout.implicitWidth + 18
            implicitHeight: 32
            radius: 8
            color: openAppMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            border.color: openAppMouse.containsMouse ? Theme.accent : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                id: openAppLayout
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰓃"
                    color: openAppMouse.containsMouse ? Theme.accent : Theme.fgSoft
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Open App ↗"
                    color: openAppMouse.containsMouse ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.fontFamily
                }
            }

            MouseArea {
                id: openAppMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["easyeffects"])
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.border
        opacity: 0.4
    }

    // =========================================================================
    // Scrollable Content Area (Fixed Modal Height, Internal Flickable)
    // =========================================================================
    Flickable {
        id: flickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.rightMargin: -12
        contentWidth: width - 12
        contentHeight: effectsContentLayout.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ModernScrollBar {
            targetFlickable: flickable
        }

        ColumnLayout {
            id: effectsContentLayout
            width: flickable.contentWidth
            spacing: 14

            // =================================================================
            // Section 1: ROUTING & UTILITIES (Toggle Cards)
            // =================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: Theme.accent
        }

        Text {
            text: "ROUTING & UTILITIES"
            color: Theme.subtextDim
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1.1
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        // Card 1: Mic Clean (RNNoise)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: 10
            readonly property bool isActive: effectsRoot.activeInputPreset === "Voice_Clean"
            color: isActive ? Theme.surfaceHover : (c1Mouse.containsMouse ? Theme.surface : "transparent")
            border.color: isActive ? Theme.accent : (c1Mouse.containsMouse ? Theme.border : "transparent")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: "󰍬"
                    color: parent.parent.isActive ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Mic Clean (RNNoise)"
                    color: parent.parent.isActive ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 48
                    implicitHeight: 24
                    radius: 12
                    color: parent.parent.isActive ? Theme.accent : Qt.rgba(0, 0, 0, 0.45)
                    border.color: parent.parent.isActive ? Theme.accent : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: parent.parent.parent.isActive ? "ON" : "OFF"
                        color: parent.parent.parent.isActive ? Theme.bgDark : Theme.subtextDim
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: c1Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (effectsRoot.activeInputPreset === "Voice_Clean") {
                        effectsRoot.setInputPreset("Voice_Raw");
                    } else {
                        effectsRoot.setInputPreset("Voice_Clean");
                    }
                }
            }
        }

        // Card 2: Sidetone (Mic Monitoring)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: 10
            readonly property bool isActive: effectsRoot.isSidetoneActive
            color: isActive ? Theme.surfaceHover : (c2Mouse.containsMouse ? Theme.surface : "transparent")
            border.color: isActive ? Theme.accent : (c2Mouse.containsMouse ? Theme.border : "transparent")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: "󰋋"
                    color: parent.parent.isActive ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Sidetone (Mic Monitoring)"
                    color: parent.parent.isActive ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 48
                    implicitHeight: 24
                    radius: 12
                    color: parent.parent.isActive ? Theme.accent : Qt.rgba(0, 0, 0, 0.45)
                    border.color: parent.parent.isActive ? Theme.accent : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: parent.parent.parent.isActive ? "ON" : "OFF"
                        color: parent.parent.parent.isActive ? Theme.bgDark : Theme.subtextDim
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: c2Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: effectsRoot.toggleSidetone()
            }
        }

        // Card 3: Audio Sharing (Desktop to Mic)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: 10
            readonly property bool isActive: effectsRoot.isAudioSharingActive
            color: isActive ? Qt.tint(Theme.surface, Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)) : (c3Mouse.containsMouse ? Theme.surface : "transparent")
            border.color: isActive ? Theme.warning : (c3Mouse.containsMouse ? Theme.border : "transparent")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: "󰘳"
                    color: parent.parent.isActive ? Theme.warning : Theme.subtextDim
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Audio Sharing (Desktop to Mic)"
                    color: parent.parent.isActive ? Theme.warning : Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 48
                    implicitHeight: 24
                    radius: 12
                    color: parent.parent.isActive ? Theme.warning : Qt.rgba(0, 0, 0, 0.45)
                    border.color: parent.parent.isActive ? Theme.warning : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: parent.parent.parent.isActive ? "ON" : "OFF"
                        color: parent.parent.parent.isActive ? Theme.bgDark : Theme.subtextDim
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: c3Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: effectsRoot.toggleAudioSharing()
            }
        }

        // Card 4: Master DSP Bypass
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: 10
            readonly property bool isActive: effectsRoot.isBypassActive
            color: isActive ? Qt.tint(Theme.surface, Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.15)) : (c4Mouse.containsMouse ? Theme.surface : "transparent")
            border.color: isActive ? Theme.urgent : (c4Mouse.containsMouse ? Theme.border : "transparent")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: "󰓃"
                    color: parent.parent.isActive ? Theme.urgent : Theme.subtextDim
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Master DSP Bypass"
                    color: parent.parent.isActive ? Theme.urgent : Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: true
                    font.family: Theme.fontFamily
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 48
                    implicitHeight: 24
                    radius: 12
                    color: parent.parent.isActive ? Theme.urgent : Qt.rgba(0, 0, 0, 0.45)
                    border.color: parent.parent.isActive ? Theme.urgent : Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: parent.parent.parent.isActive ? "BYPASS" : "OFF"
                        color: parent.parent.parent.isActive ? Theme.bgDark : Theme.subtextDim
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: c4Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: effectsRoot.toggleBypass()
            }
        }
    }

    // =========================================================================
    // Section 2: INPUT PRESETS (MIC)
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: Theme.accent
        }

        Text {
            text: "INPUT PRESETS (MIC)"
            color: Theme.subtextDim
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1.1
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        // Voice Clean Preset
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: 10
            readonly property bool isSelected: effectsRoot.activeInputPreset === "Voice_Clean"
            color: isSelected ? Theme.surfaceHover : (inP1Mouse.containsMouse ? Theme.surface : "transparent")
            border.color: isSelected ? Theme.accent : (inP1Mouse.containsMouse ? Theme.border : "transparent")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: parent.parent.isSelected ? "󰄲" : "󰄱"
                    color: parent.parent.isSelected ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Voice Clean (80Hz Cut + RNNoise)"
                    color: parent.parent.isSelected ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: parent.parent.isSelected
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: parent.parent.isSelected
                    implicitWidth: inP1Text.implicitWidth + 16
                    implicitHeight: 24
                    radius: 12
                    color: Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25))
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        id: inP1Text
                        anchors.centerIn: parent
                        text: "ACTIVE"
                        color: Theme.accent
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: inP1Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: effectsRoot.setInputPreset("Voice_Clean")
            }
        }

        // Voice Raw Preset
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: 10
            readonly property bool isSelected: effectsRoot.activeInputPreset === "Voice_Raw"
            color: isSelected ? Theme.surfaceHover : (inP2Mouse.containsMouse ? Theme.surface : "transparent")
            border.color: isSelected ? Theme.accent : (inP2Mouse.containsMouse ? Theme.border : "transparent")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: parent.parent.isSelected ? "󰄲" : "󰄱"
                    color: parent.parent.isSelected ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Raw Studio (Direct Passthrough)"
                    color: parent.parent.isSelected ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: parent.parent.isSelected
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: parent.parent.isSelected
                    implicitWidth: inP2Text.implicitWidth + 16
                    implicitHeight: 24
                    radius: 12
                    color: Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25))
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        id: inP2Text
                        anchors.centerIn: parent
                        text: "ACTIVE"
                        color: Theme.accent
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: inP2Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: effectsRoot.setInputPreset("Voice_Raw")
            }
        }
    }

    // =========================================================================
    // Section 3: OUTPUT PRESETS (HEADPHONES)
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: Theme.accent
        }

        Text {
            text: "OUTPUT PRESETS (HEADPHONES)"
            color: Theme.subtextDim
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1.1
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        // Output Preset 1: My-EasyEQ_2+Black
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: 10
            readonly property bool isSelected: effectsRoot.activeOutputPreset === "My-EasyEQ_2+Black"
            color: isSelected ? Theme.surfaceHover : (outP1Mouse.containsMouse ? Theme.surface : "transparent")
            border.color: isSelected ? Theme.accent : (outP1Mouse.containsMouse ? Theme.border : "transparent")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: parent.parent.isSelected ? "󰄲" : "󰄱"
                    color: parent.parent.isSelected ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "My-EasyEQ_2+Black (Current Active)"
                    color: parent.parent.isSelected ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: parent.parent.isSelected
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: parent.parent.isSelected
                    implicitWidth: outP1Text.implicitWidth + 16
                    implicitHeight: 24
                    radius: 12
                    color: Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25))
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        id: outP1Text
                        anchors.centerIn: parent
                        text: "ACTIVE"
                        color: Theme.accent
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: outP1Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: effectsRoot.setOutputPreset("My-EasyEQ_2+Black")
            }
        }

        // Output Preset 2: Flat / Neutral
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: 10
            readonly property bool isSelected: effectsRoot.activeOutputPreset === "Flat"
            color: isSelected ? Theme.surfaceHover : (outP2Mouse.containsMouse ? Theme.surface : "transparent")
            border.color: isSelected ? Theme.accent : (outP2Mouse.containsMouse ? Theme.border : "transparent")
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: parent.parent.isSelected ? "󰄲" : "󰄱"
                    color: parent.parent.isSelected ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Flat / Neutral Reference"
                    color: parent.parent.isSelected ? Theme.fg : Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: parent.parent.isSelected
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: parent.parent.isSelected
                    implicitWidth: outP2Text.implicitWidth + 16
                    implicitHeight: 24
                    radius: 12
                    color: Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25))
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        id: outP2Text
                        anchors.centerIn: parent
                        text: "ACTIVE"
                        color: Theme.accent
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: outP2Mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: effectsRoot.setOutputPreset("Flat")
            }
        }
    }
        }
    }
}
