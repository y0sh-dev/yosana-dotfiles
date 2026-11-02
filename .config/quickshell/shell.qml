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
    TimeService { id: timeService }

    TopBar { 
        focusedWs: hyprlandLogic.focusedWs
        displayedWs: hyprlandLogic.displayedWs
        occupiedWs: hyprlandLogic.occupiedWs
        
        timeText: timeService.shortTime
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
        onNetworkClicked: {
            console.log("Network clicked: control panel trigger")
        }
        onPowerClicked: {
            powerMenu.isOpen = !powerMenu.isOpen
            if (powerMenu.isOpen) {
                calendarPopup.isOpen = false
            }
        }
    }

    CalendarPopup {
        id: calendarPopup
    }

    PowerMenu {
        id: powerMenu
    }
}
