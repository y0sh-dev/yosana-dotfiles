import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../services"
import "../modules/audio"

PanelWindow {
    id: audioPanelRoot

    property bool isOpen: false
    property string currentPage: "master" // "master" | "outputSinks" | "inputSources" | "appStreams"
    property bool overdriveUnlocked: false // Safety lock for >100% volume

    onIsOpenChanged: {
        if (!isOpen) {
            currentPage = "master";
        }
    }

    // PipeWire Defaults
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    // Object tracking for mutations (defaults and active application streams)
    PwObjectTracker {
        objects: {
            var list = [];
            if (audioPanelRoot.defaultSink) list.push(audioPanelRoot.defaultSink);
            if (audioPanelRoot.defaultSource) list.push(audioPanelRoot.defaultSource);
            var streamNodes = Pipewire.nodes.values.filter(n => n && n.isStream && n.audio);
            for (var i = 0; i < streamNodes.length; i++) {
                list.push(streamNodes[i]);
            }
            return list;
        }
    }

    WlrLayershell.namespace: "quickshell-audio"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: 54
        right: 14
    }

    // Generous width for supreme legibility on QHD (2560x1440)
    implicitWidth: 460
    implicitHeight: mainLayout.implicitHeight + 40
    color: "transparent"

    visible: isOpen || mainContainer.opacity > 0

    Rectangle {
        id: mainContainer
        anchors.fill: parent
        radius: Theme.radiusWindow || 16
        color: Qt.rgba(0, 0, 0, 0.93)
        border.color: Theme.border
        border.width: 1

        opacity: audioPanelRoot.isOpen ? 1.0 : 0.0
        transform: Translate {
            y: audioPanelRoot.isOpen ? 0 : -8
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: mainLayout
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }

            // =================================================================
            // View Stack (Page Navigation)
            // =================================================================
            MasterView {
                id: masterView
                Layout.fillWidth: true
                visible: audioPanelRoot.currentPage === "master"
                defaultSink: audioPanelRoot.defaultSink
                defaultSource: audioPanelRoot.defaultSource
                overdriveUnlocked: audioPanelRoot.overdriveUnlocked

                onSelectOutputRequested: audioPanelRoot.currentPage = "outputSinks"
                onSelectInputRequested: audioPanelRoot.currentPage = "inputSources"
                onAppStreamsRequested: audioPanelRoot.currentPage = "appStreams"
                onToggleOverdrive: {
                    audioPanelRoot.overdriveUnlocked = !audioPanelRoot.overdriveUnlocked;
                    if (!audioPanelRoot.overdriveUnlocked && audioPanelRoot.defaultSink && audioPanelRoot.defaultSink.audio) {
                        if (audioPanelRoot.defaultSink.audio.volume > 1.0) {
                            audioPanelRoot.defaultSink.audio.volume = 1.0;
                        }
                    }
                }
            }

            DeviceSelectorModal {
                Layout.fillWidth: true
                visible: audioPanelRoot.currentPage === "outputSinks"
                title: "OUTPUT DEVICES"
                targetClass: "Audio/Sink"
                currentId: audioPanelRoot.defaultSink ? audioPanelRoot.defaultSink.id : -1
                onBackClicked: audioPanelRoot.currentPage = "master"
            }

            DeviceSelectorModal {
                Layout.fillWidth: true
                visible: audioPanelRoot.currentPage === "inputSources"
                title: "INPUT SOURCES"
                targetClass: "Audio/Source"
                currentId: audioPanelRoot.defaultSource ? audioPanelRoot.defaultSource.id : -1
                onBackClicked: audioPanelRoot.currentPage = "master"
            }

            AppStreamsModal {
                Layout.fillWidth: true
                visible: audioPanelRoot.currentPage === "appStreams"
                onBackClicked: audioPanelRoot.currentPage = "master"
            }
        }
    }
}
