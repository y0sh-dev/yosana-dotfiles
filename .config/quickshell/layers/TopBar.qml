import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

PanelWindow {
    id: barRoot

    property int focusedWs: 0
    property var displayedWs: []
    property var occupiedWs: []
    property string timeText: ""

    signal archClicked()
    signal menuClicked()
    signal clockClicked()
    signal networkClicked()
    signal powerClicked()

    WlrLayershell.layer: WlrLayer.Top
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    margins {
        top: 4
        left: 14
        right: 14
    }

    implicitHeight: 48
    exclusiveZone: 41
    color: "transparent"

    Item {
        anchors.fill: parent

        // ================= Island 1 (Left): Arch Linux Logo Island =================
        Rectangle {
            id: archIsland
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.islandHeight
            height: Theme.islandHeight
            radius: Theme.radiusIsland
            color: archMouse.containsMouse ? Theme.surfaceHover : Theme.bgIsland
            border.width: 0

            scale: archMouse.pressed ? 0.90 : (archMouse.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰣇"
                font.pixelSize: 20
                font.family: Theme.fontFamily
                color: archMouse.containsMouse ? Theme.accent : Theme.fg
                Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
            }

            MouseArea {
                id: archMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: barRoot.archClicked()
            }
        }

        // ================= Island 2 (Left): Workspaces Island =================
        Rectangle {
            id: wsIsland
            anchors.left: archIsland.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: Theme.islandHeight
            implicitWidth: wsContent.implicitWidth + (Theme.islandPaddingH * 2)
            radius: Theme.radiusIsland
            color: Theme.bgIsland
            border.width: 0

            Row {
                id: wsContent
                anchors.centerIn: parent
                Workspaces {
                    activeId: barRoot.focusedWs
                    displayedList: barRoot.displayedWs
                    occupiedList: barRoot.occupiedWs
                }
            }
        }

        // ================= Island 3 (Center): Clock Island (Absolute Screen Center) =================
        Rectangle {
            id: clockIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: Theme.islandHeight
            implicitWidth: clockContent.implicitWidth + (Theme.islandPaddingH * 2)
            radius: Theme.radiusIsland
            color: clockMouse.containsMouse ? Theme.surfaceHover : Theme.bgIsland
            border.width: 0

            scale: clockMouse.pressed ? 0.94 : (clockMouse.containsMouse ? 1.04 : 1.0)
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                id: clockContent
                anchors.centerIn: parent
                Clock {
                    displayTime: barRoot.timeText
                }
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: barRoot.clockClicked()
            }
        }

        // ================= Island 4 (Center Right): Main Control / Menu Shortcut Island =================
        Rectangle {
            id: menuIsland
            anchors.left: clockIsland.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.islandHeight
            height: Theme.islandHeight
            radius: Theme.radiusIsland
            color: menuMouse.containsMouse ? Theme.surfaceHover : Theme.bgIsland
            border.width: 0

            scale: menuMouse.pressed ? 0.90 : (menuMouse.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󱗼"
                font.pixelSize: 19
                font.family: Theme.fontFamily
                color: menuMouse.containsMouse ? Theme.accent : Theme.fg
                Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
            }

            MouseArea {
                id: menuMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: barRoot.menuClicked()
            }
        }

        // ================= Island 5 (Right): Media & System Island =================
        Rectangle {
            id: sysIsland
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: Theme.islandHeight
            implicitWidth: sysContent.implicitWidth + 28
            radius: Theme.radiusIsland
            color: Theme.bgIsland
            border.width: 0

            Row {
                id: sysContent
                anchors.centerIn: parent
                spacing: 8

                // Media player with idle float animation
                MediaPill {}

                // Subtle vertical separator
                Rectangle {
                    width: 1
                    height: 16
                    color: Theme.border
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.8
                }

                // System control widgets
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    // SwayNC Notification Indicator (Left of volume)
                    Notification {}

                    Volume {}

                    Network {
                        onClicked: barRoot.networkClicked()
                    }

                    PowerButton {
                        onClicked: barRoot.powerClicked()
                    }
                }
            }
        }
    }
}
