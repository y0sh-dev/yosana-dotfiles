import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland

PanelWindow {
    id: powerMenuRoot
    property bool isOpen: false

    WlrLayershell.layer: WlrLayershell.Overlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: isOpen || bgDim.opacity > 0

    // 背景暗転
    Rectangle {
        id: bgDim
        anchors.fill: parent
        color: "#000000"
        opacity: powerMenuRoot.isOpen ? 0.65 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: powerMenuRoot.isOpen = false
        }
    }

    // 中央モーダル
    Rectangle {
        id: modal
        anchors.centerIn: parent
        width: 380
        height: 250
        radius: 16
        color: "#1a1b26"
        border.color: "#333333"
        border.width: 1

        scale: powerMenuRoot.isOpen ? 1.0 : 0.9
        opacity: powerMenuRoot.isOpen ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Power Options"
                color: "#7aa2f7"
                font.pixelSize: 18
                font.bold: true
                font.family: "FiraCode Nerd Font"
            }

            GridLayout {
                columns: 3
                rowSpacing: 14
                columnSpacing: 14
                Layout.alignment: Qt.AlignHCenter

                // Shutdown
                Rectangle {
                    width: 90
                    height: 50
                    radius: 8
                    color: btnShutdown.containsMouse ? "#f7768e" : "#24283b"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            color: btnShutdown.containsMouse ? "#1a1b26" : "#f7768e"
                            font.pixelSize: 18
                            font.family: "FiraCode Nerd Font"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Power Off"
                            color: btnShutdown.containsMouse ? "#1a1b26" : "#c0caf5"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: btnShutdown
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Process.exec(["systemctl", "poweroff"])
                        }
                    }
                }

                // Reboot
                Rectangle {
                    width: 90
                    height: 50
                    radius: 8
                    color: btnReboot.containsMouse ? "#e0af68" : "#24283b"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            color: btnReboot.containsMouse ? "#1a1b26" : "#e0af68"
                            font.pixelSize: 18
                            font.family: "FiraCode Nerd Font"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Reboot"
                            color: btnReboot.containsMouse ? "#1a1b26" : "#c0caf5"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: btnReboot
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Process.exec(["systemctl", "reboot"])
                        }
                    }
                }

                // Suspend
                Rectangle {
                    width: 90
                    height: 50
                    radius: 8
                    color: btnSuspend.containsMouse ? "#7aa2f7" : "#24283b"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰒲"
                            color: btnSuspend.containsMouse ? "#1a1b26" : "#7aa2f7"
                            font.pixelSize: 18
                            font.family: "FiraCode Nerd Font"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Sleep"
                            color: btnSuspend.containsMouse ? "#1a1b26" : "#c0caf5"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: btnSuspend
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Process.exec(["systemctl", "suspend"])
                        }
                    }
                }

                // Lock
                Rectangle {
                    width: 90
                    height: 50
                    radius: 8
                    color: btnLock.containsMouse ? "#bb9af7" : "#24283b"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            color: btnLock.containsMouse ? "#1a1b26" : "#bb9af7"
                            font.pixelSize: 18
                            font.family: "FiraCode Nerd Font"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Lock"
                            color: btnLock.containsMouse ? "#1a1b26" : "#c0caf5"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: btnLock
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Process.exec(["hyprlock"])
                        }
                    }
                }

                // Logout
                Rectangle {
                    width: 90
                    height: 50
                    radius: 8
                    color: btnLogout.containsMouse ? "#ff9e64" : "#24283b"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰍃"
                            color: btnLogout.containsMouse ? "#1a1b26" : "#ff9e64"
                            font.pixelSize: 18
                            font.family: "FiraCode Nerd Font"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Logout"
                            color: btnLogout.containsMouse ? "#1a1b26" : "#c0caf5"
                            font.pixelSize: 11
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
                    width: 90
                    height: 50
                    radius: 8
                    color: btnHibernate.containsMouse ? "#7dcfff" : "#24283b"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            color: btnHibernate.containsMouse ? "#1a1b26" : "#7dcfff"
                            font.pixelSize: 18
                            font.family: "FiraCode Nerd Font"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Hibernate"
                            color: btnHibernate.containsMouse ? "#1a1b26" : "#c0caf5"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: btnHibernate
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerMenuRoot.isOpen = false
                            Process.exec(["systemctl", "hibernate"])
                        }
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 100
                height: 28
                radius: 6
                color: btnCancel.containsMouse ? "#3b4261" : "transparent"
                border.color: "#565f89"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: "#a9b1d6"
                    font.pixelSize: 12
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
