pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: networkService

    // ── Link identity ────────────────────────────────────────────────
    property bool isWired: false
    property bool isConnected: false
    property string ssid: ""
    property int rssi: -100
    property string ip: "192.168.1.50"
    property string iface: "wlan0"
    property string band: "5GHz (Wi-Fi 6E)"
    property string freq: "5.745 GHz · Ch 149"
    property string phyRate: "2.4 Gbps"

    // ── Throughput telemetry ────────────────────────────────────────
    property string txRate: "0 B/s"
    property string rxRate: "0 B/s"
    property real txBps: 0
    property real rxBps: 0
    property var rxHistory: []          // numeric history for the sparkline
    readonly property int historyDepth: 32

    property string rtt: "-- ms"

    // ── Secure mesh / resolver / shaping ────────────────────────────
    property bool tailscaleActive: false
    property string tailscaleIp: "—"
    property string dnsStatus: "DoT (853) · RPZ Shielded"
    property string cakeStatus: "Laminar · 0 drops"

    // ── Wi-Fi recon ─────────────────────────────────────────────────
    property var scanResults: []
    property bool isScanning: false
    property bool hasScanned: false

    // ── Derived ─────────────────────────────────────────────────────
    readonly property string icon: {
        if (isWired) return "󰈀";
        if (!isConnected) return "󰤭";
        if (rssi >= -55) return "󰤨";
        if (rssi >= -65) return "󰤥";
        if (rssi >= -75) return "󰤢";
        if (rssi >= -85) return "󰤟";
        return "󰤯";
    }

    // 0.0 (dead) .. 1.0 (excellent)
    readonly property real signalQuality: {
        if (!isConnected) return 0.0;
        if (rssi >= -50) return 1.0;
        if (rssi <= -90) return 0.0;
        return (rssi + 90) / 40.0;
    }

    readonly property string activeSecurity: {
        for (var i = 0; i < scanResults.length; i++) {
            if (scanResults[i].connected) return scanResults[i].security || "WPA2";
        }
        return "—";
    }

    // ── Realtime telemetry stream (event-driven, 1.5s cadence) ──────
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
                    if (obj.freq !== undefined) networkService.freq = obj.freq;
                    if (obj.phyRate !== undefined) networkService.phyRate = obj.phyRate;
                    if (obj.txRate !== undefined) networkService.txRate = obj.txRate;
                    if (obj.rxRate !== undefined) networkService.rxRate = obj.rxRate;
                    if (obj.rtt !== undefined) networkService.rtt = obj.rtt;
                    if (obj.tailscaleActive !== undefined) networkService.tailscaleActive = obj.tailscaleActive;
                    if (obj.tailscaleIp !== undefined) networkService.tailscaleIp = obj.tailscaleIp;

                    if (obj.rxBps !== undefined) {
                        networkService.rxBps = obj.rxBps;
                        var h = networkService.rxHistory.slice();
                        h.push(obj.rxBps);
                        while (h.length > networkService.historyDepth) h.shift();
                        networkService.rxHistory = h;
                    }
                    if (obj.txBps !== undefined) networkService.txBps = obj.txBps;
                } catch (e) {
                    // Ignore partial / non-JSON frames
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
            if (!netSubProcess.running) netSubProcess.running = true;
        }
    }

    // ── Wi-Fi scan ──────────────────────────────────────────────────
    property var scanProc: Process {
        id: scanProcess
        command: ["python3", "/home/yukkkk1/.config/quickshell/scripts/wifi_scan.py"]
        stdout: StdioCollector {
            onDataChanged: {
                var raw = (data || "").toString().trim();
                if (!raw) return;
                try {
                    var parsed = JSON.parse(raw);
                    if (Array.isArray(parsed)) {
                        networkService.scanResults = parsed;
                        networkService.hasScanned = true;
                    }
                } catch (e) {}
            }
        }
        onExited: function(exitCode, exitStatus) {
            networkService.isScanning = false;
        }
    }

    property var rescanTimer: Timer {
        interval: 2200
        repeat: false
        onTriggered: networkService.scan()
    }

    function scan() {
        if (!scanProc.running) {
            isScanning = true;
            scanProc.running = true;
        }
    }

    // ── Actions ─────────────────────────────────────────────────────
    // Known network: iwd resolves the stored PSK silently (fast handover).
    function connectNetwork(targetSsid) {
        Quickshell.execDetached(["iwctl", "station", iface, "connect", targetSsid]);
        rescanTimer.restart();
    }

    // Unknown secured network: passphrase handed to iwd via argv (no shell).
    function connectWithPassphrase(targetSsid, passphrase) {
        if (!targetSsid || !passphrase) return;
        Quickshell.execDetached(["iwctl", "station", iface, "connect", targetSsid, "--passphrase", passphrase]);
        rescanTimer.restart();
    }

    function disconnectNetwork() {
        Quickshell.execDetached(["iwctl", "station", iface, "disconnect"]);
        rescanTimer.restart();
    }

    function forgetNetwork(targetSsid) {
        if (!targetSsid) return;
        Quickshell.execDetached(["iwctl", "known-networks", targetSsid, "forget"]);
        rescanTimer.restart();
    }

    function toggleTailscale() {
        tailscaleActive = !tailscaleActive;
        Quickshell.execDetached(["tailscale", tailscaleActive ? "up" : "down"]);
    }

    Component.onCompleted: {
        var seed = [];
        for (var i = 0; i < historyDepth; i++) seed.push(0);
        rxHistory = seed;
    }
}
