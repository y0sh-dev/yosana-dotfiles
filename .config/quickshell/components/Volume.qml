import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../services"

Item {
    id: volumeRoot

    signal clicked()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0.0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    // Bind Pipewire node to enable volume and mute mutation
    PwObjectTracker {
        objects: volumeRoot.sink ? [volumeRoot.sink] : []
    }

    readonly property string icon: {
        if (volumeRoot.muted) return "󰖁"
        if (volumeRoot.volume <= 0.001) return "󰝟"
        if (volumeRoot.volume < 0.5) return "󰖀"
        return "󰕾"
    }

    implicitHeight: Theme.islandHeight
    implicitWidth: pillContainer.implicitWidth + 8

    Rectangle {
        id: pillContainer
        anchors.centerIn: parent
        implicitHeight: 28
        // Fixed layout width avoids horizontal jitter across percentage changes
        implicitWidth: 18 + 5 + 44 + 14 // icon(18) + spacing(5) + fixedText(44) + padding(14) = 81px
        radius: 14
        color: volMouse.containsMouse ? Theme.surfaceHover : "transparent"
        border.color: volMouse.containsMouse ? (volumeRoot.muted ? Theme.urgent : Theme.border) : "transparent"
        border.width: 1

        scale: volMouse.pressed ? 0.92 : (volMouse.containsMouse ? 1.04 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: volumeRoot.icon
                color: volumeRoot.muted ? Theme.urgent : Theme.accent
                font.pixelSize: 18 // Icon size: 18px
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
            }

            // Fixed-width text preventing horizontal shift
            Text {
                width: 44
                text: Math.round(volumeRoot.volume * 100) + "%"
                color: volumeRoot.muted ? Theme.urgent : Theme.fg
                font.pixelSize: 16 // Text size: 16px
                font.bold: true
                font.family: Theme.fontFamily
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }
            }
        }
    }

    MouseArea {
        id: volMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // Left Click: Open/Close AudioPanel, Right Click: Toggle Mute
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (volumeRoot.sink && volumeRoot.sink.audio) {
                    volumeRoot.sink.audio.muted = !volumeRoot.sink.audio.muted;
                }
            } else {
                volumeRoot.clicked();
            }
        }

        // Adjust volume on scroll (unmutes automatically)
        onWheel: function(wheel) {
            if (!volumeRoot.sink || !volumeRoot.sink.audio) return;
            var step = 0.02;
            var current = volumeRoot.sink.audio.volume;

            if (volumeRoot.sink.audio.muted) {
                volumeRoot.sink.audio.muted = false;
            }

            if (wheel.angleDelta.y > 0) {
                volumeRoot.sink.audio.volume = Math.min(1.0, current + step);
            } else if (wheel.angleDelta.y < 0) {
                volumeRoot.sink.audio.volume = Math.max(0.0, current - step);
            }
        }
    }
}
