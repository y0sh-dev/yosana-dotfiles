import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../services"
import "../../components"

// UPLINK deck — carrier identity, live telemetry, and compact jumps into the
// Mesh / Peripherals rails. Whole page scrolls internally; the window never
// changes size.
Flickable {
    id: uplinkRoot

    signal scanRequested()
    signal meshRequested()
    signal bluetoothRequested()

    contentWidth: width - 10
    contentHeight: contentLayout.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ModernScrollBar { targetFlickable: uplinkRoot }

    // ── Small reusable style helpers ────────────────────────────────
    ColumnLayout {
        id: contentLayout
        width: uplinkRoot.contentWidth
        spacing: Math.round(16 * Theme.uiScale)

        // ═════════════════════════════════════════════════════════════
        // CARD 1 — PRIMARY UPLINK
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: uplinkCol.implicitHeight + Math.round(44 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: uplinkCol
                anchors.fill: parent
                anchors.margins: Math.round(22 * Theme.uiScale)
                spacing: Math.round(15 * Theme.uiScale)

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: NetworkService.isConnected ? Theme.accent : Theme.urgent
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    MicroLabel { text: "PRIMARY UPLINK" }
                    Item { Layout.fillWidth: true }
                    GhostPill {
                        glyph: "󰤨"
                        label: "RECON AIRWAVE"
                        onTapped: uplinkRoot.scanRequested()
                    }
                }

                // Identity
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        text: NetworkService.icon
                        color: NetworkService.isConnected ? Theme.accent : Theme.subtextDim
                        font.pixelSize: Math.round(46 * Theme.uiScale)
                        font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 220 } }
                    }

                    Column {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: NetworkService.isConnected ? NetworkService.ssid : "No Carrier"
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(22 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: NetworkService.isConnected
                                  ? (NetworkService.band + "  ·  " + NetworkService.freq + "  ·  PHY " + NetworkService.phyRate)
                                  : "Uplink severed"
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(12 * Theme.uiScale)
                            font.family: Theme.fontFamily
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Sever / status affordance
                    Column {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        Text {
                            anchors.right: parent.right
                            text: NetworkService.isConnected ? "LINK NOMINAL" : "LINK DOWN"
                            color: NetworkService.isConnected ? Theme.accent : Theme.urgent
                            font.pixelSize: Math.round(10 * Theme.uiScale)
                            font.bold: true
                            font.letterSpacing: 1.2
                            font.family: Theme.fontFamily
                        }

                        Text {
                            id: severText
                            anchors.right: parent.right
                            visible: NetworkService.isConnected
                            text: "SEVER UPLINK"
                            color: severMouse.containsMouse ? Theme.urgent : Theme.subtextDim
                            font.pixelSize: Math.round(10 * Theme.uiScale)
                            font.bold: true
                            font.letterSpacing: 1.0
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 120 } }

                            MouseArea {
                                id: severMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetworkService.disconnectNetwork()
                            }
                        }
                    }
                }

                // Hairline
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(255, 255, 255, 0.06)
                }

                // Telemetry strip: IP · SIGNAL · LATENCY
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Column {
                        spacing: 5
                        MicroLabel { text: "IP ADDRESS" }
                        Text {
                            text: NetworkService.ip
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(14 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    Rectangle { width: 1; height: Math.round(28 * Theme.uiScale); color: Qt.rgba(255, 255, 255, 0.06) }

                    Column {
                        spacing: 5
                        MicroLabel { text: "SIGNAL" }
                        Row {
                            spacing: 8
                            Row {
                                id: sigRow
                                height: Math.round(18 * Theme.uiScale)
                                spacing: 3
                                Repeater {
                                    model: 5
                                    Rectangle {
                                        width: 3
                                        height: 5 + index * 3
                                        radius: 1
                                        y: sigRow.height - height
                                        color: ((index + 1) / 5.0) <= (NetworkService.signalQuality + 0.001)
                                               ? Theme.accent
                                               : Qt.rgba(255, 255, 255, 0.09)
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: NetworkService.isConnected ? (NetworkService.rssi + " dBm") : "—"
                                color: Theme.fgSoft
                                font.pixelSize: Math.round(13 * Theme.uiScale)
                                font.bold: true
                                font.family: Theme.fontFamily
                            }
                        }
                    }

                    Rectangle { width: 1; height: Math.round(28 * Theme.uiScale); color: Qt.rgba(255, 255, 255, 0.06) }

                    Column {
                        spacing: 5
                        MicroLabel { text: "ROUND TRIP" }
                        Text {
                            text: NetworkService.rtt
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(14 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Throughput ribbon (live receive histogram)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        MicroLabel { text: "THROUGHPUT" }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "▲ " + NetworkService.txRate + "    ▼ " + NetworkService.rxRate
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(11 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    Row {
                        id: sparkRow
                        height: Math.round(26 * Theme.uiScale)
                        spacing: 1
                        readonly property var hist: NetworkService.rxHistory
                        readonly property real maxV: {
                            var m = 1;
                            for (var i = 0; i < hist.length; i++) if (hist[i] > m) m = hist[i];
                            return m;
                        }
                        Repeater {
                            model: NetworkService.historyDepth
                            Rectangle {
                                width: 3
                                height: Math.max(2, 2 + ((sparkRow.hist[index] || 0) / sparkRow.maxV) * (sparkRow.height - 4))
                                y: sparkRow.height - height
                                radius: 1
                                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b,
                                               0.16 + 0.55 * (index / Math.max(1, NetworkService.historyDepth - 1)))
                            }
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════
        // CARD 2 — ENCRYPTED MESH (summary → MESH rail)
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: meshCol.implicitHeight + Math.round(40 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: meshCol
                anchors.fill: parent
                anchors.margins: Math.round(20 * Theme.uiScale)
                spacing: Math.round(13 * Theme.uiScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                    }
                    MicroLabel { text: "ENCRYPTED MESH" }
                    Item { Layout.fillWidth: true }
                    GhostPill {
                        glyph: "󰒃"
                        label: "ROUTING DETAILS"
                        onTapped: uplinkRoot.meshRequested()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        text: "󰖂"
                        color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                        font.pixelSize: Math.round(20 * Theme.uiScale)
                        font.family: Theme.fontFamily
                    }
                    Column {
                        spacing: 2
                        Text {
                            text: "Tailscale WireGuard"
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: NetworkService.tailscaleActive
                                  ? ("Mesh " + NetworkService.tailscaleIp + " · MagicDNS")
                                  : "Tunnel offline"
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(11 * Theme.uiScale)
                            font.family: Theme.fontFamily
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: NetworkService.tailscaleActive ? "ACTIVE" : "OFF"
                        color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                        font.pixelSize: Math.round(10 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        text: "󰒃"
                        color: Theme.accent
                        font.pixelSize: Math.round(20 * Theme.uiScale)
                        font.family: Theme.fontFamily
                    }
                    Column {
                        spacing: 2
                        Text {
                            text: "Zero-Trust DNS & Shaping"
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: NetworkService.dnsStatus + " · CAKE " + NetworkService.cakeStatus
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(11 * Theme.uiScale)
                            font.family: Theme.fontFamily
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "PROTECTED"
                        color: Theme.accent
                        font.pixelSize: Math.round(10 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════
        // CARD 3 — WIRELESS PERIPHERALS (summary → PERIPHERALS rail)
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: periphCol.implicitHeight + Math.round(40 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: periphCol
                anchors.fill: parent
                anchors.margins: Math.round(20 * Theme.uiScale)
                spacing: Math.round(13 * Theme.uiScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: BluetoothService.isPowered ? Theme.accent : Theme.subtextDim
                    }
                    MicroLabel { text: "WIRELESS PERIPHERALS" }
                    Item { Layout.fillWidth: true }
                    GhostPill {
                        glyph: "󰂯"
                        label: "MANAGE"
                        onTapped: uplinkRoot.bluetoothRequested()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        text: "󰂯"
                        color: BluetoothService.isPowered ? Theme.accent : Theme.subtextDim
                        font.pixelSize: Math.round(20 * Theme.uiScale)
                        font.family: Theme.fontFamily
                    }
                    Column {
                        spacing: 2
                        Text {
                            text: BluetoothService.isPowered ? "Bluetooth Controller" : "Radio Powered Down"
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: !BluetoothService.isPowered
                                  ? "No active radio"
                                  : (BluetoothService.activeDevice
                                     ? (BluetoothService.activeDevice.name + " · linked")
                                     : (BluetoothService.devices.length + " paired · none linked"))
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(11 * Theme.uiScale)
                            font.family: Theme.fontFamily
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: BluetoothService.isPowered ? "ONLINE" : "OFFLINE"
                        color: BluetoothService.isPowered ? Theme.accent : Theme.subtextDim
                        font.pixelSize: Math.round(10 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }
            }
        }

        // Bottom breathing room
        Item { Layout.fillWidth: true; Layout.preferredHeight: Math.round(4 * Theme.uiScale) }
    }
}
