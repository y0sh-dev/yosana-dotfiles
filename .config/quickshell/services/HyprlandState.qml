import QtQuick
import Quickshell.Hyprland

Item {
    // 組み込みの Hyprland オブジェクトからデータを抽出
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
            // ウィンドウ（toplevels）が存在するワークスペースを記録
            if (ws.id > 0 && ws.toplevels.values.length > 0) ids.push(ws.id);
        }
        return ids;
    }
}
