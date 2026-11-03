import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: confirmViewRoot

    property var pendingAction: null
    signal confirmed()
    signal cancelled()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(36 * Theme.uiScale)
        spacing: Math.round(24 * Theme.uiScale)

        // Header Message
        Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(8 * Theme.uiScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: confirmViewRoot.pendingAction ? ("Really want to " + confirmViewRoot.pendingAction.label.toLowerCase() + "?") : ""
                color: Theme.fgSoft
                font.pixelSize: Math.round(24 * Theme.uiScale)
                font.bold: true
                font.family: Theme.fontFamily
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: confirmViewRoot.pendingAction ? confirmViewRoot.pendingAction.desc : ""
                color: Theme.subtextDim
                font.pixelSize: Math.round(14 * Theme.uiScale)
                font.family: Theme.fontFamily
            }
        }

        Item { Layout.fillHeight: true }

        // Split Center Content: Large Iconic Badge (Left) + High-Contrast Horizontal Buttons (Right)
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(36 * Theme.uiScale)

            // Left: Large Glowing Iconic Badge (140px x 140px, 64px icon)
            Rectangle {
                width: Math.round(140 * Theme.uiScale)
                height: Math.round(140 * Theme.uiScale)
                radius: Math.round(24 * Theme.uiScale)
                color: confirmViewRoot.pendingAction
                    ? Qt.rgba(confirmViewRoot.pendingAction.color.r, confirmViewRoot.pendingAction.color.g, confirmViewRoot.pendingAction.color.b, 0.16)
                    : "transparent"
                border.color: confirmViewRoot.pendingAction
                    ? Qt.rgba(confirmViewRoot.pendingAction.color.r, confirmViewRoot.pendingAction.color.g, confirmViewRoot.pendingAction.color.b, 0.40)
                    : "transparent"
                border.width: 1.5

                Text {
                    anchors.centerIn: parent
                    text: confirmViewRoot.pendingAction ? confirmViewRoot.pendingAction.icon : ""
                    color: confirmViewRoot.pendingAction ? confirmViewRoot.pendingAction.color : Theme.fgSoft
                    font.pixelSize: Math.round(64 * Theme.uiScale)
                    font.family: Theme.fontFamily
                }
            }

            // Right: Horizontal Action Pair [ Cancel (ESC) ] [ Action (Key / ↵) ]
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(20 * Theme.uiScale)

                // ─── Button 1: Cancel (ESC) ───
                Rectangle {
                    implicitWidth: Math.round(200 * Theme.uiScale)
                    implicitHeight: Math.round(64 * Theme.uiScale)
                    radius: Math.round(16 * Theme.uiScale)
                    color: cancelBtnMouse.containsMouse
                        ? Theme.surfaceHover
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.55)
                    border.color: cancelBtnMouse.containsMouse ? Theme.accent : Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(10 * Theme.uiScale)

                        Text {
                            text: "Cancel"
                            color: cancelBtnMouse.containsMouse ? Theme.accent : "#ffffff"
                            font.pixelSize: Math.round(16 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "(ESC)"
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: 0.85
                        }
                    }

                    MouseArea {
                        id: cancelBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirmViewRoot.cancelled()
                    }
                }

                // ─── Button 2: Action [Shutdown (U / ↵)] - High Contrast Without Hovering ───
                Rectangle {
                    id: confirmBtn
                    implicitWidth: Math.round(230 * Theme.uiScale)
                    implicitHeight: Math.round(64 * Theme.uiScale)
                    radius: Math.round(16 * Theme.uiScale)

                    property color actionColor: confirmViewRoot.pendingAction ? confirmViewRoot.pendingAction.color : Theme.accent

                    // High-contrast semi-solid fill even without hovering for effortless instant legibility
                    color: confirmBtnMouse.containsMouse
                        ? actionColor
                        : Qt.rgba(actionColor.r, actionColor.g, actionColor.b, 0.32)

                    border.color: actionColor
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(10 * Theme.uiScale)

                        Text {
                            text: confirmViewRoot.pendingAction ? confirmViewRoot.pendingAction.label : "Confirm"
                            // High contrast pure white text normally, sharp black on solid hover
                            color: confirmBtnMouse.containsMouse ? "#000000" : "#ffffff"
                            font.pixelSize: Math.round(16 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: confirmViewRoot.pendingAction ? ("(" + confirmViewRoot.pendingAction.key + " / ↵)") : "(↵)"
                            color: confirmBtnMouse.containsMouse ? "#000000" : "#ffffff"
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: confirmBtnMouse.containsMouse ? 1.0 : 0.85
                        }
                    }

                    MouseArea {
                        id: confirmBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirmViewRoot.confirmed()
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Micro Key Instruction
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: confirmViewRoot.pendingAction
                ? ("esc to cancel  •  " + confirmViewRoot.pendingAction.key.toLowerCase() + " or enter to confirm")
                : "esc to cancel  •  enter to confirm"
            color: Theme.subtextDim
            font.pixelSize: Math.round(12 * Theme.uiScale)
            font.family: Theme.fontFamily
            opacity: 0.65
        }
    }
}
