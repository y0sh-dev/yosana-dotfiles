pragma Singleton
import QtQuick

QtObject {
    id: timeService

    property date now: new Date()
    readonly property string shortTime: Qt.formatDateTime(now, "HH:mm")
    readonly property string fullDate: Qt.formatDateTime(now, "MMMM d, yyyy")

    // Precision mode: when active (e.g. CalendarPopup opened), ticks every 1000ms for seconds display.
    // When inactive (default), synchronizes precisely to minute boundaries (:00 sec) with zero idle polling.
    property bool highPrecision: false

    function tick() {
        now = new Date();
        scheduleNext();
    }

    function scheduleNext() {
        if (highPrecision) {
            // Next exact second boundary (:XX.000)
            const ms = now.getMilliseconds();
            syncTimer.interval = Math.max(20, 1000 - ms);
        } else {
            // Next exact minute boundary (:00.000)
            const sec = now.getSeconds();
            const ms = now.getMilliseconds();
            const remainingMs = (60 - sec) * 1000 - ms;
            syncTimer.interval = Math.max(50, remainingMs);
        }
        syncTimer.restart();
    }

    property var syncTimer: Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: timeService.tick()
    }

    onHighPrecisionChanged: {
        tick();
    }

    Component.onCompleted: {
        tick();
    }
}
