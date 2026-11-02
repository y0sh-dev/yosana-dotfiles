import QtQuick
import Quickshell
import "../services"

Item {
    id: powerRoot
    implicitHeight: Theme.islandHeight
    implicitWidth: 32

    signal clicked()

    Rectangle {
        id: bgPill
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 14
        color: powerMouse.containsMouse ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.22) : "transparent"
        border.color: powerMouse.containsMouse ? Theme.urgent : "transparent"
        border.width: 1

        scale: powerMouse.pressed ? 0.90 : (powerMouse.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            color: powerMouse.containsMouse ? Theme.urgent : Theme.fg
            font.pixelSize: 18 // Icon size: 18px
            font.family: Theme.fontFamily
            Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
        }
    }

    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: powerRoot.clicked()
    }
}
