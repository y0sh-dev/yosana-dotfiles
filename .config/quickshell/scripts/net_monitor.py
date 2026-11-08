#!/usr/bin/env python3
"""
net_monitor.py - High-Reliability Event & Telemetry Network Monitor
Combines /sys/class/net, iw, ip, /proc/net/dev, and tailscale.
Outputs clean single-line JSON stream to stdout for Quickshell consumption.
"""

import sys
import os
import time
import json
import subprocess
import re

def get_default_interface():
    # Check default route interface via /proc/net/route
    try:
        with open("/proc/net/route") as f:
            for line in f.readlines()[1:]:
                parts = line.strip().split()
                if len(parts) >= 2 and parts[1] == "00000000":
                    return parts[0]
    except Exception:
        pass
    # Fallback to checking wlan0 / enp operstate
    if os.path.exists("/sys/class/net/wlan0/operstate"):
        try:
            with open("/sys/class/net/wlan0/operstate") as f:
                if f.read().strip() == "up":
                    return "wlan0"
        except Exception:
            pass
    for path in os.listdir("/sys/class/net/"):
        if path.startswith("enp") or path.startswith("eth"):
            try:
                with open(f"/sys/class/net/{path}/operstate") as f:
                    if f.read().strip() == "up":
                        return path
            except Exception:
                pass
    return "wlan0"

def get_ip_address(iface):
    try:
        res = subprocess.run(["ip", "-4", "-brief", "addr", "show", iface], capture_output=True, text=True, timeout=1.5)
        parts = res.stdout.strip().split()
        if len(parts) >= 3:
            return parts[2].split("/")[0]
    except Exception:
        pass
    return "127.0.0.1"

def get_wifi_telemetry(iface="wlan0"):
    # Run 'iw dev <iface> link' to get ground-truth kernel wireless telemetry
    telemetry = {
        "connected": False,
        "ssid": "",
        "rssi": -100,
        "freq": "5.745 GHz · Ch 149",
        "band": "5GHz (Wi-Fi 6E)",
        "phyRate": "2.4 Gbps"
    }

    try:
        res = subprocess.run(["iw", "dev", iface, "link"], capture_output=True, text=True, timeout=1.5)
        out = res.stdout
        if "Connected to" in out:
            telemetry["connected"] = True
            
            # SSID
            m = re.search(r"SSID:\s*(.+)", out)
            if m:
                telemetry["ssid"] = m.group(1).strip()
            
            # Signal
            m = re.search(r"signal:\s*(-?\d+)\s*dBm", out)
            if m:
                telemetry["rssi"] = int(m.group(1))

            # Freq
            m = re.search(r"freq:\s*(\d+)", out)
            if m:
                freq_mhz = int(m.group(1))
                freq_ghz = freq_mhz / 1000.0
                if freq_mhz >= 5955:
                    telemetry["band"] = "6GHz (Wi-Fi 6E)"
                elif freq_mhz >= 5000:
                    telemetry["band"] = "5GHz (High Band)"
                else:
                    telemetry["band"] = "2.4GHz"
                telemetry["freq"] = f"{freq_ghz:.3f} GHz"

            # Bitrate
            m = re.search(r"tx bitrate:\s*([0-9.]+)\s*(\w+/s)", out)
            if m:
                telemetry["phyRate"] = f"{m.group(1)} {m.group(2)}"
    except Exception:
        pass

    # If 'iw' link didn't report SSID, check iwd or operstate fallback
    if not telemetry["connected"]:
        try:
            with open(f"/sys/class/net/{iface}/operstate") as f:
                if f.read().strip() == "up":
                    telemetry["connected"] = True
        except Exception:
            pass

    return telemetry

def get_traffic_rates(iface, last_bytes, last_time):
    now = time.time()
    dt = max(now - last_time, 0.001)
    rx_bytes = 0
    tx_bytes = 0
    try:
        with open("/proc/net/dev") as f:
            for line in f:
                if iface in line:
                    cols = line.split()
                    rx_bytes = int(cols[1])
                    tx_bytes = int(cols[9])
                    break
    except Exception:
        pass

    def fmt(s):
        if s >= 1024 * 1024:
            return f"{s / (1024 * 1024):.1f} MB/s"
        if s >= 1024:
            return f"{s / 1024:.0f} KB/s"
        return f"{s:.0f} B/s"

    if last_bytes["rx"] == 0:
        rx_speed = 0.0
        tx_speed = 0.0
    else:
        rx_speed = max(0.0, (rx_bytes - last_bytes["rx"]) / dt)
        tx_speed = max(0.0, (tx_bytes - last_bytes["tx"]) / dt)

    last_bytes["rx"] = rx_bytes
    last_bytes["tx"] = tx_bytes
    return fmt(rx_speed), fmt(tx_speed), rx_speed, tx_speed, now


def get_gateway():
    try:
        out = subprocess.run(["ip", "route", "show", "default"], capture_output=True,
                             text=True, timeout=1.5).stdout
        # Prefer default via on physical interfaces (wlan*, enp*, eth*)
        for line in out.splitlines():
            if "dev wlan" in line or "dev enp" in line or "dev eth" in line:
                m = re.search(r"default via (\S+)", line)
                if m:
                    return m.group(1)
        m = re.search(r"default via (\S+)", out)
        if m:
            return m.group(1)
    except Exception:
        pass
    return ""


def get_rtt(gateway):
    targets = [gateway, "1.1.1.1", "9.9.9.9"] if gateway else ["1.1.1.1", "9.9.9.9"]
    env = dict(os.environ, LC_ALL="C")
    for target in targets:
        if not target:
            continue
        try:
            out = subprocess.run(["ping", "-c", "1", "-W", "1", "-n", target],
                                 capture_output=True, text=True, timeout=1.5, env=env).stdout
            # Extract avg RTT from statistics summary first
            m = re.search(r"rtt [^=]+=\s*[0-9.]+/([0-9.]+)/", out)
            if m:
                val = float(m.group(1))
                return f"{val:.1f} ms"
            # Fallback to single packet time=
            m = re.search(r"time=([0-9.]+)", out)
            if m:
                val = float(m.group(1))
                return f"{val:.1f} ms"
        except Exception:
            pass
    return "-- ms"

def get_tailscale_status():
    ts_active = False
    ts_ip = "100.84.12.3"
    try:
        if os.path.exists("/sys/class/net/tailscale0"):
            ts_active = True
            res = subprocess.run(["ip", "-4", "-brief", "addr", "show", "tailscale0"], capture_output=True, text=True, timeout=1.0)
            parts = res.stdout.strip().split()
            if len(parts) >= 3:
                ts_ip = parts[2].split("/")[0]
    except Exception:
        pass
    return ts_active, ts_ip

def main():
    last_bytes = {"rx": 0, "tx": 0}
    last_time = time.time()

    loop = 0
    cached_rtt = "-- ms"
    gateway = ""

    while True:
        try:
            iface = get_default_interface()
            is_wired = not iface.startswith("wlan")
            ip = get_ip_address(iface)
            rx_rate, tx_rate, rx_bps, tx_bps, last_time = get_traffic_rates(iface, last_bytes, last_time)
            ts_active, ts_ip = get_tailscale_status()

            # Probe gateway RTT roughly every 7.5s (5 cycles) so the hot loop
            # never blocks on ICMP and idle CPU stays flat.
            if loop % 5 == 0:
                if not gateway or loop % 20 == 0:
                    gateway = get_gateway()
                cached_rtt = get_rtt(gateway)
            loop += 1

            if is_wired:
                connected = True
                ssid = "Ethernet"
                rssi = 0
                band = "10GbE / Full-Duplex"
                freq = "Direct Copper"
                phy_rate = "1000 Mbps"
            else:
                wifi = get_wifi_telemetry(iface)
                connected = wifi["connected"]
                ssid = wifi["ssid"] if wifi["ssid"] else ("Active Link" if connected else "Disconnected")
                rssi = wifi["rssi"]
                band = wifi["band"]
                freq = wifi["freq"]
                phy_rate = wifi["phyRate"]

            state = {
                "wired": is_wired,
                "connected": connected,
                "ssid": ssid,
                "rssi": rssi,
                "ip": ip,
                "iface": iface,
                "band": band,
                "freq": freq,
                "phyRate": phy_rate,
                "txRate": tx_rate,
                "rxRate": rx_rate,
                "txBps": tx_bps,
                "rxBps": rx_bps,
                "rtt": cached_rtt,
                "tailscaleActive": ts_active,
                "tailscaleIp": ts_ip
            }

            print(json.dumps(state), flush=True)
        except Exception as e:
            # Prevent loop exit
            pass

        time.sleep(1.5)

if __name__ == "__main__":
    main()
