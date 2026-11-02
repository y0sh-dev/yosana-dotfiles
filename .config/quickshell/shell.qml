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
            console.log("Clock clicked: center anchor trigger")
        }
        onNetworkClicked: {
            console.log("Network clicked: control panel trigger")
        }
        onPowerClicked: powerMenu.isOpen = !powerMenu.isOpen
    }

    PowerMenu {
        id: powerMenu
    }
}
