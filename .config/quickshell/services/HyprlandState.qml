import QtQuick
import Quickshell.Hyprland

Item {
    // Extract state from built-in Hyprland singleton
    readonly property int focusedWs: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.activeWorkspace.id : 0
    
    readonly property var displayedWs: {
        var ids = [];
        for (var i = 0; i < Hyprland.monitors.values.length; i++) {
            var mon = Hyprland.monitors.values[i];
            if (mon.activeWorkspace) ids.push(mon.activeWorkspace.id);
        }
        return ids;
    }

    readonly property var occupiedWs: {
        var ids = [];
        for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
            var ws = Hyprland.workspaces.values[i];
            // Track workspaces that contain open windows (toplevels)
            if (ws.id > 0 && ws.toplevels.values.length > 0) ids.push(ws.id);
        }
        return ids;
    }
}
