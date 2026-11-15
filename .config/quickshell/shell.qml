// Root shell configuration
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import "./services"
import "./layers"

ShellRoot {
    id: root
    HyprlandState { id: hyprlandLogic }

    TopBar { 
        focusedWs: hyprlandLogic.focusedWs
        displayedWs: hyprlandLogic.displayedWs
        occupiedWs: hyprlandLogic.occupiedWs
        
        timeText: TimeService.shortTime
        onArchClicked: {
            console.log("Arch Logo clicked")
        }
        onMenuClicked: {
            console.log("Main Menu / Control Shortcut clicked")
        }
        onClockClicked: {
            calendarPopup.isOpen = !calendarPopup.isOpen
            if (calendarPopup.isOpen) {
                powerMenu.isOpen = false
            }
        }
        onVolumeClicked: {
            audioPanel.isOpen = !audioPanel.isOpen
            if (audioPanel.isOpen) {
                powerMenu.isOpen = false
            }
        }
        onNetworkClicked: {
            networkPanel.isOpen = !networkPanel.isOpen
            if (networkPanel.isOpen) {
                powerMenu.isOpen = false
            }
        }
        onPowerClicked: {
            powerMenu.isOpen = !powerMenu.isOpen
            if (powerMenu.isOpen) {
                // PowerMenu closes all telemetry panels
                calendarPopup.isOpen = false
                audioPanel.isOpen = false
                networkPanel.isOpen = false
            }
        }
    }

    CalendarPopup {
        id: calendarPopup
    }

    AudioPanel {
        id: audioPanel
    }

    NetworkPanel {
        id: networkPanel
    }

    PowerMenu {
        id: powerMenu
    }

    function activeMprisPlayer() {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].isPlaying) return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    // Native MPRIS IPC bridge (replaces external playerctl dependency)
    IpcHandler {
        target: "media"

        function playPause(): void {
            const target = root.activeMprisPlayer();
            if (target) target.togglePlaying();
        }

        function next(): void {
            const target = root.activeMprisPlayer();
            if (target) target.next();
        }

        function previous(): void {
            const target = root.activeMprisPlayer();
            if (target) target.previous();
        }
    }
}
