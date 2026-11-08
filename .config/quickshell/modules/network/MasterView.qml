import QtQuick
import QtQuick.Layouts
import "../../services"

ColumnLayout {
    id: masterViewRoot

    signal scanRequested()
    signal meshRequested()
    signal bluetoothRequested()

    spacing: Math.round(14 * Theme.uiScale)

    // =========================================================================
    // CARD 1: PRIMARY UPLINK & CARRIER (Surface Container)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(200 * Theme.uiScale)
        radius: Math.round(16 * Theme.uiScale)
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(20 * Theme.uiScale)
            spacing: Math.round(14 * Theme.uiScale)

            // Header: Category Indicator + Airwave Scan Button Pill
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: NetworkService.isConnected ? Theme.accent : Theme.urgent
                    }
                    Text {
                        text: "PRIMARY UPLINK"
                        color: Theme.subtextDim
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.1
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }

                // Airwave Recon / Wi-Fi Scanner Pill Button: [ 󰤨 SSID › ]
                Rectangle {
                    implicitHeight: Math.round(30 * Theme.uiScale)
                    implicitWidth: ssidPillLayout.implicitWidth + 24
                    radius: height / 2
                    color: ssidPillMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.45)
                    border.color: ssidPillMouse.containsMouse ? Theme.accent : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    scale: ssidPillMouse.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: ssidPillLayout
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: NetworkService.icon
                            color: ssidPillMouse.containsMouse ? Theme.accent : Theme.fgSoft
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: NetworkService.isConnected ? NetworkService.ssid : "No Carrier"
                            color: ssidPillMouse.containsMouse ? Theme.fg : Theme.fgSoft
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.maximumWidth: Math.round(240 * Theme.uiScale)
                        }

                        Text {
                            text: "›"
                            color: ssidPillMouse.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: ssidPillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: masterViewRoot.scanRequested()
                    }
                }
            }

            // Specs & Identity: Large Carrier Glyph + SSID + Frequency
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(16 * Theme.uiScale)

                Text {
                    text: NetworkService.icon
                    color: Theme.accent
                    font.pixelSize: Math.round(48 * Theme.uiScale)
                    font.family: Theme.fontFamily
                    Layout.alignment: Qt.AlignVCenter
                }

                Column {
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: NetworkService.isConnected ? NetworkService.ssid : "Disconnected"
                        color: Theme.fgSoft
                        font.pixelSize: Math.round(20 * Theme.uiScale)
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: NetworkService.band + " · " + NetworkService.freq + " · PHY " + NetworkService.phyRate
                        color: Theme.subtextDim
                        font.pixelSize: Math.round(13 * Theme.uiScale)
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Minimalist Metrics Row: IP, Signal dBm, Latency / Throughput
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * Theme.uiScale)

                // Pill 1: IP Address
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * Theme.uiScale)
                    radius: Math.round(8 * Theme.uiScale)
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰩟"
                            color: Theme.accent
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: NetworkService.ip
                            color: Theme.fgSoft
                            font.pixelSize: 12
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Pill 2: Signal Strength
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * Theme.uiScale)
                    radius: Math.round(8 * Theme.uiScale)
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰤨"
                            color: Theme.accent
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: NetworkService.isConnected ? (NetworkService.rssi + " dBm") : "--"
                            color: Theme.fgSoft
                            font.pixelSize: 12
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Pill 3: Ping & Realtime Throughput
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * Theme.uiScale)
                    radius: Math.round(8 * Theme.uiScale)
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰓅"
                            color: Theme.accent
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: NetworkService.rtt + " · ▲" + NetworkService.txRate + " ▼" + NetworkService.rxRate
                            color: Theme.fgSoft
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // CARD 2: ENCRYPTED MESH & AUTONOMOUS DEFENSE (Surface Container)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(155 * Theme.uiScale)
        radius: Math.round(16 * Theme.uiScale)
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(20 * Theme.uiScale)
            spacing: Math.round(12 * Theme.uiScale)

            // Header: Category + Details Navigation Pill
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                    }
                    Text {
                        text: "ENCRYPTED MESH & ROUTING"
                        color: Theme.subtextDim
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.1
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }

                // Routing Details Pill: [ 󰒃 Details › ]
                Rectangle {
                    implicitHeight: Math.round(28 * Theme.uiScale)
                    implicitWidth: meshPillLayout.implicitWidth + 20
                    radius: height / 2
                    color: meshPillMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.45)
                    border.color: meshPillMouse.containsMouse ? Theme.accent : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    scale: meshPillMouse.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: meshPillLayout
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰒃"
                            color: meshPillMouse.containsMouse ? Theme.accent : Theme.fgSoft
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: "Routing Details"
                            color: meshPillMouse.containsMouse ? Theme.fg : Theme.fgSoft
                            font.pixelSize: 12
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: "›"
                            color: meshPillMouse.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: 14
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: meshPillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: masterViewRoot.meshRequested()
                    }
                }
            }

            // Item 1: Tailscale WireGuard Mesh
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "󰖂"
                    color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 20
                    font.family: Theme.fontFamily
                }

                Column {
                    spacing: 2
                    Text {
                        text: "Tailscale WireGuard Mesh"
                        color: Theme.fgSoft
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: NetworkService.tailscaleActive ? ("Mesh IP: " + NetworkService.tailscaleIp + " · MagicDNS") : "Tunnel Offline"
                        color: Theme.subtextDim
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick Toggle Pill: [ ACTIVE ]
                Rectangle {
                    implicitWidth: tsPillText.implicitWidth + 20
                    implicitHeight: 26
                    radius: 13
                    color: NetworkService.tailscaleActive ? Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)) : Qt.rgba(0, 0, 0, 0.45)
                    border.color: NetworkService.tailscaleActive ? Theme.accent : Theme.border
                    border.width: 1

                    Text {
                        id: tsPillText
                        anchors.centerIn: parent
                        text: NetworkService.tailscaleActive ? "ACTIVE" : "OFF"
                        color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.toggleTailscale()
                    }
                }
            }

            // Item 2: Zero-Trust DNS & CAKE qdisc
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "󰒃"
                    color: Theme.accent
                    font.pixelSize: 20
                    font.family: Theme.fontFamily
                }

                Column {
                    spacing: 2
                    Text {
                        text: "Zero-Trust DNS & Shaping"
                        color: Theme.fgSoft
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: NetworkService.dnsStatus + " · CAKE " + NetworkService.cakeStatus
                        color: Theme.subtextDim
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: dnsBadgeText.implicitWidth + 18
                    implicitHeight: 24
                    radius: 12
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        id: dnsBadgeText
                        anchors.centerIn: parent
                        text: "PROTECTED"
                        color: Theme.accent
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }

    // =========================================================================
    // CARD 3: WIRELESS PERIPHERALS (BLUETOOTH)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(140 * Theme.uiScale)
        radius: Math.round(16 * Theme.uiScale)
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(20 * Theme.uiScale)
            spacing: Math.round(12 * Theme.uiScale)

            // Header: Category Indicator
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: BluetoothService.isPowered ? Theme.accent : Theme.subtextDim
                    }
                    Text {
                        text: "WIRELESS PERIPHERALS"
                        color: Theme.subtextDim
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.1
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick Toggle Pill: [ ACTIVE ]
                Rectangle {
                    implicitWidth: btPillText.implicitWidth + 20
                    implicitHeight: 26
                    radius: 13
                    color: BluetoothService.isPowered ? Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)) : Qt.rgba(0, 0, 0, 0.45)
                    border.color: BluetoothService.isPowered ? Theme.accent : Theme.border
                    border.width: 1

                    Text {
                        id: btPillText
                        anchors.centerIn: parent
                        text: BluetoothService.isPowered ? "ACTIVE" : "OFF"
                        color: BluetoothService.isPowered ? Theme.accent : Theme.subtextDim
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.togglePower()
                    }
                }
            }

            // Bluetooth Status & Device Details
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "󰂯"
                    color: BluetoothService.isPowered ? Theme.accent : Theme.subtextDim
                    font.pixelSize: 22
                    font.family: Theme.fontFamily
                }

                Column {
                    spacing: 2
                    Text {
                        text: BluetoothService.isPowered ? "Bluetooth Controller" : "Controller Disabled"
                        color: Theme.fgSoft
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: BluetoothService.isPowered 
                            ? (BluetoothService.devices.length > 0 ? (BluetoothService.devices[0].name + " (Paired)") : "Zero Connected Devices")
                            : "Radio powered down"
                        color: Theme.subtextDim
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: btBadgeText.implicitWidth + 18
                    implicitHeight: 24
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    Text {
                        id: btBadgeText
                        anchors.centerIn: parent
                        text: BluetoothService.isPowered ? "STANDBY" : "OFFLINE"
                        color: Theme.subtextDim
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
