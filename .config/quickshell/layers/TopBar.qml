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

    signal clockClicked()
    signal networkClicked()
    signal powerClicked()

    WlrLayershell.layer: WlrLayershell.Top
    
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

        // ================= Left: Workspaces Island =================
        Rectangle {
            id: wsIsland
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: Theme.islandHeight
            implicitWidth: wsContent.implicitWidth + (Theme.islandPaddingH * 2)
            radius: Theme.radiusIsland
            color: Theme.bgIsland
            border.color: Theme.border
            border.width: 1

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

        // ================= Center: Clock Island (Absolute screen center) =================
        Rectangle {
            id: clockIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: Theme.islandHeight
            implicitWidth: clockContent.implicitWidth + (Theme.islandPaddingH * 2)
            radius: Theme.radiusIsland
            color: clockMouse.containsMouse ? Theme.surfaceHover : Theme.bgIsland
            border.color: Theme.border
            border.width: 1

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
        
        // ================= Right: Media & System Island =================
        Rectangle {
            id: sysIsland
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: Theme.islandHeight
            implicitWidth: sysContent.implicitWidth + 28
            radius: Theme.radiusIsland
            color: Theme.bgIsland
            border.color: Theme.border
            border.width: 1

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
