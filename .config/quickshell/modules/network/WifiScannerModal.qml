import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../services"
import "../../components"

// RECON deck — airwave scan, silent fast-handover for known networks, and an
// inline obsidian passphrase field for unknown secured APs. No popups.
Flickable {
    id: reconRoot

    signal backClicked()

    property string pendingSsid: ""
    property string passText: ""
    readonly property bool keyboardRequested: pendingSsid.length > 0

    contentWidth: width - 10
    contentHeight: contentLayout.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ModernScrollBar { targetFlickable: reconRoot }

    function beginJoin(ssid) {
        pendingSsid = ssid;
        passText = "";
    }

    function abortJoin() {
        pendingSsid = "";
        passText = "";
    }

    function engage(ssid) {
        if (passText.length === 0) return;
        NetworkService.connectWithPassphrase(ssid, passText);
        abortJoin();
    }

    ColumnLayout {
        id: contentLayout
        width: reconRoot.contentWidth
        spacing: Math.round(14 * Theme.uiScale)

        // ── Header ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            //Rectangle {
            //    implicitWidth: Math.round(64 * Theme.uiScale)
            //    implicitHeight: Math.round(28 * Theme.uiScale)
            //    radius: 8
            //    color: backMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.42)
            //    border.color: backMouse.containsMouse ? Theme.accent : Qt.rgba(255, 255, 255, 0.08)
            //    border.width: 1
            //    Row {
            //        anchors.centerIn: parent
            //        spacing: 5
            //        Text { text: "‹"; color: Theme.accent; font.pixelSize: 15; font.bold: true; font.family: Theme.fontFamily }
            //        Text { text: "BACK"; color: Theme.fgSoft; font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8; font.family: Theme.fontFamily }
            //    }
            //    MouseArea {
            //        id: backMouse
            //        anchors.fill: parent
            //        hoverEnabled: true
            //        cursorShape: Qt.PointingHandCursor
            //        onClicked: reconRoot.backClicked()
            //    }
            //}
            Rectangle {
                implicitWidth: 84
                implicitHeight: 32
                radius: 8
                color: backMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                border.color: backMouse.containsMouse ? Theme.accent : Theme.border
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
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "Back"
                        color: backMouse.containsMouse ? Theme.accent : Theme.fgSoft
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamily
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: reconRoot.backClicked()
                }
            }

            Item { Layout.fillWidth: true }
            MicroLabel { text: "AIRWAVE RECON" }
            Item { Layout.fillWidth: true }

            GhostPill {
                label: NetworkService.isScanning ? "SCANNING" : "SCAN"
                glyph: "󰑐"
                onTapped: NetworkService.scan()
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(255, 255, 255, 0.06) }

        // ── Empty state ──────────────────────────────────────────────
        Item {
            visible: NetworkService.scanResults.length === 0
            Layout.fillWidth: true
            implicitHeight: Math.round(150 * Theme.uiScale)
            Column {
                anchors.centerIn: parent
                spacing: 10
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰤮"; color: Theme.subtextDim; font.pixelSize: 34; font.family: Theme.fontFamily }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: NetworkService.isScanning ? "Probing the airwaves…" : "No transmitters detected"
                    color: Theme.subtextDim
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }
            }
        }

        // ── AP list ──────────────────────────────────────────────────
        Repeater {
            model: NetworkService.scanResults

            delegate: Rectangle {
                id: apCard
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: apCol.implicitHeight + Math.round(28 * Theme.uiScale)
                radius: Math.round(12 * Theme.uiScale)

                readonly property bool connected: modelData.connected === true
                    || (NetworkService.isConnected && modelData.ssid === NetworkService.ssid)
                readonly property bool isOpen: (modelData.security || "") === "Open"
                readonly property bool known: modelData.known === true
                readonly property bool expanded: reconRoot.pendingSsid === modelData.ssid

                color: connected
                       ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
                       : (apHover.hovered ? Theme.surfaceHover : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.40))
                border.color: connected ? Theme.accent
                             : (expanded ? Theme.accent
                                : (apHover.hovered ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.05)))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                HoverHandler { id: apHover }

                ColumnLayout {
                    id: apCol
                    anchors.fill: parent
                    anchors.margins: Math.round(14 * Theme.uiScale)
                    spacing: Math.round(10 * Theme.uiScale)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Text {
                            text: {
                                var s = modelData.signal || -100;
                                if (s >= -55) return "󰤨";
                                if (s >= -65) return "󰤥";
                                if (s >= -75) return "󰤢";
                                if (s >= -85) return "󰤟";
                                return "󰤯";
                            }
                            color: connected ? Theme.accent : Theme.fgSoft
                            font.pixelSize: Math.round(22 * Theme.uiScale)
                            font.family: Theme.fontFamily
                        }

                        Column {
                            spacing: 3
                            Layout.fillWidth: true

                            Row {
                                spacing: 8
                                Text {
                                    text: modelData.ssid || "Hidden Network"
                                    color: connected ? Theme.fg : Theme.fgSoft
                                    font.pixelSize: Math.round(15 * Theme.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    visible: known
                                    height: 16
                                    width: 50
                                    radius: 8
                                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "KNOWN"
                                        color: Theme.accent
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 0.8
                                        font.family: Theme.fontFamily
                                    }
                                }
                            }

                            Row {
                                spacing: 8
                                Text {
                                    text: (modelData.band || "5GHz") + " · " + (modelData.security || "WPA2")
                                    color: Theme.subtextDim
                                    font.pixelSize: Math.round(11 * Theme.uiScale)
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    visible: modelData.signal !== undefined
                                    text: "· " + (modelData.signal || "") + " dBm"
                                    color: Theme.subtextDim
                                    font.pixelSize: Math.round(11 * Theme.uiScale)
                                    font.family: Theme.fontFamily
                                }
                            }
                        }

                        // Action
                        GhostPill {
                            visible: connected
                            label: "SEVER"
                            accent: true
                            onTapped: NetworkService.disconnectNetwork()
                        }

                        GhostPill {
                            visible: !connected && known
                            label: "REJOIN"
                            glyph: "󰤨"
                            accent: true
                            onTapped: NetworkService.connectNetwork(modelData.ssid)
                        }

                        GhostPill {
                            visible: !connected && !known && isOpen
                            label: "ENGAGE"
                            glyph: "󰤨"
                            accent: true
                            onTapped: NetworkService.connectNetwork(modelData.ssid)
                        }

                        GhostPill {
                            visible: !connected && !known && !isOpen
                            label: expanded ? "CANCEL" : "JOIN"
                            glyph: "󰌾"
                            accent: expanded
                            onTapped: expanded ? reconRoot.abortJoin() : reconRoot.beginJoin(modelData.ssid)
                        }
                    }

                    // Inline passphrase field (terminal cipher entry)
                    Rectangle {
                        Layout.fillWidth: true
                        visible: apCard.expanded
                        implicitHeight: credRow.implicitHeight + Math.round(20 * Theme.uiScale)
                        radius: 9
                        color: Qt.rgba(0, 0, 0, 0.45)
                        border.color: passInput.activeFocus ? Theme.accent : Qt.rgba(255, 255, 255, 0.10)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: credRow
                            anchors.fill: parent
                            anchors.margins: Math.round(10 * Theme.uiScale)
                            spacing: 10

                            Text {
                                text: "󰌾"
                                color: Theme.accent
                                font.pixelSize: Math.round(14 * Theme.uiScale)
                                font.family: Theme.fontFamily
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: "PASSPHRASE · " + (modelData.ssid || "")
                                    color: Theme.subtextDim
                                    font.pixelSize: Math.round(9 * Theme.uiScale)
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                    font.family: Theme.fontFamily
                                }
                                TextInput {
                                    id: passInput
                                    width: parent.width
                                    height: Math.round(20 * Theme.uiScale)
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    passwordCharacter: "•"
                                    color: Theme.fgSoft
                                    selectionColor: Theme.accent
                                    selectedTextColor: "#000000"
                                    font.pixelSize: Math.round(13 * Theme.uiScale)
                                    font.family: Theme.fontFamily
                                    onTextChanged: reconRoot.passText = text
                                    onAccepted: reconRoot.engage(modelData.ssid)

                                    Component.onCompleted: if (apCard.expanded) forceActiveFocus()
                                    Connections {
                                        target: reconRoot
                                        function onPendingSsidChanged() {
                                            if (reconRoot.pendingSsid === modelData.ssid) {
                                                passInput.text = "";
                                                passInput.forceActiveFocus();
                                            }
                                        }
                                    }
                                }
                            }

                            GhostPill {
                                label: "ENGAGE"
                                glyph: "󰄬"
                                accent: true
                                onTapped: reconRoot.engage(modelData.ssid)
                            }
                        }
                    }

                    // Explicit disconnect / forget actions for the live link
                    Row {
                        visible: connected
                        spacing: 16
                        Text {
                            text: "FORGET NETWORK"
                            color: forgetMouse.containsMouse ? Theme.urgent : Theme.subtextDim
                            font.pixelSize: Math.round(10 * Theme.uiScale)
                            font.bold: true
                            font.letterSpacing: 0.8
                            font.family: Theme.fontFamily
                            MouseArea {
                                id: forgetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetworkService.forgetNetwork(modelData.ssid)
                            }
                        }
                    }
                }

            }
        }

        Item { Layout.fillWidth: true; Layout.preferredHeight: Math.round(4 * Theme.uiScale) }
    }
}
