import QtQuick
import Quickshell

Item {
    id: powerBtnRoot
    implicitWidth: 28
    implicitHeight: 28

    signal clicked()

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 14
        color: mouseArea.containsMouse ? "#f7768e" : "#24283b"
        opacity: mouseArea.containsMouse ? 0.3 : 0.8
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: "󰐥"
        color: mouseArea.containsMouse ? "#f7768e" : "#c0caf5"
        font.pixelSize: 15
        font.family: "FiraCode Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: powerBtnRoot.clicked()
    }
}
