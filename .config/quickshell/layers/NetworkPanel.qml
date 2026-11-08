import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../modules/network"

PanelWindow {
    id: networkPanelRoot

    property bool isOpen: false
    property string currentPage: "master" // "master" | "scanner" | "mesh" | "bluetooth"

    onIsOpenChanged: {
        if (!isOpen) {
            currentPage = "master";
        }
    }

    WlrLayershell.namespace: "quickshell-network"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        bottom: true
        right: true
    }

    margins {
        bottom: 14
        right: 14
    }

    // Monolithic high-end instrument dimensions.
    // Expanded for superior negative space, breathing room, and future Bluetooth integration.
    implicitWidth: Math.round(660 * Theme.uiScale)
    implicitHeight: Math.round(580 * Theme.uiScale)
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
            y: networkPanelRoot.isOpen ? 0 : 8
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Content Area with generous outer margins (24px) for supreme wabi-sabi breathing room
        Item {
            anchors.fill: parent
            anchors.margins: Math.round(24 * Theme.uiScale)

            // =================================================================
            // PAGE 1: MASTER VIEW (Top Page)
            // =================================================================
            MasterView {
                anchors.fill: parent
                visible: networkPanelRoot.currentPage === "master"

                onScanRequested: {
                    NetworkService.scan();
                    networkPanelRoot.currentPage = "scanner";
                }
                onMeshRequested: {
                    networkPanelRoot.currentPage = "mesh";
                }
                onBluetoothRequested: {
                    networkPanelRoot.currentPage = "bluetooth";
                }
            }

            // =================================================================
            // PAGE 2: AIRWAVE RECON (Wi-Fi Scanner Subpage)
            // =================================================================
            WifiScannerModal {
                anchors.fill: parent
                visible: networkPanelRoot.currentPage === "scanner"
                onBackClicked: networkPanelRoot.currentPage = "master"
            }

            // =================================================================
            // PAGE 3: MESH & ROUTING TELEMETRY (Subpage)
            // =================================================================
            MeshModal {
                anchors.fill: parent
                visible: networkPanelRoot.currentPage === "mesh"
                onBackClicked: networkPanelRoot.currentPage = "master"
            }
        }
    }
}
