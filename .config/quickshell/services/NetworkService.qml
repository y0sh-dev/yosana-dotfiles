pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: networkService

    property bool isWired: false
    property bool isConnected: false
    property string ssid: ""
    property int rssi: -100
    property string ip: "192.168.1.50"
    property string iface: "wlan0"
    property string band: "5GHz (Wi-Fi 6E)"
    property string freq: "5.745 GHz · Ch 149"
    property string phyRate: "2.4 Gbps"
    property string txRate: "24 KB/s"
    property string rxRate: "1.8 MB/s"
    property string rtt: "1.8 ms"
    property bool tailscaleActive: true
    property string tailscaleIp: "100.84.12.3"
    property string dnsStatus: "DoT (853) · RPZ Shielded"
    property string cakeStatus: "Laminar · 0 drops"

    // Dynamic icon based on signal strength
    readonly property string icon: {
        if (isWired) return "󰈀";
        if (!isConnected) return "󰤭";
        if (rssi >= -55) return "󰤨";
        if (rssi >= -65) return "󰤥";
        if (rssi >= -75) return "󰤢";
        if (rssi >= -85) return "󰤟";
        return "󰤯";
    }

    // Scanned Wi-Fi networks model
    property var scanResults: [
        { ssid: "Home_5G", signal: -42, band: "6GHz", security: "WPA3", connected: true },
        { ssid: "Toride_Node_Mesh", signal: -58, band: "5GHz", security: "WPA2", connected: false },
        { ssid: "Tokyo_Station_SubNet", signal: -72, band: "5GHz", security: "WPA2", connected: false },
        { ssid: "Free_Public_Ether", signal: -81, band: "2.4GHz", security: "Open", connected: false }
    ]
    property bool isScanning: false

    // Realtime stream subscriber process (net_monitor.py)
    property var netSubProc: Process {
        id: netSubProcess
        command: ["python3", "-u", "/home/yukkkk1/.config/quickshell/scripts/net_monitor.py"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var raw = (line || "").toString().trim();
                if (!raw) return;
                try {
                    var obj = JSON.parse(raw);
                    if (obj.wired !== undefined) networkService.isWired = obj.wired;
                    if (obj.connected !== undefined) networkService.isConnected = obj.connected;
                    if (obj.ssid !== undefined) networkService.ssid = obj.ssid;
                    if (obj.rssi !== undefined) networkService.rssi = obj.rssi;
                    if (obj.ip !== undefined) networkService.ip = obj.ip;
                    if (obj.iface !== undefined) networkService.iface = obj.iface;
                    if (obj.band !== undefined) networkService.band = obj.band;
                    if (obj.txRate !== undefined) networkService.txRate = obj.txRate;
                    if (obj.rxRate !== undefined) networkService.rxRate = obj.rxRate;
                    if (obj.rtt !== undefined) networkService.rtt = obj.rtt;
                    if (obj.tailscaleActive !== undefined) networkService.tailscaleActive = obj.tailscaleActive;
                    if (obj.tailscaleIp !== undefined) networkService.tailscaleIp = obj.tailscaleIp;
                } catch(e) {
                    // Ignore non-json frames
                }
            }
        }

        onExited: function(exitCode, exitStatus) {
            reconnectTimer.restart();
        }
    }

    property var reconnectTimer: Timer {
        interval: 3000
        repeat: false
        onTriggered: {
            if (!netSubProcess.running) {
                netSubProcess.running = true;
            }
        }
    }

    // Wi-Fi Scan Process
    property var scanProc: Process {
        id: scanProcess
        command: ["python3", "/home/yukkkk1/.config/quickshell/scripts/wifi_scan.py"]
        stdout: StdioCollector {
            onDataChanged: {
                var raw = (data || "").toString().trim();
                if (raw) {
                    try {
                        var parsed = JSON.parse(raw);
                        if (Array.isArray(parsed) && parsed.length > 0) {
                            networkService.scanResults = parsed;
                        }
                    } catch(e) {}
                }
            }
        }
        onExited: function(exitCode, exitStatus) {
            networkService.isScanning = false;
        }
    }

    property var rescanTimer: Timer {
        interval: 2000
        repeat: false
        onTriggered: {
            networkService.scan();
        }
    }

    function scan() {
        if (!scanProcess.running) {
            isScanning = true;
            scanProcess.running = true;
        }
    }

    function toggleTailscale() {
        tailscaleActive = !tailscaleActive;
        Quickshell.execDetached(["tailscale", tailscaleActive ? "up" : "down"]);
    }

    function connectNetwork(targetSsid) {
        Quickshell.execDetached(["iwctl", "station", iface, "connect", targetSsid]);
        rescanTimer.restart();
    }

    function disconnectNetwork() {
        Quickshell.execDetached(["iwctl", "station", iface, "disconnect"]);
        rescanTimer.restart();
    }
}
