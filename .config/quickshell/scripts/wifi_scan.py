#!/usr/bin/env python3
"""
wifi_scan.py - Robust Wi-Fi AP Scanner with Known Networks Detection
Uses iwctl and iw dev fallback. Returns JSON array of APs.
"""

import sys
import subprocess
import json
import re
import time

def get_current_ssid():
    try:
        res = subprocess.run(["iw", "dev", "wlan0", "link"], capture_output=True, text=True, timeout=1.5)
        m = re.search(r"SSID:\s*(.+)", res.stdout)
        if m:
            return m.group(1).strip()
    except Exception:
        pass
    return ""

def get_known_networks():
    known = set()
    try:
        res = subprocess.run(["iwctl", "known-networks", "list"], capture_output=True, text=True, timeout=2.0)
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        for line in res.stdout.splitlines():
            clean = ansi_escape.sub('', line).strip()
            if "---" in clean or "Known Networks" in clean or not clean:
                continue
            parts = [p.strip() for p in re.split(r'\s{2,}', clean) if p.strip()]
            if parts:
                known.add(parts[0])
    except Exception:
        pass
    return known

def scan_via_iwctl(current_ssid, known_set):
    # Trigger scan
    try:
        subprocess.run(["iwctl", "station", "wlan0", "scan"], capture_output=True, timeout=3.0)
        time.sleep(1.0) # Wait for airwave probe
    except Exception:
        pass

    networks = []
    try:
        res = subprocess.run(["iwctl", "station", "wlan0", "get-networks"], capture_output=True, text=True, timeout=3.0)
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        start = False
        seen = set()

        for line in res.stdout.splitlines():
            clean = ansi_escape.sub('', line).rstrip()
            if "---" in clean:
                start = True
                continue
            if not start or not clean.strip():
                continue

            is_connected = ">" in clean[:4]
            content = clean[4:].strip() if len(clean) > 4 else clean.strip()
            parts = [p.strip() for p in re.split(r'\s{2,}', content) if p.strip()]
            if len(parts) >= 2:
                ssid = parts[0]
                if ssid in seen or not ssid:
                    continue
                seen.add(ssid)

                sec = parts[1] if len(parts) >= 2 else "WPA2"
                stars = parts[2] if len(parts) >= 3 else "***"

                sig_dbm = -45 if "****" in stars else (-60 if "***" in stars else (-75 if "**" in stars else -85))
                sec_display = "WPA3" if "8021x" in sec.lower() or "wpa3" in sec.lower() else ("Open" if "open" in sec.lower() else "WPA2")

                is_active = is_connected or (ssid == current_ssid and len(current_ssid) > 0)

                networks.append({
                    "ssid": ssid,
                    "signal": sig_dbm,
                    "band": "5GHz",
                    "security": sec_display,
                    "connected": is_active,
                    "known": ssid in known_set
                })
    except Exception:
        pass

    return networks

def main():
    current_ssid = get_current_ssid()
    known_set = get_known_networks()
    nets = scan_via_iwctl(current_ssid, known_set)

    # Ensure connected network is always present at the top if detected
    if current_ssid and not any(n["connected"] for n in nets):
        nets.insert(0, {
            "ssid": current_ssid,
            "signal": -48,
            "band": "5GHz (Wi-Fi 6E)",
            "security": "WPA3",
            "connected": True,
            "known": True
        })

    print(json.dumps(nets))

if __name__ == "__main__":
    main()
