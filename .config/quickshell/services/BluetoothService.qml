pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Bluetooth state bridge. Polling is gated by `active` (set by the panel while
// it is open) so the shell stays at zero idle wakeups when the deck is closed.
QtObject {
    id: bluetoothService

    readonly property string script: "/home/yukkkk1/.config/quickshell/scripts/bt_manager.py"

    property bool active: false

    property bool isPowered: false
    property bool isDiscovering: false
    property bool isScanning: false
    property string controllerName: ""
    property string controllerMac: ""
    property var devices: []       // paired peripherals
    property var discovered: []    // last scan result (paired + discovered)

    // Type glyph mapping (Nerd Font)
    function glyphFor(type) {
        switch (type) {
        case "audio":    return "󰋋";
        case "keyboard": return "󰌌";
        case "mouse":    return "󰍽";
        case "gamepad":  return "󰄡";
        case "phone":    return "󰏲";
        default:         return "󰂯";
        }
    }

    readonly property var connectedDevices: devices.filter(function(d) { return d.connected; })
    readonly property int connectedCount: connectedDevices.length
    readonly property var activeDevice: connectedCount > 0 ? connectedDevices[0] : null

    // Unpaired beacons only (paired devices live in the "Paired" deck).
    readonly property var newBeacons: discovered.filter(function(d) { return !d.paired; })

    // ── Processes ───────────────────────────────────────────────────
    property var statusProc: Process {
        id: statusProcess
        command: ["python3", bluetoothService.script, "status"]
        stdout: StdioCollector {
            onDataChanged: bluetoothService.applyStatus((data || "").toString())
        }
    }

    property var scanProc: Process {
        id: scanProcess
        command: ["python3", bluetoothService.script, "scan", "7"]
        stdout: StdioCollector {
            onDataChanged: bluetoothService.applyScan((data || "").toString())
        }
        onExited: {
            bluetoothService.isScanning = false;
            bluetoothService.refresh();
        }
    }

    // Generic action runner (command swapped per action).
    property var actionProc: Process {
        id: actionProcess
        onExited: bluetoothService.refresh()
    }

    property var pollTimer: Timer {
        interval: 6000
        repeat: true
        running: bluetoothService.active
        onTriggered: bluetoothService.refresh()
    }

    property var powerRefreshTimer: Timer {
        interval: 1500
        repeat: false
        onTriggered: bluetoothService.refresh()
    }

    // ── Parsers ─────────────────────────────────────────────────────
    function applyStatus(raw) {
        var t = (raw || "").trim();
        if (!t) return;
        try {
            var o = JSON.parse(t);
            bluetoothService.isPowered = !!o.powered;
            bluetoothService.isDiscovering = !!o.discovering;
            bluetoothService.controllerName = o.controllerName || "";
            bluetoothService.controllerMac = o.controllerMac || "";
            bluetoothService.devices = o.devices || [];

            // Reconcile stale discovery entries: once a beacon is paired it
            // should leave the "new beacons" deck immediately.
            var pairedMacs = {};
            for (var i = 0; i < bluetoothService.devices.length; i++) {
                pairedMacs[bluetoothService.devices[i].mac] = true;
            }
            if (bluetoothService.discovered.length > 0) {
                var upd = [];
                for (var j = 0; j < bluetoothService.discovered.length; j++) {
                    var src = bluetoothService.discovered[j];
                    var dst = {};
                    for (var k in src) dst[k] = src[k];
                    if (pairedMacs[dst.mac]) dst.paired = true;
                    upd.push(dst);
                }
                bluetoothService.discovered = upd;
            }
        } catch (e) {}
    }

    function applyScan(raw) {
        var t = (raw || "").trim();
        if (!t) return;
        try {
            var o = JSON.parse(t);
            if (o.powered !== undefined) bluetoothService.isPowered = !!o.powered;
            bluetoothService.discovered = o.devices || [];
        } catch (e) {}
    }

    // ── Control surface ─────────────────────────────────────────────
    function refresh() {
        if (bluetoothService.active && !statusProcess.running && !scanProcess.running) {
            statusProcess.running = true;
        }
    }

    function scan() {
        if (!bluetoothService.isPowered || scanProcess.running) return;
        bluetoothService.isScanning = true;
        scanProcess.running = true;
    }

    function runAction(args) {
        if (actionProcess.running) return;
        actionProcess.command = ["python3", bluetoothService.script].concat(args);
        actionProcess.running = true;
    }

    function togglePower() {
        var target = !bluetoothService.isPowered;
        bluetoothService.isPowered = target; // optimistic, corrected by refresh
        runAction(["power", target ? "on" : "off"]);
        powerRefreshTimer.restart();
    }

    function connectDevice(mac)    { runAction(["connect", mac]); }
    function disconnectDevice(mac) { runAction(["disconnect", mac]); }
    function pairDevice(mac)       { runAction(["pair", mac]); }
    function trustDevice(mac)      { runAction(["trust", mac]); }
    function adoptDevice(mac)      { runAction(["adopt", mac]); }
    function removeDevice(mac)     { runAction(["remove", mac]); }

    onActiveChanged: {
        if (active) refresh();
    }

    Component.onCompleted: {
        if (active) refresh();
    }
}
