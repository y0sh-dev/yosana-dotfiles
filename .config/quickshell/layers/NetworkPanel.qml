import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../modules/network"

// ─────────────────────────────────────────────────────────────────────────
// NETWORK TERMINAL
// A monolithic bottom-right instrument. Three persistent rails
// (UPLINK / PERIPHERALS / MESH) plus a transient RECON page. The outer
// window never resizes; every page scrolls internally.
// ─────────────────────────────────────────────────────────────────────────
PanelWindow {
    id: networkPanelRoot

    property bool isOpen: false
    // "uplink" | "recon" | "peripherals" | "mesh"
    property string mode: "uplink"

    onIsOpenChanged: {
        BluetoothService.active = isOpen;
        if (!isOpen) {
            mode = "uplink";
        } else if (mode === "peripherals") {
            BluetoothService.refresh();
        }
    }

    onModeChanged: {
        if (mode === "peripherals") BluetoothService.refresh();
    }

    WlrLayershell.namespace: "quickshell-network"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    // Only RECON needs keyboard input (the inline passphrase field); every
    // other page stays hands-off so the panel never steals focus.
    WlrLayershell.keyboardFocus: networkPanelRoot.mode === "recon"
                                 ? WlrKeyboardFocus.OnDemand
                                 : WlrKeyboardFocus.None

    anchors {
        bottom: true
        right: true
    }

    margins {
        bottom: 14
        right: 14
    }

    // Fixed instrument dimensions. Height is locked so sub-views never jump.
    implicitWidth: Math.round(680 * Theme.uiScale)
    implicitHeight: Math.round(600 * Theme.uiScale)
    color: "transparent"

    visible: isOpen || mainContainer.opacity > 0

    Rectangle {
        id: mainContainer
        anchors.fill: parent
        radius: Math.round(18 * Theme.uiScale)
        color: Qt.rgba(0, 0, 0, 0.93)
        border.color: Theme.border
        border.width: 1

        opacity: networkPanelRoot.isOpen ? 1.0 : 0.0
        transform: Translate {
            y: networkPanelRoot.isOpen ? 0 : 10
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(24 * Theme.uiScale)
            spacing: Math.round(16 * Theme.uiScale)

            // ═══════════════════════════════════════════════════════════
            // HEADER RAIL
            // ═══════════════════════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(26 * Theme.uiScale)

                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: NetworkService.isConnected ? Theme.accent : Theme.urgent
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Text {
                        text: "NETWORK TERMINAL"
                        color: Theme.subtextDim
                        font.pixelSize: Math.round(10 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.8
                        font.family: Theme.fontFamily
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.round(20 * Theme.uiScale)

                    Repeater {
                        model: [
                            { id: "uplink", label: "UPLINK" },
                            { id: "peripherals", label: "PERIPHERALS" },
                            { id: "mesh", label: "MESH" }
                        ]

                        delegate: Item {
                            id: railItem
                            width: railLabel.implicitWidth + 6
                            height: Math.round(24 * Theme.uiScale)

                            readonly property bool isActive: networkPanelRoot.mode === modelData.id
                                || (modelData.id === "uplink" && networkPanelRoot.mode === "recon")

                            Text {
                                id: railLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: railItem.isActive
                                       ? Theme.fgSoft
                                       : (railMouse.containsMouse ? Theme.subtext : Theme.subtextDim)
                                font.pixelSize: Math.round(11 * Theme.uiScale)
                                font.bold: true
                                font.letterSpacing: 1.2
                                font.family: Theme.fontFamily
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Theme.accent
                                opacity: railItem.isActive ? 0.9 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: railMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: networkPanelRoot.mode = modelData.id
                            }
                        }
                    }
                }
            }

            // Hairline under the rail
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(255, 255, 255, 0.06)
            }

            // ═══════════════════════════════════════════════════════════
            // PAGE STACK (fixed height, internal scroll per page)
            // ═══════════════════════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                MasterView {
                    anchors.fill: parent
                    opacity: networkPanelRoot.mode === "uplink" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    enabled: opacity > 0.5
                    Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                    onScanRequested: {
                        NetworkService.scan();
                        networkPanelRoot.mode = "recon";
                    }
                    onMeshRequested: networkPanelRoot.mode = "mesh"
                    onBluetoothRequested: networkPanelRoot.mode = "peripherals"
                }

                WifiScannerModal {
                    anchors.fill: parent
                    opacity: networkPanelRoot.mode === "recon" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    enabled: opacity > 0.5
                    Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                    onBackClicked: networkPanelRoot.mode = "uplink"
                }

                BluetoothModal {
                    anchors.fill: parent
                    opacity: networkPanelRoot.mode === "peripherals" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    enabled: opacity > 0.5
                    Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                }

                MeshModal {
                    anchors.fill: parent
                    opacity: networkPanelRoot.mode === "mesh" ? 1.0 : 0.0
                    visible: opacity > 0.01
                    enabled: opacity > 0.5
                    Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
