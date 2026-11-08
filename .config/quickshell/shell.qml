// Root shell configuration
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "./services"
import "./layers"

ShellRoot {
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
}
