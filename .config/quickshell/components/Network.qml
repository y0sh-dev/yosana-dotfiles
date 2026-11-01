import QtQuick
import Quickshell

Item {
    id: networkRoot
    implicitWidth: 26
    implicitHeight: 26

    signal clicked()

    property bool isConnected: true
    property string icon: isConnected ? "" : "󰤭"

    Text {
        anchors.centerIn: parent
        text: networkRoot.icon
        color: mouseArea.containsMouse ? "#7aa2f7" : (networkRoot.isConnected ? "#c0caf5" : "#565f89")
        font.pixelSize: 15
        font.family: "FiraCode Nerd Font"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: networkRoot.clicked()
    }
}
