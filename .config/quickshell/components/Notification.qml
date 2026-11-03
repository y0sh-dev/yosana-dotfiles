import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: notifRoot
    implicitHeight: Theme.islandHeight
    implicitWidth: 32 // Fixed width preventing any layout shifting for adjacent controls

    property int unreadCount: 0
    property bool isDnd: false

    // Bell with dot badge (󰂞) when unread, crossed bell (󰂛) when DND, outline (󰂚) when idle
    readonly property string icon: {
        if (notifRoot.isDnd) return "󰂛";
        if (notifRoot.unreadCount > 0) return "󰂞";
        return "󰂚";
    }

    // Zero-polling event-driven SwayNC stream subscriber (0% idle CPU)
    Process {
        id: swayncSubProc
        command: ["swaync-client", "-s"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var raw = (line || "").toString().trim();
                if (!raw) return;
                try {
                    var obj = JSON.parse(raw);
                    if (obj.count !== undefined) notifRoot.unreadCount = obj.count;
                    if (obj.dnd !== undefined) notifRoot.isDnd = obj.dnd;
                } catch(e) {
                    // Ignore non-json frames
                }
            }
        }

        // Auto-reconnect if SwayNC daemon restarts
        onExited: function(exitCode, exitStatus) {
            reconnectTimer.restart();
        }
    }

    Timer {
        id: reconnectTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!swayncSubProc.running) {
                swayncSubProc.running = true;
            }
        }
    }

    // Main notification button pill
    Rectangle {
        id: bgPill
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 14
        color: notifMouse.containsMouse ? Theme.surfaceHover : "transparent"
        border.color: notifMouse.containsMouse ? (notifRoot.unreadCount > 0 ? Theme.accent : Theme.border) : "transparent"
        border.width: 1

        scale: notifMouse.pressed ? 0.90 : (notifMouse.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: notifRoot.icon
            font.pixelSize: 18
            font.family: Theme.fontFamily
            color: notifRoot.unreadCount > 0 ? Theme.accent : (notifMouse.containsMouse ? Theme.fg : Theme.subtext)
            Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
        }
    }

    MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                // Toggle SwayNC notification center
                Quickshell.execDetached(["swaync-client", "-t"]);
            } else if (mouse.button === Qt.RightButton) {
                // Toggle Do-Not-Disturb (DND)
                Quickshell.execDetached(["swaync-client", "-d"]);
            }
        }
    }
}
