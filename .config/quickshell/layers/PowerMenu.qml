import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../services"
import "../modules/powermenu"

PanelWindow {
    id: powerMenuRoot
    property bool isOpen: false
    screen: Quickshell.screens[0]

    // Navigation & confirmation state
    property string viewState: "grid" // "grid" or "confirm"
    property var pendingAction: null

    // Master Action Definitions
    readonly property var actions: [
        {
            id: "shutdown",
            label: "Shutdown",
            key: "U",
            icon: "",
            color: Theme.urgent,
            desc: "Unsaved progress will be lost. Press U or Enter to confirm.",
            cmd: ["systemctl", "poweroff"]
        },
        {
            id: "reboot",
            label: "Reboot",
            key: "R",
            icon: "",
            color: Theme.accent,
            desc: "The system will restart all active services. Press R or Enter to confirm.",
            cmd: ["systemctl", "reboot"]
        },
        {
            id: "sleep",
            label: "Sleep",
            key: "S",
            icon: "󰒲",
            color: Theme.fgSoft,
            desc: "The system will enter low-power sleep mode. Press S or Enter to confirm.",
            cmd: ["systemctl", "suspend"]
        },
        {
            id: "lock",
            label: "Lock",
            key: "L",
            icon: "",
            color: Theme.fgSoft,
            desc: "Your screen will lock. Background sessions stay active. Press L or Enter to confirm.",
            cmd: ["hyprlock"]
        },
        {
            id: "logout",
            label: "Logout",
            key: "E",
            icon: "󰍃",
            color: Theme.fgSoft,
            desc: "Your current user desktop session will terminate. Press E or Enter to confirm.",
            cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"]
        },
        {
            id: "hibernate",
            label: "Hibernate",
            key: "H",
            icon: "",
            color: Theme.fgSoft,
            desc: "Session state will be saved to disk and powered down. Press H or Enter to confirm.",
            cmd: ["systemctl", "hibernate"]
        }
    ]

    onIsOpenChanged: {
        if (isOpen) {
            viewState = "grid";
            pendingAction = null;
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "powermenu"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: isOpen || bgDim.opacity > 0

    // ─── Keyboard Shortcuts ───
    // Escape: Return to grid if in confirm; close modal if in grid
    Shortcut {
        sequence: "Escape"
        enabled: powerMenuRoot.isOpen
        onActivated: {
            if (powerMenuRoot.viewState === "confirm") {
                powerMenuRoot.cancelConfirm();
            } else {
                powerMenuRoot.isOpen = false;
            }
        }
    }

    // Enter / Return: Execute pending action if in confirm
    Shortcut {
        sequence: "Return"
        enabled: powerMenuRoot.isOpen && powerMenuRoot.viewState === "confirm"
        onActivated: powerMenuRoot.executePending()
    }
    Shortcut {
        sequence: "Enter"
        enabled: powerMenuRoot.isOpen && powerMenuRoot.viewState === "confirm"
        onActivated: powerMenuRoot.executePending()
    }

    // Direct Keys: UU, RR, SS, LL, EE, HH execution
    Shortcut {
        sequence: "U"
        enabled: powerMenuRoot.isOpen
        onActivated: {
            if (powerMenuRoot.viewState === "confirm") {
                if (powerMenuRoot.pendingAction && powerMenuRoot.pendingAction.id === "shutdown") {
                    powerMenuRoot.executePending();
                }
            } else {
                powerMenuRoot.requestConfirm(powerMenuRoot.actions[0]);
            }
        }
    }
    Shortcut {
        sequence: "R"
        enabled: powerMenuRoot.isOpen
        onActivated: {
            if (powerMenuRoot.viewState === "confirm") {
                if (powerMenuRoot.pendingAction && powerMenuRoot.pendingAction.id === "reboot") {
                    powerMenuRoot.executePending();
                }
            } else {
                powerMenuRoot.requestConfirm(powerMenuRoot.actions[1]);
            }
        }
    }
    Shortcut {
        sequence: "S"
        enabled: powerMenuRoot.isOpen
        onActivated: {
            if (powerMenuRoot.viewState === "confirm") {
                if (powerMenuRoot.pendingAction && powerMenuRoot.pendingAction.id === "sleep") {
                    powerMenuRoot.executePending();
                }
            } else {
                powerMenuRoot.requestConfirm(powerMenuRoot.actions[2]);
            }
        }
    }
    Shortcut {
        sequence: "L"
        enabled: powerMenuRoot.isOpen
        onActivated: {
            if (powerMenuRoot.viewState === "confirm") {
                if (powerMenuRoot.pendingAction && powerMenuRoot.pendingAction.id === "lock") {
                    powerMenuRoot.executePending();
                }
            } else {
                powerMenuRoot.requestConfirm(powerMenuRoot.actions[3]);
            }
        }
    }
    Shortcut {
        sequence: "E"
        enabled: powerMenuRoot.isOpen
        onActivated: {
            if (powerMenuRoot.viewState === "confirm") {
                if (powerMenuRoot.pendingAction && powerMenuRoot.pendingAction.id === "logout") {
                    powerMenuRoot.executePending();
                }
            } else {
                powerMenuRoot.requestConfirm(powerMenuRoot.actions[4]);
            }
        }
    }
    Shortcut {
        sequence: "H"
        enabled: powerMenuRoot.isOpen
        onActivated: {
            if (powerMenuRoot.viewState === "confirm") {
                if (powerMenuRoot.pendingAction && powerMenuRoot.pendingAction.id === "hibernate") {
                    powerMenuRoot.executePending();
                }
            } else {
                powerMenuRoot.requestConfirm(powerMenuRoot.actions[5]);
            }
        }
    }

    function requestConfirm(actionObj) {
        pendingAction = actionObj;
        viewState = "confirm";
    }

    function cancelConfirm() {
        viewState = "grid";
        pendingAction = null;
    }

    function executePending() {
        if (!pendingAction) return;
        var act = pendingAction;
        powerMenuRoot.isOpen = false;
        if (act.id === "logout") {
            Hyprland.dispatch("hl.dsp.exit()");
        } else if (act.cmd && act.cmd.length > 0) {
            Quickshell.execDetached(act.cmd);
        }
    }

    // Backdrop Dimming (Subtle 45% dark scrim allowing Hyprland blur to shine)
    Rectangle {
        id: bgDim
        anchors.fill: parent
        color: "#000000"
        opacity: powerMenuRoot.isOpen ? 0.45 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (powerMenuRoot.viewState === "confirm") {
                    powerMenuRoot.cancelConfirm();
                } else {
                    powerMenuRoot.isOpen = false;
                }
            }
        }
    }

    // ─── Central Modal Monolith (Grand 16:9 Aspect: 864px x 486px at 1440p) ───
    Rectangle {
        id: modal
        anchors.centerIn: parent
        width: Math.round(864 * Theme.uiScale)
        height: Math.round(486 * Theme.uiScale)
        radius: Math.round(Theme.radiusIsland * Theme.uiScale) // ~20px
        color: Qt.rgba(0, 0, 0, 0.90) // Pure matte obsidian matching Calendar Monolith
        border.width: 0 // Zero harsh white border lines

        scale: powerMenuRoot.isOpen ? 1.0 : 0.94
        opacity: powerMenuRoot.isOpen ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // ====================================================================
        // VIEW 1: Grid Action View (Prominent Icons First, Text Second)
        // ====================================================================
        GridView {
            anchors.fill: parent
            visible: powerMenuRoot.viewState === "grid"
            opacity: powerMenuRoot.viewState === "grid" ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            actions: powerMenuRoot.actions
            onActionSelected: function(act) { powerMenuRoot.requestConfirm(act); }
            onCancelRequested: { powerMenuRoot.isOpen = false; }
        }

        // ====================================================================
        // VIEW 2: Safe Confirmation View (Two-Step Confirmation Gate)
        // ====================================================================
        ConfirmView {
            anchors.fill: parent
            visible: powerMenuRoot.viewState === "confirm"
            opacity: powerMenuRoot.viewState === "confirm" ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            pendingAction: powerMenuRoot.pendingAction
            onConfirmed: powerMenuRoot.executePending()
            onCancelled: powerMenuRoot.cancelConfirm()
        }
    }
}
