#!/usr/bin/env python3
"""wifi_scan.py - Wi-Fi AP scanner with known-network detection.

Strategy:
  1. `iw dev <iface> scan` for ground-truth RSSI / frequency / BSSID per SSID.
  2. `iwctl station <iface> get-networks` for security class + association state.
  3. `iwctl known-networks list` to flag silent fast-handover candidates.

Emits a single JSON array. Every field is best-effort: a missing tool never
aborts the scan.
"""

import json
import re
import subprocess
import time

IFACE = "wlan0"
ANSI_RE = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")


def band_from_freq(mhz):
    if mhz >= 5955:
        return "6GHz"
    if mhz >= 5000:
        return "5GHz"
    if mhz >= 2400:
        return "2.4GHz"
    return "Unknown"


def get_current_ssid():
    try:
        res = subprocess.run(["iw", "dev", IFACE, "link"], capture_output=True,
                             text=True, timeout=1.5)
        m = re.search(r"SSID:\s*(.+)", res.stdout)
        if m:
            return m.group(1).strip()
    except Exception:
        pass
    return ""


def get_known_networks():
    known = set()
    try:
        res = subprocess.run(["iwctl", "known-networks", "list"], capture_output=True,
                             text=True, timeout=2.0)
        for line in res.stdout.splitlines():
            clean = ANSI_RE.sub("", line).strip()
            if "---" in clean or "Known Networks" in clean or not clean:
                continue
            parts = [p.strip() for p in re.split(r"\s{2,}", clean) if p.strip()]
            if parts:
                known.add(parts[0])
    except Exception:
        pass
    return known


def scan_via_iw():
    """Return {ssid: {bssid, signal, freq, band}} using the strongest BSS."""
    iw_map = {}
    try:
        subprocess.run(["iw", "dev", IFACE, "scan", "trigger"], capture_output=True, timeout=2.5)
        time.sleep(1.2)
        out = subprocess.run(["iw", "dev", IFACE, "scan"], capture_output=True,
                             text=True, timeout=5.0).stdout
        cur = None
        for raw in out.splitlines():
            line = raw.strip()
            m = re.match(r"BSS ([0-9a-fA-F:]{17})", line)
            if m:
                cur = {"bssid": m.group(1), "ssid": "", "signal": -100, "freq": 0}
                continue
            if cur is None:
                continue
            m = re.match(r"freq:\s*([0-9.]+)", line)
            if m:
                cur["freq"] = int(float(m.group(1)))
            m = re.match(r"signal:\s*(-?[0-9.]+)", line)
            if m:
                cur["signal"] = int(float(m.group(1)))
            m = re.match(r"SSID:\s*(.*)", line)
            if m:
                cur["ssid"] = m.group(1).strip()
                if cur["ssid"]:
                    prev = iw_map.get(cur["ssid"])
                    if prev is None or cur["signal"] > prev["signal"]:
                        cur["band"] = band_from_freq(cur["freq"])
                        iw_map[cur["ssid"]] = dict(cur)
    except Exception:
        pass
    return iw_map


def scan_via_iwctl(current_ssid, known_set, iw_map):
    try:
        subprocess.run(["iwctl", "station", IFACE, "scan"], capture_output=True, timeout=3.0)
        time.sleep(1.0)
    except Exception:
        pass

    networks = []
    try:
        res = subprocess.run(["iwctl", "station", IFACE, "get-networks"], capture_output=True,
                             text=True, timeout=3.0)
        start = False
        seen = set()

        for line in res.stdout.splitlines():
            clean = ANSI_RE.sub("", line).rstrip()
            if "---" in clean:
                start = True
                continue
            if not start or not clean.strip():
                continue

            is_connected = ">" in clean[:4]
            content = clean[4:].strip() if len(clean) > 4 else clean.strip()
            parts = [p.strip() for p in re.split(r"\s{2,}", content) if p.strip()]
            if len(parts) < 2:
                continue

            ssid = parts[0]
            if not ssid or ssid in seen:
                continue
            seen.add(ssid)

            sec = parts[1] if len(parts) >= 2 else "WPA2"
            stars = parts[2] if len(parts) >= 3 else "***"
            sig_dbm = -45 if "****" in stars else (-60 if "***" in stars else (-75 if "**" in stars else -85))
            sec_display = "WPA3" if ("8021x" in sec.lower() or "wpa3" in sec.lower()) else (
                "Open" if "open" in sec.lower() else "WPA2")

            entry = {
                "ssid": ssid,
                "signal": sig_dbm,
                "band": "5GHz",
                "freq": 0,
                "bssid": "",
                "security": sec_display,
                "connected": is_connected or (ssid == current_ssid and len(current_ssid) > 0),
                "known": ssid in known_set,
            }

            iw = iw_map.get(ssid)
            if iw:
                entry["signal"] = iw["signal"]
                entry["freq"] = iw["freq"]
                entry["band"] = iw.get("band", "5GHz")
                entry["bssid"] = iw["bssid"]

            networks.append(entry)
    except Exception:
        pass

    # Add SSIDs that iw saw but iwctl did not list (rare, e.g. hidden/just-appeared)
    listed = {n["ssid"] for n in networks}
    for ssid, iw in iw_map.items():
        if ssid in listed:
            continue
        networks.append({
            "ssid": ssid,
            "signal": iw["signal"],
            "band": iw.get("band", "5GHz"),
            "freq": iw["freq"],
            "bssid": iw["bssid"],
            "security": "WPA2",
            "connected": ssid == current_ssid,
            "known": ssid in known_set,
        })

    return networks


def main():
    current_ssid = get_current_ssid()
    known_set = get_known_networks()
    iw_map = scan_via_iw()
    nets = scan_via_iwctl(current_ssid, known_set, iw_map)

    # Guarantee the active uplink is always present at the top.
    if current_ssid and not any(n["connected"] for n in nets):
        iw = iw_map.get(current_ssid, {})
        nets.insert(0, {
            "ssid": current_ssid,
            "signal": iw.get("signal", -48),
            "band": iw.get("band", "5GHz"),
            "freq": iw.get("freq", 0),
            "bssid": iw.get("bssid", ""),
            "security": "WPA3",
            "connected": True,
            "known": True,
        })

    # Connected first, then known, then strongest signal.
    nets.sort(key=lambda n: (not n["connected"], not n["known"], -n["signal"]))
    print(json.dumps(nets))


if __name__ == "__main__":
    main()
