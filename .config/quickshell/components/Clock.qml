import QtQuick
import "../services"

Text {
    property string displayTime: ""

    text: displayTime
    color: Theme.fg
    font.pixelSize: Theme.clockFontSize
    font.bold: true
    font.family: Theme.fontFamily
}
