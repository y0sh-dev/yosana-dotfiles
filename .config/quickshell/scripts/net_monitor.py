#!/usr/bin/env python3
"""
net_monitor.py - Lightweight Event-Driven Network Status Monitor
Monitors Linux network carrier and iwd station state via DBus & /proc.
Outputs single-line JSON stream to stdout for Quickshell consumption.
"""

import os
import sys
import time
import json
import glob
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

def get_wired_state():
    for path in glob.glob("/sys/class/net/en*/operstate"):
        try:
            with open(path) as f:
                if f.read().strip() == "up":
                    return True
        except Exception:
            pass
    return False

def get_wifi_rssi():
    try:
        with open("/proc/net/wireless") as f:
            for line in f:
                if "wlan" in line:
                    parts = line.split()
                    if len(parts) >= 4:
                        return int(float(parts[3]))
    except Exception:
        pass
    return -100

class NetMonitor:
    def __init__(self):
        self.bus = dbus.SystemBus()
        self.last_state = {}
        self.station_path = None
        self.find_station()
        self.setup_signals()

    def find_station(self):
        try:
            obj = self.bus.get_object("net.connman.iwd", "/")
            mgr = dbus.Interface(obj, "org.freedesktop.DBus.ObjectManager")
            objects = mgr.GetManagedObjects()
            for path, interfaces in objects.items():
                if "net.connman.iwd.Station" in interfaces:
                    self.station_path = path
                    break
        except Exception:
            self.station_path = None

    def setup_signals(self):
        # Listen for any PropertyChanged signals from iwd
        self.bus.add_signal_receiver(
            self.on_properties_changed,
            signal_name="PropertiesChanged",
            dbus_interface="org.freedesktop.DBus.Properties",
            bus_name="net.connman.iwd"
        )

    def on_properties_changed(self, interface, changed_props, invalidated_props):
        self.emit_state()

    def get_ssid(self):
        if not self.station_path:
            self.find_station()
        if not self.station_path:
            return ""

        try:
            obj = self.bus.get_object("net.connman.iwd", self.station_path)
            props = dbus.Interface(obj, "org.freedesktop.DBus.Properties")
            net_path = props.Get("net.connman.iwd.Station", "ConnectedNetwork")
            if net_path:
                net_obj = self.bus.get_object("net.connman.iwd", net_path)
                net_props = dbus.Interface(net_obj, "org.freedesktop.DBus.Properties")
                return str(net_props.Get("net.connman.iwd.Network", "Name"))
        except Exception:
            pass
        return ""

    def emit_state(self):
        wired = get_wired_state()
        if wired:
            state = {
                "wired": True,
                "connected": True,
                "ssid": "Ethernet",
                "rssi": 0
            }
        else:
            ssid = self.get_ssid()
            connected = len(ssid) > 0
            rssi = get_wifi_rssi() if connected else -100
            state = {
                "wired": False,
                "connected": connected,
                "ssid": ssid,
                "rssi": rssi
            }

        # Deduplicate sequential identical emissions (except rssi changes)
        if state != self.last_state:
            self.last_state = state
            print(json.dumps(state), flush=True)

def main():
    DBusGMainLoop(set_as_default=True)
    monitor = NetMonitor()
    # Initial immediate output
    monitor.emit_state()

    # Low-frequency periodic RSSI tick (every 10s only when wireless connected)
    def on_periodic():
        monitor.emit_state()
        return True

    GLib.timeout_add_seconds(10, on_periodic)

    loop = GLib.MainLoop()
    try:
        loop.run()
    except (KeyboardInterrupt, SystemExit):
        pass

if __name__ == "__main__":
    main()
