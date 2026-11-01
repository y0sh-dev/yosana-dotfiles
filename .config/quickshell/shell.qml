import Quickshell
import Quickshell.Hyprland
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
        onClockClicked: calendarPopup.isOpen = !calendarPopup.isOpen
        onVolumeClicked: volumePopup.isOpen = !volumePopup.isOpen
        onPowerClicked: powerMenu.isOpen = !powerMenu.isOpen
    }

    CalendarPopup {
        id: calendarPopup
        dateText: timeService.fullDate
    }

    VolumePopup {
        id: volumePopup
    }

    PowerMenu {
        id: powerMenu
    }
}
