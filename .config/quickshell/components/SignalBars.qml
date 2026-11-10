import QtQuick
import "../services"

// Compact ascending signal meter. Fill maps -90..-50 dBm to 0..1.
Row {
    id: bars

    property int rssi: -100
    property int barsCount: 4

    spacing: 2

    Repeater {
        model: bars.barsCount
        Rectangle {
            width: 2
            height: 4 + index * 3
            radius: 1
            y: bars.height - height
            color: ((index + 1) / bars.barsCount) <= Math.max(0, Math.min(1, (bars.rssi + 90) / 40.0))
                   ? Theme.accent
                   : Qt.rgba(255, 255, 255, 0.09)
        }
    }
}
