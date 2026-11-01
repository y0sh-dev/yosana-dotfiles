import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Row {
    spacing: 8
    property int activeId: 0
    property var displayedList: []
    property var occupiedList: []

    Repeater {
        model: 9
        delegate: Rectangle {
            readonly property int wsId: index + 1
            readonly property bool isFocused: wsId === activeId
            readonly property bool isDisplayed: displayedList.indexOf(wsId) !== -1 && !isFocused
            readonly property bool isOccupied: occupiedList.indexOf(wsId) !== -1

            implicitWidth: isFocused ? 24 : 12
            implicitHeight: 12
            radius: 6
            
            color: isFocused ? "#ffffff" : (isDisplayed ? "#aaaaaa" : (isOccupied ? "#666666" : "#333333"))

            Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + wsId)
            }
        }
    }
}
