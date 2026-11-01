import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: volumeRoot

    signal clicked()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0.0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    readonly property string icon: {
        if (volumeRoot.muted) return "󰖁"
        if (volumeRoot.volume <= 0.001) return "󰝟"
        if (volumeRoot.volume < 0.5) return "󰖀"
        return "󰕾"
    }

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 4

        Text {
            text: volumeRoot.icon
            color: volumeRoot.muted ? "#f7768e" : "#7aa2f7"
            font.pixelSize: 16
            font.family: "FiraCode Nerd Font"
        }

        Text {
            text: Math.round(volumeRoot.volume * 100) + "%"
            color: volumeRoot.muted ? "#565f89" : "#c0caf5"
            font.pixelSize: 13
            font.family: "FiraCode Nerd Font"
            Layout.minimumWidth: 36
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (volumeRoot.sink && volumeRoot.sink.audio) {
                    volumeRoot.sink.audio.muted = !volumeRoot.sink.audio.muted
                }
            } else {
                volumeRoot.clicked()
            }
        }

        onWheel: function(wheel) {
            if (!volumeRoot.sink || !volumeRoot.sink.audio) return
            var step = 0.02
            var current = volumeRoot.sink.audio.volume
            if (wheel.angleDelta.y > 0) {
                volumeRoot.sink.audio.volume = Math.min(1.0, current + step)
            } else if (wheel.angleDelta.y < 0) {
                volumeRoot.sink.audio.volume = Math.max(0.0, current - step)
            }
        }
    }
}
