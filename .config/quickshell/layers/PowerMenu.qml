import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../services"

PanelWindow {
    id: powerMenuRoot
    property bool isOpen: false
    screen: Quickshell.screens[0]

    // Adaptive Resolution Scaling synchronized with Theme SSOT
    readonly property real uiScale: Theme.uiScale

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
            cmd: []
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
            Hyprland.dispatch("exit");
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
    // Matching the exact majestic scale of the Calendar Panel (860px x 490px)
    Rectangle {
        id: modal
        anchors.centerIn: parent
        width: Math.round(864 * powerMenuRoot.uiScale)
        height: Math.round(486 * powerMenuRoot.uiScale)
        radius: Math.round(Theme.radiusIsland * powerMenuRoot.uiScale) // ~20px
        color: Qt.rgba(0, 0, 0, 0.90) // Pure matte obsidian matching Calendar Monolith
        border.width: 0 // Zero harsh white border lines

        scale: powerMenuRoot.isOpen ? 1.0 : 0.94
        opacity: powerMenuRoot.isOpen ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // ====================================================================
        // VIEW 1: Grid Action View (Prominent Icons First, Text Second)
        // ====================================================================
        Item {
            id: gridView
            anchors.fill: parent
            visible: powerMenuRoot.viewState === "grid"
            opacity: powerMenuRoot.viewState === "grid" ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(32 * powerMenuRoot.uiScale)
                spacing: Math.round(20 * powerMenuRoot.uiScale)

                // Header
                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Math.round(6 * powerMenuRoot.uiScale)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Power Session"
                        color: Theme.fgSoft
                        font.pixelSize: Math.round(22 * powerMenuRoot.uiScale)
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Select an action or press shortcut key"
                        color: Theme.subtextDim
                        font.pixelSize: Math.round(13 * powerMenuRoot.uiScale)
                        font.family: Theme.fontFamily
                    }
                }

                // 3x2 Grid of Actions (Large tiles: ~256px x 124px, Huge prominent icons: 50px)
                GridLayout {
                    columns: 3
                    rowSpacing: Math.round(16 * powerMenuRoot.uiScale)
                    columnSpacing: Math.round(16 * powerMenuRoot.uiScale)
                    Layout.alignment: Qt.AlignHCenter

                    Repeater {
                        model: powerMenuRoot.actions

                        delegate: Rectangle {
                            id: actionTile
                            width: Math.round(254 * powerMenuRoot.uiScale)
                            height: Math.round(124 * powerMenuRoot.uiScale)
                            radius: Math.round(16 * powerMenuRoot.uiScale)

                            // Translucent matte surface
                            color: tileMouse.containsMouse
                                ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.18)
                                : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)

                            border.color: tileMouse.containsMouse
                                ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.45)
                                : Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: Math.round(10 * powerMenuRoot.uiScale)

                                // Huge Iconic Lead: 50px (Instant visual recognition without cognitive friction)
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    color: tileMouse.containsMouse ? modelData.color : (modelData.id === "shutdown" ? Theme.urgent : (modelData.id === "reboot" ? Theme.accent : Theme.fgSoft))
                                    font.pixelSize: Math.round(50 * powerMenuRoot.uiScale)
                                    font.family: Theme.fontFamily
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                // Secondary Label with Shortcut Hint: e.g. Shutdown (U)
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: Math.round(6 * powerMenuRoot.uiScale)

                                    Text {
                                        text: modelData.label
                                        color: tileMouse.containsMouse ? modelData.color : Theme.fgSoft
                                        font.pixelSize: Math.round(15 * powerMenuRoot.uiScale)
                                        font.bold: true
                                        font.family: Theme.fontFamily
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Text {
                                        text: "(" + modelData.key + ")"
                                        color: tileMouse.containsMouse ? modelData.color : Theme.subtextDim
                                        font.pixelSize: Math.round(13 * powerMenuRoot.uiScale)
                                        font.bold: true
                                        font.family: Theme.fontFamily
                                        opacity: 0.85
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: powerMenuRoot.requestConfirm(modelData)
                            }
                        }
                    }
                }

                // Footer Cancel Capsule
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: cancelGridRow.implicitWidth + Math.round(32 * powerMenuRoot.uiScale)
                    implicitHeight: Math.round(36 * powerMenuRoot.uiScale)
                    radius: Math.round(18 * powerMenuRoot.uiScale)
                    color: cancelGridMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: cancelGridMouse.containsMouse ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Row {
                        id: cancelGridRow
                        anchors.centerIn: parent
                        spacing: Math.round(8 * powerMenuRoot.uiScale)

                        Text {
                            text: "Cancel"
                            color: cancelGridMouse.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(14 * powerMenuRoot.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: "(ESC)"
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(12 * powerMenuRoot.uiScale)
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: 0.7
                        }
                    }

                    MouseArea {
                        id: cancelGridMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerMenuRoot.isOpen = false
                    }
                }
            }
        }

        // ====================================================================
        // VIEW 2: Safe Confirmation View (Two-Step Confirmation Gate)
        // High-contrast, immediately readable buttons without hovering
        // ====================================================================
        Item {
            id: confirmView
            anchors.fill: parent
            visible: powerMenuRoot.viewState === "confirm"
            opacity: powerMenuRoot.viewState === "confirm" ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(36 * powerMenuRoot.uiScale)
                spacing: Math.round(24 * powerMenuRoot.uiScale)

                // Header Message
                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Math.round(8 * powerMenuRoot.uiScale)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: powerMenuRoot.pendingAction ? ("Really want to " + powerMenuRoot.pendingAction.label.toLowerCase() + "?") : ""
                        color: Theme.fgSoft
                        font.pixelSize: Math.round(24 * powerMenuRoot.uiScale)
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: powerMenuRoot.pendingAction ? powerMenuRoot.pendingAction.desc : ""
                        color: Theme.subtextDim
                        font.pixelSize: Math.round(14 * powerMenuRoot.uiScale)
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillHeight: true }

                // Split Center Content: Large Iconic Badge (Left) + High-Contrast Horizontal Buttons (Right)
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Math.round(36 * powerMenuRoot.uiScale)

                    // Left: Large Glowing Iconic Badge (140px x 140px, 64px icon)
                    Rectangle {
                        width: Math.round(140 * powerMenuRoot.uiScale)
                        height: Math.round(140 * powerMenuRoot.uiScale)
                        radius: Math.round(24 * powerMenuRoot.uiScale)
                        color: powerMenuRoot.pendingAction
                            ? Qt.rgba(powerMenuRoot.pendingAction.color.r, powerMenuRoot.pendingAction.color.g, powerMenuRoot.pendingAction.color.b, 0.16)
                            : "transparent"
                        border.color: powerMenuRoot.pendingAction
                            ? Qt.rgba(powerMenuRoot.pendingAction.color.r, powerMenuRoot.pendingAction.color.g, powerMenuRoot.pendingAction.color.b, 0.40)
                            : "transparent"
                        border.width: 1.5

                        Text {
                            anchors.centerIn: parent
                            text: powerMenuRoot.pendingAction ? powerMenuRoot.pendingAction.icon : ""
                            color: powerMenuRoot.pendingAction ? powerMenuRoot.pendingAction.color : Theme.fgSoft
                            font.pixelSize: Math.round(64 * powerMenuRoot.uiScale)
                            font.family: Theme.fontFamily
                        }
                    }

                    // Right: Horizontal Action Pair [ Cancel (ESC) ] [ Action (Key / ↵) ]
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(20 * powerMenuRoot.uiScale)

                        // ─── Button 1: Cancel (ESC) ───
                        Rectangle {
                            implicitWidth: Math.round(200 * powerMenuRoot.uiScale)
                            implicitHeight: Math.round(64 * powerMenuRoot.uiScale)
                            radius: Math.round(16 * powerMenuRoot.uiScale)
                            color: cancelBtnMouse.containsMouse
                                ? Theme.surfaceHover
                                : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.55)
                            border.color: cancelBtnMouse.containsMouse ? Theme.accent : Qt.rgba(1, 1, 1, 0.12)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: Math.round(10 * powerMenuRoot.uiScale)

                                Text {
                                    text: "Cancel"
                                    color: cancelBtnMouse.containsMouse ? Theme.accent : "#ffffff"
                                    font.pixelSize: Math.round(16 * powerMenuRoot.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "(ESC)"
                                    color: Theme.subtextDim
                                    font.pixelSize: Math.round(13 * powerMenuRoot.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                    opacity: 0.85
                                }
                            }

                            MouseArea {
                                id: cancelBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: powerMenuRoot.cancelConfirm()
                            }
                        }

                        // ─── Button 2: Action [Shutdown (U / ↵)] - High Contrast Without Hovering ───
                        Rectangle {
                            id: confirmBtn
                            implicitWidth: Math.round(230 * powerMenuRoot.uiScale)
                            implicitHeight: Math.round(64 * powerMenuRoot.uiScale)
                            radius: Math.round(16 * powerMenuRoot.uiScale)

                            property color actionColor: powerMenuRoot.pendingAction ? powerMenuRoot.pendingAction.color : Theme.accent

                            // High-contrast semi-solid fill even without hovering for effortless instant legibility
                            color: confirmBtnMouse.containsMouse
                                ? actionColor
                                : Qt.rgba(actionColor.r, actionColor.g, actionColor.b, 0.32)

                            border.color: actionColor
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: Math.round(10 * powerMenuRoot.uiScale)

                                Text {
                                    text: powerMenuRoot.pendingAction ? powerMenuRoot.pendingAction.label : "Confirm"
                                    // High contrast pure white text normally, sharp black on solid hover
                                    color: confirmBtnMouse.containsMouse ? "#000000" : "#ffffff"
                                    font.pixelSize: Math.round(16 * powerMenuRoot.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: powerMenuRoot.pendingAction ? ("(" + powerMenuRoot.pendingAction.key + " / ↵)") : "(↵)"
                                    color: confirmBtnMouse.containsMouse ? "#000000" : "#ffffff"
                                    font.pixelSize: Math.round(13 * powerMenuRoot.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                    opacity: confirmBtnMouse.containsMouse ? 1.0 : 0.85
                                }
                            }

                            MouseArea {
                                id: confirmBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: powerMenuRoot.executePending()
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Micro Key Instruction
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: powerMenuRoot.pendingAction
                        ? ("esc to cancel  •  " + powerMenuRoot.pendingAction.key.toLowerCase() + " or enter to confirm")
                        : "esc to cancel  •  enter to confirm"
                    color: Theme.subtextDim
                    font.pixelSize: Math.round(12 * powerMenuRoot.uiScale)
                    font.family: Theme.fontFamily
                    opacity: 0.65
                }
            }
        }
    }
}
