import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../services"

ColumnLayout {
    id: appStreamsRoot

    signal backClicked()

    spacing: 14

    // Strict filter for audio playback streams (filters out microphone capture streams)
    function isPlaybackStream(n) {
        if (!n || !n.isStream || !n.audio) return false;
        var tStr = PwNodeType.toString(n.type);
        if (tStr.indexOf("InStream") !== -1 || tStr.indexOf("Source") !== -1) return false;
        var props = n.properties || {};
        if (props["media.class"] === "Stream/Input/Audio") return false;
        return true;
    }

    // Deduplicated list of active application streams (one card per app)
    readonly property var uniqueStreams: {
        var rawList = Pipewire.nodes.values.filter(appStreamsRoot.isPlaybackStream);
        var appMap = {};
        var result = [];
        for (var i = 0; i < rawList.length; i++) {
            var node = rawList[i];
            var props = node.properties || {};
            var appKey = props["application.name"] || props["application.process.binary"] || node.description || node.name || ("app_" + node.id);
            if (!appMap[appKey]) {
                appMap[appKey] = true;
                result.push(node);
            }
        }
        return result;
    }

    // Top-level tracker to bind all candidate stream nodes
    PwObjectTracker {
        objects: appStreamsRoot.uniqueStreams
    }

    // =========================================================================
    // Header: Back button + Title
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            implicitWidth: 84
            implicitHeight: 32
            radius: 8
            color: backMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            border.color: backMouse.containsMouse ? Theme.accent : Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "‹"
                    color: backMouse.containsMouse ? Theme.accent : Theme.fg
                    font.pixelSize: 15
                    font.bold: true
                    font.family: Theme.fontFamily
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "Back"
                    color: backMouse.containsMouse ? Theme.accent : Theme.fgSoft
                    font.pixelSize: 13
                    font.bold: true
                    font.family: Theme.fontFamily
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: appStreamsRoot.backClicked()
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "APPLICATION STREAMS"
            color: Theme.fg
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 1.2
            font.family: Theme.fontFamily
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.border
        opacity: 0.4
    }

    // =========================================================================
    // Active Streams List
    // =========================================================================
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        Repeater {
            model: appStreamsRoot.uniqueStreams

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 74
                radius: 12
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                readonly property real streamVol: modelData.audio ? modelData.audio.volume : 0.0
                readonly property bool streamMuted: modelData.audio ? modelData.audio.muted : false
                readonly property string appName: {
                    var p = modelData.properties || {};
                    return p["application.name"] || modelData.description || modelData.name || ("App #" + modelData.id);
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Application Icon / Badge
                        Text {
                            text: "󰎆"
                            color: streamMuted ? Theme.subtextDim : Theme.accent
                            font.pixelSize: 16
                            font.family: Theme.fontFamily
                        }

                        // Application Name (Clear 15px Bold)
                        Text {
                            text: appName
                            color: Theme.fg
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Volume Percentage (15px Bold)
                        Text {
                            text: Math.round(streamVol * 100) + "%"
                            color: streamMuted ? Theme.urgent : Theme.fgSoft
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        // App mute toggle
                        Rectangle {
                            implicitWidth: 30
                            implicitHeight: 26
                            radius: 6
                            color: streamMuted ? Theme.urgent : (appMuteMouse.containsMouse ? Theme.surfaceHover : "transparent")
                            border.color: appMuteMouse.containsMouse ? Theme.border : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: streamMuted ? "󰖁" : "󰕾"
                                color: streamMuted ? Theme.bgDark : (appMuteMouse.containsMouse ? Theme.accent : Theme.fgSoft)
                                font.pixelSize: 14
                                font.family: Theme.fontFamily
                            }

                            MouseArea {
                                id: appMuteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.audio) {
                                        modelData.audio.muted = !modelData.audio.muted;
                                    }
                                }
                            }
                        }
                    }

                    ModernSlider {
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        value: streamVol
                        isMuted: streamMuted
                        onMoved: (val) => {
                            if (modelData.audio) {
                                modelData.audio.volume = val;
                            }
                        }
                    }
                }
            }
        }

        // Empty state
        Rectangle {
            visible: appStreamsRoot.uniqueStreams.length === 0
            Layout.fillWidth: true
            implicitHeight: 90
            radius: 12
            color: Theme.surface
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "󰝟"
                    color: Theme.subtextDim
                    font.pixelSize: 24
                    font.family: Theme.fontFamily
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "No active application audio streams"
                    color: Theme.subtextDim
                    font.pixelSize: 14
                    font.family: Theme.fontFamily
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
