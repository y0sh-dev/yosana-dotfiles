import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../services"
import "../../components"

ColumnLayout {
    id: scannerRoot

    signal backClicked()

    spacing: Math.round(16 * Theme.uiScale)

    // =========================================================================
    // HEADER: Back Button + Title + Scan Trigger
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Ghost Back Button
        Rectangle {
            implicitWidth: Math.round(84 * Theme.uiScale)
            implicitHeight: Math.round(32 * Theme.uiScale)
            radius: Math.round(8 * Theme.uiScale)
            color: backMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            border.color: backMouse.containsMouse ? Theme.accent : Qt.rgba(255, 255, 255, 0.08)
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
                }

                Text {
                    text: "Back"
                    color: backMouse.containsMouse ? Theme.accent : Theme.fgSoft
                    font.pixelSize: 13
                    font.bold: true
                    font.family: Theme.fontFamily
                }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: scannerRoot.backClicked()
            }
        }

        Item { Layout.fillWidth: true }

        // Modal Title
        Text {
            text: "AIRWAVE RECON / WI-FI"
            color: Theme.fg
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 1.2
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }

        // Recon / Scan Pill Button
        Rectangle {
            implicitWidth: scanPillRow.implicitWidth + 20
            implicitHeight: Math.round(30 * Theme.uiScale)
            radius: height / 2
            color: scanMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.45)
            border.color: NetworkService.isScanning ? Theme.accent : (scanMouse.containsMouse ? Theme.accent : Qt.rgba(255, 255, 255, 0.08))
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                id: scanPillRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰑐"
                    color: NetworkService.isScanning ? Theme.accent : (scanMouse.containsMouse ? Theme.accent : Theme.fgSoft)
                    font.pixelSize: 13
                    font.family: Theme.fontFamily

                    RotationAnimation on rotation {
                        running: NetworkService.isScanning
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }

                Text {
                    text: NetworkService.isScanning ? "SCANNING" : "SCAN"
                    color: NetworkService.isScanning ? Theme.accent : (scanMouse.containsMouse ? Theme.fg : Theme.fgSoft)
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.8
                    font.family: Theme.fontFamily
                }
            }

            MouseArea {
                id: scanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkService.scan()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(255, 255, 255, 0.06)
    }

    // =========================================================================
    // SCROLLABLE AP LIST (Fixed Modal Height, Internal Flickable)
    // =========================================================================
    Flickable {
        id: flickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.rightMargin: -14
        contentWidth: width - 14
        contentHeight: apListLayout.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ModernScrollBar {
            targetFlickable: flickable
        }

        ColumnLayout {
            id: apListLayout
            width: flickable.contentWidth
            spacing: 10

            // Zero networks placeholder
            Item {
                visible: NetworkService.scanResults.length === 0
                Layout.fillWidth: true
                implicitHeight: 200

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰤮"
                        color: Theme.subtextDim
                        font.pixelSize: 36
                        font.family: Theme.fontFamily
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No airwave transmitters detected"
                        color: Theme.subtextDim
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                    }
                }
            }

            // AP Cards Repeater
            Repeater {
                model: NetworkService.scanResults

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(58 * Theme.uiScale)
                    radius: Math.round(12 * Theme.uiScale)

                    readonly property bool isCurrentConnected: modelData.connected === true || (NetworkService.isConnected && modelData.ssid === NetworkService.ssid)

                    color: isCurrentConnected 
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                        : (itemMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.40))

                    border.color: isCurrentConnected
                        ? Theme.accent
                        : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.05))
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(18 * Theme.uiScale)
                        anchors.rightMargin: Math.round(18 * Theme.uiScale)
                        spacing: 14

                        // Signal Icon helper
                        Text {
                            text: {
                                var s = modelData.signal || -100;
                                if (s >= -55) return "󰤨";
                                if (s >= -65) return "󰤥";
                                if (s >= -75) return "󰤢";
                                if (s >= -85) return "󰤟";
                                return "󰤯";
                            }
                            color: isCurrentConnected ? Theme.accent : Theme.fgSoft
                            font.pixelSize: 22
                            font.family: Theme.fontFamily
                        }

                        // SSID & Metadata
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true

                            Text {
                                text: modelData.ssid || "Hidden Network"
                                color: isCurrentConnected ? Theme.fg : Theme.fgSoft
                                font.pixelSize: 15
                                font.bold: true
                                font.family: Theme.fontFamily
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: (modelData.band || "5GHz") + " · " + (modelData.security || "WPA2")
                                    color: Theme.subtextDim
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamily
                                }

                                Text {
                                    text: "·"
                                    color: Theme.subtextDim
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamily
                                    visible: modelData.signal !== undefined
                                }

                                Text {
                                    text: (modelData.signal || "") + " dBm"
                                    color: Theme.subtextDim
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamily
                                    visible: modelData.signal !== undefined
                                }
                            }
                        }

                        // Connect / Connected Action Badge
                        Rectangle {
                            implicitWidth: actionText.implicitWidth + 20
                            implicitHeight: Math.round(28 * Theme.uiScale)
                            radius: height / 2
                            color: isCurrentConnected 
                                ? Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)) 
                                : (connectMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.40))
                            border.color: isCurrentConnected ? Theme.accent : (connectMouse.containsMouse ? Theme.accent : Qt.rgba(255, 255, 255, 0.08))
                            border.width: 1

                            Text {
                                id: actionText
                                anchors.centerIn: parent
                                text: isCurrentConnected ? "CONNECTED" : "CONNECT"
                                color: isCurrentConnected ? Theme.accent : (connectMouse.containsMouse ? Theme.fg : Theme.fgSoft)
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.8
                                font.family: Theme.fontFamily
                            }

                            MouseArea {
                                id: connectMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!isCurrentConnected) {
                                        NetworkService.connectNetwork(modelData.ssid);
                                        scannerRoot.backClicked();
                                    } else {
                                        NetworkService.disconnectNetwork();
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!isCurrentConnected) {
                                NetworkService.connectNetwork(modelData.ssid);
                                scannerRoot.backClicked();
                            }
                        }
                    }
                }
            }
        }
    }
}
