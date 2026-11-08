import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../services"
import "../../components"

ColumnLayout {
    id: meshRoot

    signal backClicked()

    spacing: Math.round(16 * Theme.uiScale)

    // =========================================================================
    // HEADER: Back Button + Title
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
                onClicked: meshRoot.backClicked()
            }
        }

        Item { Layout.fillWidth: true }

        // Modal Title
        Text {
            text: "MESH & ROUTING TELEMETRY"
            color: Theme.fg
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 1.2
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(255, 255, 255, 0.06)
    }

    // =========================================================================
    // SCROLLABLE TELEMETRY (Fixed Modal Height, Internal Flickable)
    // =========================================================================
    Flickable {
        id: flickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.rightMargin: -14
        contentWidth: width - 14
        contentHeight: meshContentLayout.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ModernScrollBar {
            targetFlickable: flickable
        }

        ColumnLayout {
            id: meshContentLayout
            width: flickable.contentWidth
            spacing: Math.round(16 * Theme.uiScale)

            // =================================================================
            // SECTION 1: TAILSCALE WIREGUARD MESH
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: tsLayout.implicitHeight + Math.round(36 * Theme.uiScale)
                radius: Math.round(12 * Theme.uiScale)
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                border.color: Qt.rgba(255, 255, 255, 0.06)
                border.width: 1

                ColumnLayout {
                    id: tsLayout
                    anchors.fill: parent
                    anchors.margins: Math.round(18 * Theme.uiScale)
                    spacing: Math.round(12 * Theme.uiScale)

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰖂"
                            color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                            font.pixelSize: 16
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: "TAILSCALE WIREGUARD OVERLAY"
                            color: Theme.fg
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.0
                            font.family: Theme.fontFamily
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: tsBadgeText.implicitWidth + 18
                            implicitHeight: 24
                            radius: 11
                            color: NetworkService.tailscaleActive 
                                ? Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25))
                                : Qt.rgba(0, 0, 0, 0.40)
                            border.color: NetworkService.tailscaleActive ? Theme.accent : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1

                            Text {
                                id: tsBadgeText
                                anchors.centerIn: parent
                                text: NetworkService.tailscaleActive ? "ACTIVE" : "STANDBY"
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

                    // Key-Value Rows
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 9

                        Text { text: "Overlay Address"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: NetworkService.tailscaleActive ? NetworkService.tailscaleIp : "Disconnected"; color: Theme.fgSoft; font.pixelSize: 13; font.bold: true; font.family: Theme.fontFamily }

                        Text { text: "MagicDNS Route"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "yukkkk1-station.ts.net"; color: Theme.fgSoft; font.pixelSize: 13; font.family: Theme.fontFamily }

                        Text { text: "Cipher Suite"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "ChaCha20-Poly1305 (Noise_IK)"; color: Theme.fgSoft; font.pixelSize: 13; font.family: Theme.fontFamily }

                        Text { text: "Direct Mesh Peer"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "tokyo-relay-01 · 1.4 ms RTT"; color: Theme.accent; font.pixelSize: 13; font.family: Theme.fontFamily }
                    }
                }
            }

            // =================================================================
            // SECTION 2: ZERO-TRUST RECURSIVE DNS (UNBOUND)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: dnsLayout.implicitHeight + Math.round(36 * Theme.uiScale)
                radius: Math.round(12 * Theme.uiScale)
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                border.color: Qt.rgba(255, 255, 255, 0.06)
                border.width: 1

                ColumnLayout {
                    id: dnsLayout
                    anchors.fill: parent
                    anchors.margins: Math.round(18 * Theme.uiScale)
                    spacing: Math.round(12 * Theme.uiScale)

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰒃"
                            color: Theme.accent
                            font.pixelSize: 16
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: "ZERO-TRUST DNS & RESOLVER"
                            color: Theme.fg
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.0
                            font.family: Theme.fontFamily
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: dnsTagText.implicitWidth + 18
                            implicitHeight: 24
                            radius: 11
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                            border.color: Theme.accent
                            border.width: 1

                            Text {
                                id: dnsTagText
                                anchors.centerIn: parent
                                text: "PROTECTED"
                                color: Theme.accent
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.8
                                font.family: Theme.fontFamily
                            }
                        }
                    }

                    // Key-Value Rows
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 9

                        Text { text: "Local Daemon"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "Unbound 1.20 @ 127.0.0.1:853"; color: Theme.fgSoft; font.pixelSize: 13; font.bold: true; font.family: Theme.fontFamily }

                        Text { text: "Upstream Transport"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "DNS-over-TLS (Quad9 / TLS 1.3)"; color: Theme.fgSoft; font.pixelSize: 13; font.family: Theme.fontFamily }

                        Text { text: "Validation"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "DNSSEC Strict Enforced"; color: Theme.accent; font.pixelSize: 13; font.family: Theme.fontFamily }

                        Text { text: "Cache Latency"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "0.3 ms · Hit Ratio 91.8%"; color: Theme.fgSoft; font.pixelSize: 13; font.family: Theme.fontFamily }
                    }
                }
            }

            // =================================================================
            // SECTION 3: BUFFERBLOAT MITIGATION (CAKE QDISC)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: cakeLayout.implicitHeight + Math.round(36 * Theme.uiScale)
                radius: Math.round(12 * Theme.uiScale)
                color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.35)
                border.color: Qt.rgba(255, 255, 255, 0.06)
                border.width: 1

                ColumnLayout {
                    id: cakeLayout
                    anchors.fill: parent
                    anchors.margins: Math.round(18 * Theme.uiScale)
                    spacing: Math.round(12 * Theme.uiScale)

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰓅"
                            color: Theme.accent
                            font.pixelSize: 16
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: "TRAFFIC SHAPING (CAKE QDISC)"
                            color: Theme.fg
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.0
                            font.family: Theme.fontFamily
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: cakeTagText.implicitWidth + 18
                            implicitHeight: 24
                            radius: 11
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                            border.color: Theme.accent
                            border.width: 1

                            Text {
                                id: cakeTagText
                                anchors.centerIn: parent
                                text: "LAMINAR FLOW"
                                color: Theme.accent
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.8
                                font.family: Theme.fontFamily
                            }
                        }
                    }

                    // Key-Value Rows
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 9

                        Text { text: "Queue Discipline"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "CAKE (DiffServ / FQ-CoDel hybrid)"; color: Theme.fgSoft; font.pixelSize: 13; font.bold: true; font.family: Theme.fontFamily }

                        Text { text: "Flow Isolation"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "Triple-isolate (host / flow / src-dst)"; color: Theme.fgSoft; font.pixelSize: 13; font.family: Theme.fontFamily }

                        Text { text: "Buffer Overhead"; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily }
                        Text { text: "0 drops · +0.2 ms peak under load"; color: Theme.accent; font.pixelSize: 13; font.family: Theme.fontFamily }
                    }
                }
            }
        }
    }
}
