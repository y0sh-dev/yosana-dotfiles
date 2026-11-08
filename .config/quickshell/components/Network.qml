import QtQuick
import "../services"

Item {
    id: networkRoot
    implicitHeight: Theme.islandHeight
    implicitWidth: 32

    signal clicked()

    Rectangle {
        id: bgPill
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 14
        color: netMouse.containsMouse ? Theme.surfaceHover : "transparent"
        border.color: netMouse.containsMouse ? Theme.border : "transparent"
        border.width: 1

        scale: netMouse.pressed ? 0.90 : (netMouse.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: NetworkService.icon
            font.pixelSize: 16 // Icon size: 16px
            font.family: Theme.fontFamily
            color: NetworkService.isConnected ? Theme.fg : Theme.urgent
            Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
        }
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: networkRoot.clicked()
    }
}
