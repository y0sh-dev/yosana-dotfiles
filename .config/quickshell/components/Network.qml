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

    // Periodically fetch connection & RSSI info via iwd
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchNetInfo()
    }

    Process {
        id: netProc
        command: ["bash", "-c", "cat /sys/class/net/en*/operstate 2>/dev/null | grep -q 'up' && echo 'WIRED' || iwctl station wlan0 show | awk '/Connected network/ {print $3} /^[[:space:]]+RSSI/ {print $2}'"]

        stdout: StdioCollector {
            onDataChanged: {
                var rawStr = (data || "").toString().trim();
                if (rawStr.length === 0) return;
                var lines = rawStr.split("\n");
                if (lines[0] === "WIRED") {
                    networkRoot.isWired = true;
                    networkRoot.isConnected = true;
                    networkRoot.ssid = "Ethernet";
                } else if (lines.length >= 2 && lines[0].length > 0) {
                    networkRoot.isWired = false;
                    networkRoot.ssid = lines[0].trim();
                    networkRoot.rssi = parseInt(lines[1]) || -70;
                } else {
                    networkRoot.isWired = false;
                    networkRoot.ssid = "";
                    networkRoot.rssi = -100;
                }
            }
        }
    }

    function fetchNetInfo() {
        if (!netProc.running) {
            netProc.running = true;
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
            Behavior on color { ColorAnimation { duration: 150 } }
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
