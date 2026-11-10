import QtQuick
import "../services"

Item {
    id: marqueeRoot

    property string text: ""
    property color color: Theme.fg
    property int pixelSize: 13
    property bool fontBold: true
    property string fontFamily: Theme.fontFamily
    property int gap: 36
    property bool running: true
    property real speed: 32 // pixels per second

    clip: true

    Text {
        id: measureText
        text: marqueeRoot.text
        font.pixelSize: marqueeRoot.pixelSize
        font.bold: marqueeRoot.fontBold
        font.family: marqueeRoot.fontFamily
        visible: false
    }

    readonly property bool needsScroll: measureText.implicitWidth > marqueeRoot.width
    readonly property real cycleDistance: measureText.implicitWidth + marqueeRoot.gap

    property real offset: 0.0

    NumberAnimation on offset {
        from: 0.0
        to: Math.max(1, marqueeRoot.cycleDistance)
        duration: Math.max(1000, (Math.max(1, marqueeRoot.cycleDistance) / Math.max(1, marqueeRoot.speed)) * 1000)
        loops: Animation.Infinite
        running: marqueeRoot.running && marqueeRoot.needsScroll
    }

    // Static text when no scroll needed
    Text {
        visible: !marqueeRoot.needsScroll
        text: marqueeRoot.text
        color: marqueeRoot.color
        font.pixelSize: marqueeRoot.pixelSize
        font.bold: marqueeRoot.fontBold
        font.family: marqueeRoot.fontFamily
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        width: parent.width
    }

    // Seamless dual-text ticker (Snake chasing its tail)
    Item {
        visible: marqueeRoot.needsScroll
        anchors.fill: parent

        // Instance 1
        Text {
            x: -marqueeRoot.offset
            anchors.verticalCenter: parent.verticalCenter
            text: marqueeRoot.text
            color: marqueeRoot.color
            font.pixelSize: marqueeRoot.pixelSize
            font.bold: marqueeRoot.fontBold
            font.family: marqueeRoot.fontFamily
        }

        // Instance 2 (Trailing immediately behind Instance 1)
        Text {
            x: -marqueeRoot.offset + marqueeRoot.cycleDistance
            anchors.verticalCenter: parent.verticalCenter
            text: marqueeRoot.text
            color: marqueeRoot.color
            font.pixelSize: marqueeRoot.pixelSize
            font.bold: marqueeRoot.fontBold
            font.family: marqueeRoot.fontFamily
        }
    }
}
