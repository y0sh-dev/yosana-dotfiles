import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: networkRoot
    implicitHeight: Theme.islandHeight
    implicitWidth: 32

    signal clicked()

    property bool isWired: false
    property bool isConnected: ssid.length > 0
    property string ssid: ""
    property int rssi: -100

    // Dynamic network icon based on signal strength (Nerd Font: 16px)
    readonly property string icon: {
        if (isWired) return "󰈀";
        if (!isConnected) return "󰤭";
        if (rssi >= -55) return "󰤨";
        if (rssi >= -65) return "󰤥";
        if (rssi >= -75) return "󰤢";
        if (rssi >= -85) return "󰤟";
        return "󰤯";
    }

    // Zero-polling event-driven Network stream subscriber (0% idle CPU)
    Process {
        id: netSubProc
        command: ["python3", "-u", "/home/yukkkk1/.config/quickshell/scripts/net_monitor.py"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var raw = (line || "").toString().trim();
                if (!raw) return;
                try {
                    var obj = JSON.parse(raw);
                    if (obj.wired !== undefined) networkRoot.isWired = obj.wired;
                    if (obj.connected !== undefined) networkRoot.isConnected = obj.connected;
                    if (obj.ssid !== undefined) networkRoot.ssid = obj.ssid;
                    if (obj.rssi !== undefined) networkRoot.rssi = obj.rssi;
                } catch(e) {
                    // Ignore non-json frames
                }
            }
        }

        // Auto-reconnect if process exits
        onExited: function(exitCode, exitStatus) {
            reconnectTimer.restart();
        }
    }

    Timer {
        id: reconnectTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!netSubProc.running) {
                netSubProc.running = true;
            }
        }
    }

    Rectangle {
        id: bgPill
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 14
        color: netMouse.containsMouse ? Theme.surfaceHover : "transparent"
        border.color: netMouse.containsMouse ? Theme.border : "transparent"
        border.width: 1

        scale: netMouse.pressed ? 0.90 : (netMouse.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: networkRoot.icon
            font.pixelSize: 16 // Icon size: 16px
            font.family: Theme.fontFamily
            color: networkRoot.isConnected ? Theme.fg : Theme.urgent
            Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
        }
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: networkRoot.clicked()
    }
}
