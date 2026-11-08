import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import "../../services"
import "../../components"

ColumnLayout {
    id: selectorRoot

    property string title: "DEVICES"
    property string targetClass: "Audio/Sink"
    property int currentId: -1

    signal backClicked()

    spacing: Math.round(14 * Theme.uiScale)

    // Helper filter to accurately identify hardware sinks vs sources
    function matchDevice(n) {
        if (!n || n.isStream) return false;
        var props = n.properties || {};
        var mClass = props["media.class"] || "";
        if (selectorRoot.targetClass === "Audio/Sink") {
            return n.isSink || mClass === "Audio/Sink";
        } else {
            return (!n.isSink && (mClass === "Audio/Source" || mClass === "Audio/Source/Virtual" || (!mClass && n.audio)));
        }
    }

    // =========================================================================
    // Header: Back button + Title
    // =========================================================================
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            implicitWidth: Math.round(84 * Theme.uiScale)
            implicitHeight: Math.round(32 * Theme.uiScale)
            radius: Math.round(8 * Theme.uiScale)
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
                onClicked: selectorRoot.backClicked()
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: selectorRoot.title
            color: Theme.fg
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 1.2
            font.family: Theme.fontFamily
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.border
        opacity: 0.4
    }

    // =========================================================================
    // Scrollable Device Cards List (Fixed Height, Internal Flickable)
    // =========================================================================
    Flickable {
        id: flickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.rightMargin: -12
        contentWidth: width - 12
        contentHeight: deviceListLayout.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ModernScrollBar {
            targetFlickable: flickable
        }

        ColumnLayout {
            id: deviceListLayout
            width: flickable.contentWidth
            spacing: 8

            Repeater {
                model: Pipewire.nodes.values.filter(n => selectorRoot.matchDevice(n))

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 50
                    radius: 10

                    readonly property bool isSelected: modelData.id === selectorRoot.currentId
                    color: isSelected ? Theme.surfaceHover : (cardMouse.containsMouse ? Theme.surface : "transparent")
                    border.color: isSelected ? Theme.accent : (cardMouse.containsMouse ? Theme.border : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 14

                        // Radio indicator
                        Text {
                            text: isSelected ? "󰄲" : "󰄱"
                            color: isSelected ? Theme.accent : Theme.subtextDim
                            font.pixelSize: 18
                            font.family: Theme.fontFamily
                        }

                        // Device name (Clean 15px Bold)
                        Text {
                            text: {
                                var p = modelData.properties || {};
                                return modelData.description || p["node.nick"] || modelData.name || ("Device #" + modelData.id);
                            }
                            color: isSelected ? Theme.fg : Theme.fgSoft
                            font.pixelSize: 15
                            font.bold: isSelected
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Active badge
                        Rectangle {
                            visible: isSelected
                            implicitWidth: activeText.implicitWidth + 16
                            implicitHeight: 24
                            radius: 12
                            color: Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25))
                            border.color: Theme.accent
                            border.width: 1

                            Text {
                                id: activeText
                                anchors.centerIn: parent
                                text: "ACTIVE"
                                color: Theme.accent
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.0
                                font.family: Theme.fontFamily
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["wpctl", "set-default", modelData.id.toString()]);
                            selectorRoot.backClicked();
                        }
                    }
                }
            }
        }
    }
}
