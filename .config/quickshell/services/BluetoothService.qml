pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: bluetoothService

    property bool isPowered: true
    property int connectedCount: 0
    property string activeDeviceName: "No Device Connected"
    property var devices: [
        { name: "Sony WH-1000XM5", mac: "CC:98:8B:12:34:56", connected: true, type: "audio" },
        { name: "HHKB Studio", mac: "E4:5F:01:78:9A:BC", connected: false, type: "keyboard" }
    ]

    // Background process to check bluetooth status via bluetoothctl
    property var btStatusProc: Process {
        id: btStatusProcess
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep 'Powered:'"]
        stdout: StdioCollector {
            onDataChanged: {
                var raw = (data || "").toString().trim();
                if (raw.indexOf("yes") !== -1) {
                    bluetoothService.isPowered = true;
                } else if (raw.indexOf("no") !== -1) {
                    bluetoothService.isPowered = false;
                }
            }
        }
    }

    property var btCheckTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!btStatusProcess.running) {
                btStatusProcess.running = true;
            }
        }
    }

    function togglePower() {
        isPowered = !isPowered;
        Quickshell.execDetached(["bluetoothctl", "power", isPowered ? "on" : "off"]);
    }

    function connectDevice(mac) {
        Quickshell.execDetached(["bluetoothctl", "connect", mac]);
    }

    function disconnectDevice(mac) {
        Quickshell.execDetached(["bluetoothctl", "disconnect", mac]);
    }
}
