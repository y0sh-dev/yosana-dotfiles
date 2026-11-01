import QtQuick

Item {
    property date now: new Date()
    readonly property string shortTime: Qt.formatDateTime(now, "HH:mm")
    readonly property string fullDate: Qt.formatDateTime(now, "yyyy年MM月dd日")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: now = new Date()
    }
}
