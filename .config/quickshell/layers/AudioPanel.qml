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
    property string currentPage: "master" // "master" | "outputSinks" | "inputSources" | "appStreams" | "effects"
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

    // Monolithic fixed dimensions preserving the hardware instrument aesthetic (500x440)
    implicitWidth: Math.round(500 * Theme.uiScale)
    implicitHeight: Math.round(440 * Theme.uiScale)
    color: "transparent"

    visible: isOpen || mainContainer.opacity > 0

    Rectangle {
        id: mainContainer
        anchors.fill: parent
        radius: Math.round(18 * Theme.uiScale)
        color: Qt.rgba(0, 0, 0, 0.93)
        border.color: Theme.border
        border.width: 1

        opacity: audioPanelRoot.isOpen ? 1.0 : 0.0
        transform: Translate {
            y: audioPanelRoot.isOpen ? 0 : -8
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Content Area with strict margins
        Item {
            anchors.fill: parent
            anchors.margins: Math.round(20 * Theme.uiScale)

            // =================================================================
            // View Stack (Page Navigation)
            // =================================================================
            MasterView {
                id: masterView
                anchors.fill: parent
                visible: audioPanelRoot.currentPage === "master"
                defaultSink: audioPanelRoot.defaultSink
                defaultSource: audioPanelRoot.defaultSource
                overdriveUnlocked: audioPanelRoot.overdriveUnlocked
                isPanelOpen: audioPanelRoot.isOpen

                onSelectOutputRequested: audioPanelRoot.currentPage = "outputSinks"
                onSelectInputRequested: audioPanelRoot.currentPage = "inputSources"
                onAppStreamsRequested: audioPanelRoot.currentPage = "appStreams"
                onEffectsRequested: audioPanelRoot.currentPage = "effects"
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
                anchors.fill: parent
                visible: audioPanelRoot.currentPage === "outputSinks"
                title: "OUTPUT DEVICES"
                targetClass: "Audio/Sink"
                currentId: audioPanelRoot.defaultSink ? audioPanelRoot.defaultSink.id : -1
                onBackClicked: audioPanelRoot.currentPage = "master"
            }

            DeviceSelectorModal {
                anchors.fill: parent
                visible: audioPanelRoot.currentPage === "inputSources"
                title: "INPUT SOURCES"
                targetClass: "Audio/Source"
                currentId: audioPanelRoot.defaultSource ? audioPanelRoot.defaultSource.id : -1
                onBackClicked: audioPanelRoot.currentPage = "master"
            }

            AppStreamsModal {
                anchors.fill: parent
                visible: audioPanelRoot.currentPage === "appStreams"
                onBackClicked: audioPanelRoot.currentPage = "master"
            }

            EffectsModal {
                anchors.fill: parent
                visible: audioPanelRoot.currentPage === "effects"
                onBackClicked: audioPanelRoot.currentPage = "master"
            }
        }
    }
}
