import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: monthViewRoot

    readonly property var currentTime: TimeService.now
    property int viewYear: currentTime.getFullYear()
    property int viewMonth: currentTime.getMonth() // 0-indexed

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear--;
        } else {
            viewMonth--;
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear++;
        } else {
            viewMonth++;
        }
    }

    function prevYear() {
        viewYear--;
    }

    function nextYear() {
        viewYear++;
    }

    function resetToday() {
        viewYear = currentTime.getFullYear();
        viewMonth = currentTime.getMonth();
    }

    // Solid Framed Enclosure Card for Calendar (Frameless pure matte card with gentle translucency)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.width: 0
        radius: Math.round(14 * Theme.uiScale)

        // Mouse wheel navigation for smooth month switching
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton // Let clicks pass through to child buttons
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) {
                    monthViewRoot.prevMonth();
                } else if (wheel.angleDelta.y < 0) {
                    monthViewRoot.nextMonth();
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(14 * Theme.uiScale)
            spacing: Math.round(10 * Theme.uiScale)

            // 1. Navigation Header: Bi-split Capsule Navigation (◀ Month ▶ / ◀ Year ▶ / Reset)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * Theme.uiScale)

                // ─── Bi-split Month Capsule ───
                Rectangle {
                    id: monthCapsule
                    implicitWidth: Math.round(186 * Theme.uiScale)
                    implicitHeight: Math.round(36 * Theme.uiScale)
                    radius: Math.round(18 * Theme.uiScale)
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    clip: true

                    // Left-half rounded highlight (Previous Month)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: monthDivider.left
                        anchors.margins: 2
                        radius: Math.round(16 * Theme.uiScale)
                        color: prevMonthArea.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Center micro-gap
                    Item {
                        id: monthDivider
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 2
                        height: parent.height
                    }

                    // Right-half rounded highlight (Next Month)
                    Rectangle {
                        anchors.left: monthDivider.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        radius: Math.round(16 * Theme.uiScale)
                        color: nextMonthArea.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Content (Centered over the capsule)
                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(10 * Theme.uiScale)

                        Text {
                            text: "◀"
                            color: prevMonthArea.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(12 * Theme.uiScale)
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                            text: monthNames[monthViewRoot.viewMonth]
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(14 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "▶"
                            color: nextMonthArea.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(12 * Theme.uiScale)
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    // Left-half hit area (◀ to center)
                    MouseArea {
                        id: prevMonthArea
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: monthDivider.left
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monthViewRoot.prevMonth()
                    }

                    // Right-half hit area (center to ▶)
                    MouseArea {
                        id: nextMonthArea
                        anchors.left: monthDivider.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monthViewRoot.nextMonth()
                    }
                }

                // ─── Bi-split Year Capsule ───
                Rectangle {
                    id: yearCapsule
                    implicitWidth: Math.round(120 * Theme.uiScale)
                    implicitHeight: Math.round(36 * Theme.uiScale)
                    radius: Math.round(18 * Theme.uiScale)
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    clip: true

                    // Left-half rounded highlight (Previous Year)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: yearDivider.left
                        anchors.margins: 2
                        radius: Math.round(16 * Theme.uiScale)
                        color: prevYearArea.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Center micro-gap
                    Item {
                        id: yearDivider
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 2
                        height: parent.height
                    }

                    // Right-half rounded highlight (Next Year)
                    Rectangle {
                        anchors.left: yearDivider.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        radius: Math.round(16 * Theme.uiScale)
                        color: nextYearArea.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Content (Centered over the capsule)
                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(8 * Theme.uiScale)

                        Text {
                            text: "◀"
                            color: prevYearArea.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(11 * Theme.uiScale)
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: monthViewRoot.viewYear.toString()
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(14 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "▶"
                            color: nextYearArea.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(11 * Theme.uiScale)
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    // Left-half hit area (◀ to center)
                    MouseArea {
                        id: prevYearArea
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: yearDivider.left
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monthViewRoot.prevYear()
                    }

                    // Right-half hit area (center to ▶)
                    MouseArea {
                        id: nextYearArea
                        anchors.left: yearDivider.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monthViewRoot.nextYear()
                    }
                }

                Item { Layout.fillWidth: true }

                // ─── Reset to Today Button ───
                Rectangle {
                    implicitWidth: Math.round(36 * Theme.uiScale)
                    implicitHeight: Math.round(36 * Theme.uiScale)
                    radius: Math.round(18 * Theme.uiScale)
                    color: todayMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    border.color: todayMouse.containsMouse ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰃭"
                        color: todayMouse.containsMouse ? Theme.accent : Theme.subtextDim
                        font.pixelSize: Math.round(16 * Theme.uiScale)
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: todayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monthViewRoot.resetToday()
                    }
                }
            }

            // 2. Weekday Header (Sun=Red, Mon-Fri=SubtextDim, Sat=Blue)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(4 * Theme.uiScale)

                Repeater {
                    model: [
                        { name: "Sun", color: Theme.colorSun },
                        { name: "Mon", color: Theme.subtextDim },
                        { name: "Tue", color: Theme.subtextDim },
                        { name: "Wed", color: Theme.subtextDim },
                        { name: "Thu", color: Theme.subtextDim },
                        { name: "Fri", color: Theme.subtextDim },
                        { name: "Sat", color: Theme.colorSat }
                    ]
                    delegate: Item {
                        Layout.fillWidth: true
                        height: Math.round(26 * Theme.uiScale)
                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            color: modelData.color
                            font.pixelSize: Math.round(12 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }
                }
            }

            // 3. Subtle Matte Divider Line between Header & Grid
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
                opacity: 0.18
            }

            // 4. Days Grid (42 Cells: 7 cols x 6 rows) - Matte Tile Grid Architecture
            GridLayout {
                columns: 7
                rowSpacing: Math.round(4 * Theme.uiScale)
                columnSpacing: Math.round(4 * Theme.uiScale)
                Layout.fillWidth: true

                Repeater {
                    model: 42
                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(38 * Theme.uiScale)

                        readonly property int firstDayOfWeek: new Date(monthViewRoot.viewYear, monthViewRoot.viewMonth, 1).getDay()
                        readonly property int daysInCurrentMonth: new Date(monthViewRoot.viewYear, monthViewRoot.viewMonth + 1, 0).getDate()
                        readonly property int daysInPrevMonth: new Date(monthViewRoot.viewYear, monthViewRoot.viewMonth, 0).getDate()

                        readonly property int dayOffset: index - firstDayOfWeek + 1
                        readonly property bool isCurrentMonth: dayOffset > 0 && dayOffset <= daysInCurrentMonth
                        readonly property int displayDay: {
                            if (dayOffset <= 0) return daysInPrevMonth + dayOffset;
                            if (dayOffset > daysInCurrentMonth) return dayOffset - daysInCurrentMonth;
                            return dayOffset;
                        }

                        readonly property bool isToday: isCurrentMonth &&
                            monthViewRoot.viewYear === monthViewRoot.currentTime.getFullYear() &&
                            monthViewRoot.viewMonth === monthViewRoot.currentTime.getMonth() &&
                            displayDay === monthViewRoot.currentTime.getDate()

                        // Matte Tile Slot
                        Rectangle {
                            anchors.fill: parent
                            radius: Math.round(8 * Theme.uiScale)

                            // Background: Today is accent, Hover is surfaceHover, default is transparent
                            color: {
                                if (isToday) return Theme.accent;
                                if (dayMouse.containsMouse) return Theme.surfaceHover;
                                return "transparent";
                            }

                            // Subtle structural slot border for current month (creates authentic calendar layer)
                            border.color: {
                                if (isToday) return Theme.accent;
                                if (dayMouse.containsMouse) return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35);
                                if (isCurrentMonth) return Qt.rgba(1, 1, 1, 0.04);
                                return "transparent";
                            }
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: displayDay.toString()
                                color: {
                                    if (isToday) return "#000000"; // Sharp contrast on solid accent pill
                                    if (!isCurrentMonth) return Qt.rgba(Theme.subtextDim.r, Theme.subtextDim.g, Theme.subtextDim.b, 0.28); // Elegant ghost depth
                                    if (index % 7 === 0) return Theme.colorSun; // Sunday Red
                                    if (index % 7 === 6) return Theme.colorSat; // Saturday Blue
                                    return Theme.fgSoft;
                                }
                                font.pixelSize: Math.round(14 * Theme.uiScale)
                                font.bold: isToday
                                font.family: Theme.fontFamily
                            }
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }
        }
    }
}
