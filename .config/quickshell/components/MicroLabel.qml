import QtQuick
import "../services"

// Instrument micro-label: tiny, tracked, quiet.
Text {
    color: Theme.subtextDim
    font.pixelSize: Math.round(10 * Theme.uiScale)
    font.bold: true
    font.letterSpacing: 1.4
    font.family: Theme.fontFamily
}
