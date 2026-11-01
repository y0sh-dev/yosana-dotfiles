import QtQuick

Text {
    property string displayTime: ""
    signal clicked()

    text: displayTime
    color: "#ffffff"
    font.pixelSize: 16
    font.family: "FiraCode Nerd Font"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.clicked()
    }
}
