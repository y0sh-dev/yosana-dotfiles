import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../services"
import "../../components"

// PERIPHERALS deck — full Bluetooth control surface:
//   Controller power · paired peripherals · discovery & onboarding.
// Everything is inline; the fixed window never resizes.
Flickable {
    id: btRoot

    property string busyMac: ""
    property var busyTimer: Timer {
        interval: 4200
        repeat: false
        onTriggered: btRoot.busyMac = ""
    }

    contentWidth: width - 10
    contentHeight: contentLayout.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ModernScrollBar { targetFlickable: btRoot }

    function act(mac, kind) {
        busyMac = mac;
        busyTimer.restart();
        if (kind === "connect") BluetoothService.connectDevice(mac);
        else if (kind === "disconnect") BluetoothService.disconnectDevice(mac);
        else if (kind === "adopt") BluetoothService.adoptDevice(mac);
        else if (kind === "remove") BluetoothService.removeDevice(mac);
    }

    // Small signal meter bars
    ColumnLayout {
        id: contentLayout
        width: btRoot.contentWidth
        spacing: Math.round(16 * Theme.uiScale)

        // ═════════════════════════════════════════════════════════════
        // CONTROLLER
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: ctrlCol.implicitHeight + Math.round(40 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: ctrlCol
                anchors.fill: parent
                anchors.margins: Math.round(20 * Theme.uiScale)
                spacing: Math.round(14 * Theme.uiScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: BluetoothService.isPowered ? Theme.accent : Theme.subtextDim
                    }
                    MicroLabel { text: "CONTROLLER" }
                    Item { Layout.fillWidth: true }
                    GhostPill {
                        label: BluetoothService.isPowered ? "POWERED" : "DOWN"
                        glyph: "󰂯"
                        onTapped: BluetoothService.togglePower()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        text: "󰂯"
                        color: BluetoothService.isPowered ? Theme.accent : Theme.subtextDim
                        font.pixelSize: Math.round(40 * Theme.uiScale)
                        font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Column {
                        spacing: 3
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            text: BluetoothService.controllerName.length > 0
                                  ? BluetoothService.controllerName
                                  : "Bluetooth Adapter"
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(18 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: (BluetoothService.controllerMac.length > 0 ? BluetoothService.controllerMac + "  ·  " : "")
                                  + (BluetoothService.isPowered
                                     ? (BluetoothService.isDiscovering ? "DISCOVERING" : "READY")
                                     : "RADIO OFFLINE")
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(11 * Theme.uiScale)
                            font.family: Theme.fontFamily
                        }
                    }

                    Item { Layout.fillWidth: true }

                    GhostPill {
                        label: BluetoothService.isScanning ? "SCANNING…" : "SCAN BEACONS"
                        glyph: "󰑐"
                        dim: !BluetoothService.isPowered || BluetoothService.isScanning
                        onTapped: BluetoothService.scan()
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════
        // PAIRED PERIPHERALS
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pairedCol.implicitHeight + Math.round(40 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: pairedCol
                anchors.fill: parent
                anchors.margins: Math.round(20 * Theme.uiScale)
                spacing: Math.round(10 * Theme.uiScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    MicroLabel { text: "PAIRED PERIPHERALS" }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: BluetoothService.connectedCount + " / " + BluetoothService.devices.length + " LINKED"
                        color: Theme.subtextDim
                        font.pixelSize: Math.round(10 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }

                // Empty state
                Item {
                    visible: BluetoothService.devices.length === 0
                    Layout.fillWidth: true
                    implicitHeight: Math.round(78 * Theme.uiScale)
                    Text {
                        anchors.centerIn: parent
                        text: BluetoothService.isPowered ? "No paired peripherals" : "Radio offline"
                        color: Theme.subtextDim
                        font.pixelSize: Math.round(13 * Theme.uiScale)
                        font.family: Theme.fontFamily
                    }
                }

                Repeater {
                    model: BluetoothService.devices
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.round(62 * Theme.uiScale)
                        radius: Math.round(12 * Theme.uiScale)

                        readonly property bool linked: modelData.connected
                        readonly property bool busy: btRoot.busyMac === modelData.mac

                        color: linked
                               ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
                               : (rowHover.hovered ? Theme.surfaceHover : "transparent")
                        border.color: linked ? Theme.accent : (rowHover.hovered ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.05))
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: rowHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(16 * Theme.uiScale)
                            anchors.rightMargin: Math.round(16 * Theme.uiScale)
                            spacing: 14

                            Text {
                                text: BluetoothService.glyphFor(modelData.type)
                                color: linked ? Theme.accent : Theme.fgSoft
                                font.pixelSize: Math.round(24 * Theme.uiScale)
                                font.family: Theme.fontFamily
                            }

                            Column {
                                spacing: 3
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.name
                                    color: linked ? Theme.fg : Theme.fgSoft
                                    font.pixelSize: Math.round(15 * Theme.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Row {
                                    spacing: 8
                                    Text {
                                        text: modelData.mac
                                        color: Theme.subtextDim
                                        font.pixelSize: Math.round(10 * Theme.uiScale)
                                        font.family: Theme.fontFamily
                                    }
                                    Text {
                                        visible: modelData.type !== "generic"
                                        text: "· " + (modelData.type || "generic").toUpperCase()
                                        color: Theme.subtextDim
                                        font.pixelSize: Math.round(10 * Theme.uiScale)
                                        font.letterSpacing: 0.8
                                        font.family: Theme.fontFamily
                                    }
                                    Text {
                                        visible: modelData.trusted === true
                                        text: "· TRUSTED"
                                        color: Theme.subtextDim
                                        font.pixelSize: Math.round(10 * Theme.uiScale)
                                        font.letterSpacing: 0.8
                                        font.family: Theme.fontFamily
                                    }
                                }
                            }

                            // Battery
                            Row {
                                visible: modelData.battery !== null && modelData.battery !== undefined
                                spacing: 6
                                Rectangle {
                                    width: 26; height: 10; radius: 2
                                    color: "transparent"
                                    border.color: Qt.rgba(255, 255, 255, 0.15)
                                    border.width: 1
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(1, (parent.width - 4) * ((modelData.battery || 0) / 100.0))
                                        height: parent.height - 4
                                        radius: 1
                                        color: (modelData.battery || 0) > 20 ? Theme.accent : Theme.urgent
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (modelData.battery !== null && modelData.battery !== undefined ? modelData.battery : "--") + "%"
                                    color: Theme.subtextDim
                                    font.pixelSize: Math.round(10 * Theme.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                }
                            }

                            // Signal
                            Row {
                                visible: modelData.rssi !== null && modelData.rssi !== undefined
                                spacing: 6
                                SignalBars {
                                    height: Math.round(14 * Theme.uiScale)
                                    rssi: modelData.rssi || -100
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (modelData.rssi || 0) + " dBm"
                                    color: Theme.subtextDim
                                    font.pixelSize: Math.round(10 * Theme.uiScale)
                                    font.family: Theme.fontFamily
                                }
                            }

                            GhostPill {
                                label: busy ? "WORKING…" : (linked ? "DISCONNECT" : "CONNECT")
                                dim: busy
                                onTapped: btRoot.act(modelData.mac, linked ? "disconnect" : "connect")
                            }
                        }

                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════
        // DISCOVERY (only once a scan has run or is running)
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            visible: BluetoothService.isScanning || BluetoothService.newBeacons.length > 0
            implicitHeight: discCol.implicitHeight + Math.round(40 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: discCol
                anchors.fill: parent
                anchors.margins: Math.round(20 * Theme.uiScale)
                spacing: Math.round(10 * Theme.uiScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: Theme.accent
                    }
                    MicroLabel { text: "DISCOVERY" }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: BluetoothService.isScanning
                              ? "PROBING AIRWAVE…"
                              : (BluetoothService.newBeacons.length + " BEACONS")
                        color: Theme.subtextDim
                        font.pixelSize: Math.round(10 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: Theme.fontFamily
                    }
                }

                Item {
                    visible: !BluetoothService.isScanning && BluetoothService.newBeacons.length === 0
                    Layout.fillWidth: true
                    implicitHeight: Math.round(40 * Theme.uiScale)
                    Text {
                        anchors.centerIn: parent
                        text: "No unpaired beacons in range"
                        color: Theme.subtextDim
                        font.pixelSize: Math.round(12 * Theme.uiScale)
                        font.family: Theme.fontFamily
                    }
                }

                Repeater {
                    model: BluetoothService.newBeacons
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.round(54 * Theme.uiScale)
                        radius: Math.round(12 * Theme.uiScale)
                        color: beaconHover.hovered ? Theme.surfaceHover : "transparent"
                        border.color: beaconHover.hovered ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: beaconHover }

                        readonly property bool busy: btRoot.busyMac === modelData.mac

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(16 * Theme.uiScale)
                            anchors.rightMargin: Math.round(16 * Theme.uiScale)
                            spacing: 14

                            Text {
                                text: BluetoothService.glyphFor(modelData.type)
                                color: Theme.fgSoft
                                font.pixelSize: Math.round(20 * Theme.uiScale)
                                font.family: Theme.fontFamily
                            }

                            Column {
                                spacing: 2
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.name
                                    color: Theme.fgSoft
                                    font.pixelSize: Math.round(14 * Theme.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: modelData.mac + (modelData.rssi !== null && modelData.rssi !== undefined ? ("  ·  " + modelData.rssi + " dBm") : "")
                                    color: Theme.subtextDim
                                    font.pixelSize: Math.round(10 * Theme.uiScale)
                                    font.family: Theme.fontFamily
                                }
                            }

                            GhostPill {
                                label: busy ? "PAIRING…" : "PAIR & TRUST"
                                glyph: "󰄬"
                                dim: busy
                                onTapped: btRoot.act(modelData.mac, "adopt")
                            }
                        }

                    }
                }
            }
        }

        Item { Layout.fillWidth: true; Layout.preferredHeight: Math.round(4 * Theme.uiScale) }
    }
}
