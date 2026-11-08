import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../services"

Item {
    id: mediaRoot

    // Primary player (Playing > First registered player)
    readonly property var activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    readonly property bool hasTrack: activePlayer && activePlayer.trackTitle && activePlayer.trackTitle.length > 0
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property string displayTitle: hasTrack ? (activePlayer.trackArtist ? (activePlayer.trackTitle + " • " + activePlayer.trackArtist) : activePlayer.trackTitle) : ""

    implicitHeight: Theme.islandHeight
    implicitWidth: pillContainer.implicitWidth + 12

    // Strict 2*PI radian continuous loop avoiding animation stutter
    property real animPhase: 0.0
    NumberAnimation on animPhase {
        from: 0.0
        to: Math.PI * 2
        duration: 2600
        loops: Animation.Infinite
    }

    Rectangle {
        id: pillContainer
        anchors.centerIn: parent
        implicitHeight: 28
        implicitWidth: contentRow.implicitWidth + 16
        radius: 14
        color: mediaMouse.containsMouse ? Theme.surfaceHover : "transparent"
        border.color: mediaMouse.containsMouse ? Theme.border : "transparent"
        border.width: 1

        scale: mediaMouse.pressed ? 0.94 : (mediaMouse.containsMouse ? 1.03 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 7

            // ================= 1. Active Track Mode =================
            Row {
                id: activeTrackRow
                visible: mediaRoot.hasTrack
                spacing: 7
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: mediaRoot.isPlaying ? "󰎈" : "󰏤"
                    color: Theme.accent
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter

                    scale: mediaRoot.isPlaying ? (1.0 + Math.sin(mediaRoot.animPhase * 2) * 0.08) : 1.0
                    Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
                }

                Text {
                    text: mediaRoot.displayTitle
                    color: Theme.fg
                    font.pixelSize: 16
                    font.bold: true
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 180)
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
                }
            }

            // ================= 2. Idle Mode (Static blinking dots + floating note) =================
            Row {
                id: idleRow
                visible: !mediaRoot.hasTrack
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                // Gently rocking headphone icon
                Text {
                    text: "󰋋"
                    color: Theme.accent
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter

                    transform: Rotation {
                        origin.x: 9; origin.y: 9
                        angle: Math.sin(mediaRoot.animPhase) * 6
                    }
                    Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
                }

                Text {
                    text: "Listening"
                    color: Theme.fg
                    opacity: 0.72 // TopBar-matching typography, slightly dimmed during standby
                    font.pixelSize: 16
                    font.bold: true
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
                }

                // Horizontally aligned blinking dots
                Repeater {
                    model: 3
                    delegate: Text {
                        text: "•"
                        font.pixelSize: 16
                        color: Theme.fg
                        anchors.verticalCenter: parent.verticalCenter

                        // Smooth pulsing opacity aligned with slightly dimmed standby theme
                        opacity: (0.30 + 0.60 * Math.max(0, Math.sin(mediaRoot.animPhase * 2 + index * 0.9))) * 0.72
                        Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
                    }
                }

                // Subtly floating musical note (2.0px stroke, 17px font)
                Text {
                    text: "🎶"
                    font.pixelSize: 17
                    anchors.verticalCenter: parent.verticalCenter

                    transform: [
                        Translate {
                            // Subtle 2.0px floating movement
                            y: Math.sin(mediaRoot.animPhase) * 2.0
                        },
                        Rotation {
                            origin.x: 8; origin.y: 8
                            angle: Math.cos(mediaRoot.animPhase) * 4
                        }
                    ]
                }
            }
        }
    }

    MouseArea {
        id: mediaMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (!mediaRoot.activePlayer) return;
            if (mouse.button === Qt.RightButton) {
                mediaRoot.activePlayer.next();
            } else {
                mediaRoot.activePlayer.togglePlaying();
            }
        }
    }
}
