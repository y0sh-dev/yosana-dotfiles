import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../services"
import "../../components"

// MESH deck — Tailscale overlay, zero-trust resolver, and CAKE shaping.
// Read-only telemetry except for the overlay toggle.
Flickable {
    id: meshRoot

    contentWidth: width - 10
    contentHeight: contentLayout.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ModernScrollBar { targetFlickable: meshRoot }

    ColumnLayout {
        id: contentLayout
        width: meshRoot.contentWidth
        spacing: Math.round(16 * Theme.uiScale)

        RowLayout {
            Layout.fillWidth: true
            spacing: 9
            Rectangle {
                width: 6; height: 6; radius: 3
                color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
            }
            MicroLabel { text: "MESH & ROUTING TELEMETRY" }
            Item { Layout.fillWidth: true }
            Text {
                text: "LIVE"
                color: Theme.accent
                font.pixelSize: Math.round(10 * Theme.uiScale)
                font.bold: true
                font.letterSpacing: 1.2
                font.family: Theme.fontFamily
            }
        }

        // ═════════════════════════════════════════════════════════════
        // TAILSCALE OVERLAY
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tsCol.implicitHeight + Math.round(40 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: tsCol
                anchors.fill: parent
                anchors.margins: Math.round(20 * Theme.uiScale)
                spacing: Math.round(12 * Theme.uiScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    Text {
                        text: "󰖂"
                        color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                        font.pixelSize: Math.round(15 * Theme.uiScale)
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "TAILSCALE WIREGUARD"
                        color: Theme.fgSoft
                        font.pixelSize: Math.round(12 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.1
                        font.family: Theme.fontFamily
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: tsBadge.implicitWidth + 18
                        implicitHeight: 24
                        radius: 12
                        color: NetworkService.tailscaleActive
                               ? Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25))
                               : Qt.rgba(0, 0, 0, 0.40)
                        border.color: NetworkService.tailscaleActive ? Theme.accent : Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1
                        Text {
                            id: tsBadge
                            anchors.centerIn: parent
                            text: NetworkService.tailscaleActive ? "ACTIVE" : "STANDBY"
                            color: NetworkService.tailscaleActive ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(10 * Theme.uiScale)
                            font.bold: true
                            font.letterSpacing: 0.9
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

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Math.round(22 * Theme.uiScale)
                    rowSpacing: Math.round(9 * Theme.uiScale)

                    KvLabel { text: "Overlay Address" }
                    KvValue {
                        text: NetworkService.tailscaleActive ? NetworkService.tailscaleIp : "Disconnected"
                        color: Theme.accent
                        Layout.fillWidth: true
                    }

                    KvLabel { text: "MagicDNS Route" }
                    KvValue { text: "yukkkk1-station.ts.net"; Layout.fillWidth: true }

                    KvLabel { text: "Cipher Suite" }
                    KvValue { text: "ChaCha20-Poly1305 (Noise_IK)"; Layout.fillWidth: true }

                    KvLabel { text: "Direct Mesh Peer" }
                    KvValue { text: "tokyo-relay-01 · 1.4 ms RTT"; Layout.fillWidth: true }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════
        // ZERO-TRUST DNS
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: dnsCol.implicitHeight + Math.round(40 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: dnsCol
                anchors.fill: parent
                anchors.margins: Math.round(20 * Theme.uiScale)
                spacing: Math.round(12 * Theme.uiScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    Text { text: "󰒃"; color: Theme.accent; font.pixelSize: Math.round(15 * Theme.uiScale); font.family: Theme.fontFamily }
                    Text {
                        text: "ZERO-TRUST DNS & RESOLVER"
                        color: Theme.fgSoft
                        font.pixelSize: Math.round(12 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.1
                        font.family: Theme.fontFamily
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: dnsBadge.implicitWidth + 18
                        implicitHeight: 24
                        radius: 12
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
                        border.width: 1
                        Text {
                            id: dnsBadge
                            anchors.centerIn: parent
                            text: "PROTECTED"
                            color: Theme.accent
                            font.pixelSize: Math.round(10 * Theme.uiScale)
                            font.bold: true
                            font.letterSpacing: 0.9
                            font.family: Theme.fontFamily
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Math.round(22 * Theme.uiScale)
                    rowSpacing: Math.round(9 * Theme.uiScale)

                    KvLabel { text: "Local Daemon" }
                    KvValue { text: "Unbound 1.20 @ 127.0.0.1:853"; Layout.fillWidth: true }

                    KvLabel { text: "Upstream Transport" }
                    KvValue { text: "DNS-over-TLS (Quad9 / TLS 1.3)"; Layout.fillWidth: true }

                    KvLabel { text: "Validation" }
                    KvValue { text: "DNSSEC Strict Enforced"; color: Theme.accent; Layout.fillWidth: true }

                    KvLabel { text: "Cache Latency" }
                    KvValue { text: "0.3 ms · Hit Ratio 91.8%"; Layout.fillWidth: true }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════
        // TRAFFIC SHAPING (CAKE)
        // ═════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cakeCol.implicitHeight + Math.round(40 * Theme.uiScale)
            radius: Math.round(16 * Theme.uiScale)
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1

            ColumnLayout {
                id: cakeCol
                anchors.fill: parent
                anchors.margins: Math.round(20 * Theme.uiScale)
                spacing: Math.round(12 * Theme.uiScale)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9
                    Text { text: "󰓅"; color: Theme.accent; font.pixelSize: Math.round(15 * Theme.uiScale); font.family: Theme.fontFamily }
                    Text {
                        text: "TRAFFIC SHAPING (CAKE QDISC)"
                        color: Theme.fgSoft
                        font.pixelSize: Math.round(12 * Theme.uiScale)
                        font.bold: true
                        font.letterSpacing: 1.1
                        font.family: Theme.fontFamily
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: cakeBadge.implicitWidth + 18
                        implicitHeight: 24
                        radius: 12
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
                        border.width: 1
                        Text {
                            id: cakeBadge
                            anchors.centerIn: parent
                            text: "LAMINAR"
                            color: Theme.accent
                            font.pixelSize: Math.round(10 * Theme.uiScale)
                            font.bold: true
                            font.letterSpacing: 0.9
                            font.family: Theme.fontFamily
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Math.round(22 * Theme.uiScale)
                    rowSpacing: Math.round(9 * Theme.uiScale)

                    KvLabel { text: "Queue Discipline" }
                    KvValue { text: "CAKE (DiffServ / FQ-CoDel hybrid)"; Layout.fillWidth: true }

                    KvLabel { text: "Flow Isolation" }
                    KvValue { text: "Triple-isolate (host / flow / src-dst)"; Layout.fillWidth: true }

                    KvLabel { text: "Buffer Overhead" }
                    KvValue { text: "0 drops · +0.2 ms peak under load"; color: Theme.accent; Layout.fillWidth: true }
                }
            }
        }

        Item { Layout.fillWidth: true; Layout.preferredHeight: Math.round(4 * Theme.uiScale) }
    }
}
