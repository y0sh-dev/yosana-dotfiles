import QtQuick
import Quickshell.Hyprland
import "../services"

Row {
    id: wsRoot
    spacing: 6

    property int activeId: 0
    property var displayedList: []
    property var occupiedList: []

    // Height 16px, Golden ratio 1.618 (16 * 1.618 ≈ 25.89 -> 26px active width)
    readonly property real dotHeight: 16
    readonly property real dotWidth: 16
    readonly property real activeWidth: Math.round(dotHeight * 1.618) // 26px

    Repeater {
        model: 9
        delegate: Item {
            id: delegateRoot
            readonly property int wsId: index + 1
            readonly property bool isFocused: wsId === wsRoot.activeId
            readonly property bool isDisplayed: wsRoot.displayedList.indexOf(wsId) !== -1 && !isFocused
            readonly property bool isOccupied: wsRoot.occupiedList.indexOf(wsId) !== -1

            // Full island height as hitbox for effortless clicking
            implicitHeight: Theme.islandHeight
            implicitWidth: pill.implicitWidth + 4

            Rectangle {
                id: pill
                anchors.centerIn: parent

                implicitWidth: delegateRoot.isFocused ? wsRoot.activeWidth : wsRoot.dotWidth
                implicitHeight: wsRoot.dotHeight
                radius: wsRoot.dotHeight / 2

                color: {
                    if (delegateRoot.isFocused) return Theme.wsActive;
                    if (mouseArea.containsMouse) return Theme.fg;
                    if (delegateRoot.isDisplayed) return Theme.wsDisplayed;
                    if (delegateRoot.isOccupied) return Theme.wsOccupied;
                    return Theme.wsEmpty;
                }

                // Tactile feedback: Subtle scale on hover, press-down feel on click
                scale: mouseArea.pressed ? 0.90 : (mouseArea.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                Behavior on implicitWidth { 
                    NumberAnimation { 
                        duration: 220 
                        easing.type: Easing.OutCubic 
                    } 
                }
                Behavior on color { 
                    ColorAnimation { 
                        duration: Theme.animDuration
                        easing.type: Theme.animEasing
                    } 
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + delegateRoot.wsId + " })");
                }
            }
        }
    }
}
