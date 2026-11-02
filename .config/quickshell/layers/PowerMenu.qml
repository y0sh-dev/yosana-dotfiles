import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import "../services"

PanelWindow {
    id: powerMenuRoot
    property bool isOpen: false
    screen: Quickshell.screens[0]

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

    // Dismiss modal on Escape key
    Shortcut {
        sequence: "Escape"
        enabled: powerMenuRoot.isOpen
        onActivated: powerMenuRoot.isOpen = false
    }

    // Backdrop dimming (semi-transparent for Hyprland blur)
    Rectangle {
        id: bgDim
        anchors.fill: parent
        color: "#000000"
        opacity: powerMenuRoot.isOpen ? 0.38 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: powerMenuRoot.isOpen = false
        }
    }

    // Central modal card (frosted glass look)
    Rectangle {
        id: modal
        anchors.centerIn: parent
        width: 520
        height: 380
        radius: 24
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.78)
        border.color: Theme.border
        border.width: 1

        scale: powerMenuRoot.isOpen ? 1.0 : 0.92
        opacity: powerMenuRoot.isOpen ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 24

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Power Options"
                color: Theme.accent
                font.pixelSize: 22
                font.bold: true
                font.family: Theme.fontFamily
            }

            GridLayout {
                columns: 3
                rowSpacing: 16
                columnSpacing: 16
                Layout.alignment: Qt.AlignHCenter

                // Shutdown
                Rectangle {
                    width: 140
                    height: 95
                    radius: 16
                    color: btnShutdown.containsMouse ? Theme.urgent : Theme.surface
                    border.color: btnShutdown.containsMouse ? Theme.urgent : Theme.border
                    border.width: 1
                    scale: btnShutdown.pressed ? 0.93 : (btnShutdown.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            color: btnShutdown.containsMouse ? Theme.bg : Theme.urgent
                            font.pixelSize: 32
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Power Off"
                            color: btnShutdown.containsMouse ? Theme.bg : Theme.fg
                            font.pixelSize: 14
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: btnShutdown
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Quickshell.execDetached(["systemctl", "poweroff"])
                        }
                    }
                }

                // Reboot
                Rectangle {
                    width: 140
                    height: 95
                    radius: 16
                    color: btnReboot.containsMouse ? Theme.accent : Theme.surface
                    border.color: btnReboot.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    scale: btnReboot.pressed ? 0.93 : (btnReboot.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            color: btnReboot.containsMouse ? Theme.bg : Theme.accent
                            font.pixelSize: 32
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Reboot"
                            color: btnReboot.containsMouse ? Theme.bg : Theme.fg
                            font.pixelSize: 14
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: btnReboot
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Quickshell.execDetached(["systemctl", "reboot"])
                        }
                    }
                }

                // Suspend
                Rectangle {
                    width: 140
                    height: 95
                    radius: 16
                    color: btnSuspend.containsMouse ? Theme.accent : Theme.surface
                    border.color: btnSuspend.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    scale: btnSuspend.pressed ? 0.93 : (btnSuspend.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰒲"
                            color: btnSuspend.containsMouse ? Theme.bg : Theme.accent
                            font.pixelSize: 32
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Sleep"
                            color: btnSuspend.containsMouse ? Theme.bg : Theme.fg
                            font.pixelSize: 14
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: btnSuspend
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Quickshell.execDetached(["systemctl", "suspend"])
                        }
                    }
                }

                // Lock
                Rectangle {
                    width: 140
                    height: 95
                    radius: 16
                    color: btnLock.containsMouse ? Theme.accent : Theme.surface
                    border.color: btnLock.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    scale: btnLock.pressed ? 0.93 : (btnLock.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            color: btnLock.containsMouse ? Theme.bg : Theme.accent
                            font.pixelSize: 32
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Lock"
                            color: btnLock.containsMouse ? Theme.bg : Theme.fg
                            font.pixelSize: 14
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: btnLock
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Quickshell.execDetached(["hyprlock"])
                        }
                    }
                }

                // Logout
                Rectangle {
                    width: 140
                    height: 95
                    radius: 16
                    color: btnLogout.containsMouse ? Theme.accent : Theme.surface
                    border.color: btnLogout.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    scale: btnLogout.pressed ? 0.93 : (btnLogout.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰍃"
                            color: btnLogout.containsMouse ? Theme.bg : Theme.accent
                            font.pixelSize: 32
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Logout"
                            color: btnLogout.containsMouse ? Theme.bg : Theme.fg
                            font.pixelSize: 14
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: btnLogout
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Hyprland.dispatch("exit")
                        }
                    }
                }

                // Hibernate
                Rectangle {
                    width: 140
                    height: 95
                    radius: 16
                    color: btnHibernate.containsMouse ? Theme.accent : Theme.surface
                    border.color: btnHibernate.containsMouse ? Theme.accent : Theme.border
                    border.width: 1
                    scale: btnHibernate.pressed ? 0.93 : (btnHibernate.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            color: btnHibernate.containsMouse ? Theme.bg : Theme.accent
                            font.pixelSize: 32
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Hibernate"
                            color: btnHibernate.containsMouse ? Theme.bg : Theme.fg
                            font.pixelSize: 14
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: btnHibernate
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Quickshell.execDetached(["systemctl", "hibernate"])
                        }
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 150
                height: 38
                radius: 12
                color: btnCancel.containsMouse ? Theme.surfaceHover : "transparent"
                border.color: Theme.border
                border.width: 1
                scale: btnCancel.pressed ? 0.94 : (btnCancel.containsMouse ? 1.03 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Theme.subtext
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: btnCancel
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerMenuRoot.isOpen = false
                }
            }
        }
    }
}
