import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: volumePopupRoot
    property bool isOpen: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real currentVolume: sink && sink.audio ? sink.audio.volume : 0.0
    readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false
    readonly property string deviceName: sink ? (sink.description || sink.name || "Default Audio") : "No Sink Found"

    WlrLayershell.layer: WlrLayershell.Overlay

    anchors {
        top: true
        right: true
    }

    margins.top: 45
    margins.right: 15
    implicitWidth: 300
    implicitHeight: 120

    visible: isOpen || content.opacity > 0

    Rectangle {
        id: content
        anchors.fill: parent
        color: "#1a1b26"
        radius: 12
        border.color: "#333333"
        border.width: 1

        opacity: volumePopupRoot.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: volumePopupRoot.isMuted ? "󰖁" : "󰕾"
                    color: volumePopupRoot.isMuted ? "#f7768e" : "#7aa2f7"
                    font.pixelSize: 18
                    font.family: "FiraCode Nerd Font"
                }

                Text {
                    text: volumePopupRoot.deviceName
                    color: "#c0caf5"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: volumePopupRoot.isMuted ? "#f7768e" : "#24283b"

                    Text {
                        anchors.centerIn: parent
                        text: volumePopupRoot.isMuted ? "" : ""
                        color: volumePopupRoot.isMuted ? "#1a1b26" : "#7aa2f7"
                        font.pixelSize: 13
                        font.family: "FiraCode Nerd Font"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (volumePopupRoot.sink && volumePopupRoot.sink.audio) {
                                volumePopupRoot.sink.audio.muted = !volumePopupRoot.sink.audio.muted
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    from: 0.0
                    to: 1.0
                    value: volumePopupRoot.currentVolume

                    onMoved: {
                        if (volumePopupRoot.sink && volumePopupRoot.sink.audio) {
                            volumePopupRoot.sink.audio.volume = value
                        }
                    }
                }

                Text {
                    text: Math.round(volumePopupRoot.currentVolume * 100) + "%"
                    color: "#7aa2f7"
                    font.pixelSize: 13
                    font.bold: true
                    Layout.minimumWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
