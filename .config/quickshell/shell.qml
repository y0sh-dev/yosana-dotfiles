// Root shell configuration
import Quickshell
// Root shell configuration
import Quickshell.Hyprland
// Root shell configuration
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
                audioPanel.isOpen = false
            }
        }
        onVolumeClicked: {
            audioPanel.isOpen = !audioPanel.isOpen
            if (audioPanel.isOpen) {
                calendarPopup.isOpen = false
                powerMenu.isOpen = false
            }
        }
        onNetworkClicked: {
            console.log("Network clicked: control panel trigger")
        }
        onPowerClicked: {
            powerMenu.isOpen = !powerMenu.isOpen
            if (powerMenu.isOpen) {
                calendarPopup.isOpen = false
                audioPanel.isOpen = false
            }
        }
    }

    CalendarPopup {
        id: calendarPopup
    }

    AudioPanel {
        id: audioPanel
    }

    PowerMenu {
        id: powerMenu
    }
}
