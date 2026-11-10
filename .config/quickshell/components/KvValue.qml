import QtQuick
import "../services"

Text {
    color: Theme.fgSoft
    font.pixelSize: Math.round(13 * Theme.uiScale)
    font.bold: true
    font.family: Theme.fontFamily
    elide: Text.ElideRight
    wrapMode: Text.NoWrap
}
