import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: gridViewRoot

    property var actions: []
    signal actionSelected(var action)
    signal cancelRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(32 * Theme.uiScale)
        spacing: Math.round(20 * Theme.uiScale)

        // Header
        Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(6 * Theme.uiScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Power Session"
                color: Theme.fgSoft
                font.pixelSize: Math.round(22 * Theme.uiScale)
                font.bold: true
                font.family: Theme.fontFamily
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Select an action or press shortcut key"
                color: Theme.subtextDim
                font.pixelSize: Math.round(13 * Theme.uiScale)
                font.family: Theme.fontFamily
            }
        }

        // 3x2 Grid of Actions (Large tiles: ~256px x 124px, Huge prominent icons: 50px)
        GridLayout {
            columns: 3
            rowSpacing: Math.round(16 * Theme.uiScale)
            columnSpacing: Math.round(16 * Theme.uiScale)
            Layout.alignment: Qt.AlignHCenter

            Repeater {
                model: gridViewRoot.actions

                delegate: Rectangle {
                    id: actionTile
                    width: Math.round(254 * Theme.uiScale)
                    height: Math.round(124 * Theme.uiScale)
                    radius: Math.round(16 * Theme.uiScale)

                    // Translucent matte surface
                    color: tileMouse.containsMouse
                        ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.18)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)

                    border.color: tileMouse.containsMouse
                        ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.45)
                        : Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(10 * Theme.uiScale)

                        // Huge Iconic Lead: 50px (Instant visual recognition without cognitive friction)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            color: tileMouse.containsMouse ? modelData.color : (modelData.id === "shutdown" ? Theme.urgent : (modelData.id === "reboot" ? Theme.accent : Theme.fgSoft))
                            font.pixelSize: Math.round(50 * Theme.uiScale)
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Secondary Label with Shortcut Hint: e.g. Shutdown (U)
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Math.round(6 * Theme.uiScale)

                            Text {
                                text: modelData.label
                                color: tileMouse.containsMouse ? modelData.color : Theme.fgSoft
                                font.pixelSize: Math.round(15 * Theme.uiScale)
                                font.bold: true
                                font.family: Theme.fontFamily
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                text: "(" + modelData.key + ")"
                                color: tileMouse.containsMouse ? modelData.color : Theme.subtextDim
                                font.pixelSize: Math.round(13 * Theme.uiScale)
                                font.bold: true
                                font.family: Theme.fontFamily
                                opacity: 0.85
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: gridViewRoot.actionSelected(modelData)
                    }
                }
            }
        }

        // Footer Cancel Capsule
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: cancelGridRow.implicitWidth + Math.round(32 * Theme.uiScale)
            implicitHeight: Math.round(36 * Theme.uiScale)
            radius: Math.round(18 * Theme.uiScale)
            color: cancelGridMouse.containsMouse ? Theme.surfaceHover : "transparent"
            border.color: cancelGridMouse.containsMouse ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Row {
                id: cancelGridRow
                anchors.centerIn: parent
                spacing: Math.round(8 * Theme.uiScale)

                Text {
                    text: "Cancel"
                    color: cancelGridMouse.containsMouse ? Theme.accent : Theme.subtextDim
                    font.pixelSize: Math.round(14 * Theme.uiScale)
                    font.bold: true
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Text {
                    text: "(ESC)"
                    color: Theme.subtextDim
                    font.pixelSize: Math.round(12 * Theme.uiScale)
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.7
                }
            }

            MouseArea {
                id: cancelGridMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: gridViewRoot.cancelRequested()
            }
        }
    }
}
