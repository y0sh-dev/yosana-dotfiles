#!/usr/bin/env python3
"""bt_manager.py - dependency-free Bluetooth bridge for Quickshell.

Wraps `bluetoothctl` non-interactively and emits single-line JSON so the QML
layer never has to parse ANSI, interactive prompts, or localized output.

Commands
--------
  status                 -> {"powered", "discovering", "controllerName",
                             "controllerMac", "devices": [...]}
  scan [seconds]         -> {"powered", "devices": [...]}  (timed discovery)
  power on|off
  connect <mac>
  disconnect <mac>
  pair <mac>
  trust <mac>
  adopt <mac>            -> pair + trust + connect (seamless onboarding)
  remove <mac>

Each device object:
  { mac, name, connected, paired, trusted, type, icon, rssi, battery }
"""

from __future__ import annotations

import json
import re
import subprocess
import sys

MAC_RE = re.compile(r"[0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5}")


def run(args, timeout=8.0):
    """Run a command and return combined stdout+stderr (never raises)."""
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return (p.stdout or "") + (p.stderr or "")
    except Exception:
        return ""


def parse_kv(text, key):
    m = re.search(rf"{re.escape(key)}:\s*(.+)", text)
    return m.group(1).strip() if m else None


def show():
    out = run(["bluetoothctl", "show"], timeout=5)
    mac = ""
    m = re.search(r"Controller\s+([0-9A-Fa-f:]{17})", out)
    if m:
        mac = m.group(1)
    # Prefer the human alias/name; the Controller line often only carries the
    # address type (e.g. "(public)") rather than the adapter's friendly name.
    name = parse_kv(out, "Alias") or parse_kv(out, "Name") or ""
    return {
        "powered": bool(re.search(r"Powered:\s*yes", out)),
        "discoverable": bool(re.search(r"Discoverable:\s*yes", out)),
        "discovering": bool(re.search(r"Discovering:\s*yes", out)),
        "controllerName": name,
        "controllerMac": mac,
    }


def list_devices(section=None):
    args = ["bluetoothctl", "devices"]
    if section:
        args.append(section)
    out = run(args, timeout=5)
    devs = []
    for line in out.splitlines():
        m = re.match(r"Device\s+([0-9A-Fa-f:]{17})\s+(.+)", line.strip())
        if m:
            devs.append((m.group(1), m.group(2).strip()))
    return devs


def type_of(icon):
    icon = (icon or "").lower()
    if any(k in icon for k in ("audio", "headset", "headphone")):
        return "audio"
    if "keyboard" in icon:
        return "keyboard"
    if "mouse" in icon or "pointer" in icon:
        return "mouse"
    if any(k in icon for k in ("game", "joystick")):
        return "gamepad"
    if "phone" in icon:
        return "phone"
    return "generic"


def info(mac):
    out = run(["bluetoothctl", "info", mac], timeout=4)
    rssi = None
    m = re.search(r"RSSI:\s*(-?\d+)", out)
    if m:
        rssi = int(m.group(1))
    battery = None
    m = re.search(r"Battery Percentage:\s*0x[0-9a-fA-F]+\s*\((\d+)\)", out)
    if not m:
        m = re.search(r"Battery Percentage:\s*(\d+)", out)
    if m:
        battery = int(m.group(1))
    icon = parse_kv(out, "Icon") or ""
    return {
        "connected": bool(re.search(r"Connected:\s*yes", out)),
        "paired": bool(re.search(r"Paired:\s*yes", out)),
        "trusted": bool(re.search(r"Trusted:\s*yes", out)),
        "type": type_of(icon),
        "icon": icon,
        "rssi": rssi,
        "battery": battery,
    }


def device_obj(mac, name=""):
    obj = {
        "mac": mac,
        "name": name or mac,
        "connected": False,
        "paired": False,
        "trusted": False,
        "type": "generic",
        "icon": "",
        "rssi": None,
        "battery": None,
    }
    obj.update(info(mac))
    if name:
        obj["name"] = name
    return obj


def status_payload():
    s = show()
    paired = list_devices("Paired")
    connected = list_devices("Connected")
    seen = set()
    devices = []
    for mac, name in paired + connected:
        if mac in seen:
            continue
        seen.add(mac)
        devices.append(device_obj(mac, name))
    devices.sort(key=lambda d: (not d["connected"], not d["paired"], d["name"].lower()))
    return {
        "powered": s["powered"],
        "discoverable": s["discoverable"],
        "discovering": s["discovering"],
        "controllerName": s["controllerName"],
        "controllerMac": s["controllerMac"],
        "devices": devices,
    }


def scan_payload(seconds=7):
    s = show()
    if not s["powered"]:
        return {"powered": False, "devices": []}

    # Preferred: bluetoothctl's own timed scan. Fallback: coreutils timeout.
    run(["bluetoothctl", "--timeout", str(seconds), "scan", "on"], timeout=seconds + 8)
    all_devs = list_devices()
    if not all_devs:
        run(["timeout", str(seconds), "bluetoothctl", "scan", "on"], timeout=seconds + 6)
        all_devs = list_devices()

    out = []
    for mac, name in all_devs:
        out.append(device_obj(mac, name))
    out.sort(key=lambda d: (not d["connected"], not d["paired"], -(d["rssi"] or -999)))
    return {"powered": True, "devices": out}


def main():
    argv = sys.argv[1:]
    if not argv:
        print(json.dumps({"error": "no command"}))
        return

    cmd = argv[0]
    if cmd == "status":
        print(json.dumps(status_payload()))
    elif cmd == "scan":
        sec = int(argv[1]) if len(argv) > 1 and argv[1].isdigit() else 7
        print(json.dumps(scan_payload(sec)))
    elif cmd == "power" and len(argv) > 1:
        run(["bluetoothctl", "power", argv[1]])
        print(json.dumps({"ok": True}))
    elif cmd in ("connect", "disconnect", "pair", "trust", "remove") and len(argv) > 1:
        run(["bluetoothctl", cmd, argv[1]], timeout=14)
        if cmd == "pair":
            run(["bluetoothctl", "trust", argv[1]], timeout=6)
        print(json.dumps({"ok": True}))
    elif cmd == "adopt" and len(argv) > 1:
        mac = argv[1]
        run(["bluetoothctl", "pair", mac], timeout=22)
        run(["bluetoothctl", "trust", mac], timeout=6)
        run(["bluetoothctl", "connect", mac], timeout=14)
        print(json.dumps({"ok": True}))
    else:
        print(json.dumps({"error": "unknown command"}))


if __name__ == "__main__":
    main()
