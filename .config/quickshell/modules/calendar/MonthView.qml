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

    // Unified Surface Container Card for Calendar (Noise-free, flat Material You / Caelestia aesthetic)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1
        radius: Math.round(18 * Theme.uiScale)

        // Mouse wheel navigation on the calendar card for smooth month switching
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton // Pass clicks through to child buttons
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
            anchors.margins: Math.round(18 * Theme.uiScale)
            spacing: 0 // Explicit spacing between sections for deliberate whitespace control

            // =================================================================
            // 1. Navigation Header: Borderless Ghost Buttons
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(10 * Theme.uiScale)

                // ─── Month Ghost Navigation ───
                Row {
                    spacing: Math.round(4 * Theme.uiScale)
                    Layout.alignment: Qt.AlignVCenter

                    // Prev Month Ghost Button
                    Rectangle {
                        width: Math.round(28 * Theme.uiScale)
                        height: Math.round(28 * Theme.uiScale)
                        radius: width / 2
                        color: prevMonthArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: 120 } }
                        scale: prevMonthArea.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: prevMonthArea.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(17 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: prevMonthArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: monthViewRoot.prevMonth()
                        }
                    }

                    // Month Name Text (Scrollable with mouse wheel)
                    Item {
                        width: Math.round(104 * Theme.uiScale)
                        height: Math.round(28 * Theme.uiScale)

                        Text {
                            anchors.centerIn: parent
                            readonly property var monthNames: [
                                "January", "February", "March", "April", "May", "June",
                                "July", "August", "September", "October", "November", "December"
                            ]
                            text: monthNames[monthViewRoot.viewMonth]
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(15 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        MouseArea {
                            anchors.fill: parent
                            onWheel: function(wheel) {
                                if (wheel.angleDelta.y > 0) monthViewRoot.prevMonth();
                                else if (wheel.angleDelta.y < 0) monthViewRoot.nextMonth();
                            }
                        }
                    }

                    // Next Month Ghost Button
                    Rectangle {
                        width: Math.round(28 * Theme.uiScale)
                        height: Math.round(28 * Theme.uiScale)
                        radius: width / 2
                        color: nextMonthArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: 120 } }
                        scale: nextMonthArea.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: nextMonthArea.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(17 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: nextMonthArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: monthViewRoot.nextMonth()
                        }
                    }
                }

                // ─── Year Ghost Navigation ───
                Row {
                    spacing: Math.round(4 * Theme.uiScale)
                    Layout.alignment: Qt.AlignVCenter

                    // Prev Year Ghost Button
                    Rectangle {
                        width: Math.round(28 * Theme.uiScale)
                        height: Math.round(28 * Theme.uiScale)
                        radius: width / 2
                        color: prevYearArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: 120 } }
                        scale: prevYearArea.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: prevYearArea.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(16 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: prevYearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: monthViewRoot.prevYear()
                        }
                    }

                    // Year Text (Scrollable with mouse wheel)
                    Item {
                        width: Math.round(50 * Theme.uiScale)
                        height: Math.round(28 * Theme.uiScale)

                        Text {
                            anchors.centerIn: parent
                            text: monthViewRoot.viewYear.toString()
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(15 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        MouseArea {
                            anchors.fill: parent
                            onWheel: function(wheel) {
                                if (wheel.angleDelta.y > 0) monthViewRoot.prevYear();
                                else if (wheel.angleDelta.y < 0) monthViewRoot.nextMonth();
                            }
                        }
                    }

                    // Next Year Ghost Button
                    Rectangle {
                        width: Math.round(28 * Theme.uiScale)
                        height: Math.round(28 * Theme.uiScale)
                        radius: width / 2
                        color: nextYearArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: 120 } }
                        scale: nextYearArea.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: nextYearArea.containsMouse ? Theme.accent : Theme.subtextDim
                            font.pixelSize: Math.round(16 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: nextYearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: monthViewRoot.nextYear()
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // ─── Reset to Today Ghost Button ───
                Rectangle {
                    width: Math.round(30 * Theme.uiScale)
                    height: Math.round(30 * Theme.uiScale)
                    radius: width / 2
                    color: todayMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                    border.width: 0

                    scale: todayMouse.pressed ? 0.90 : (todayMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

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

            // Gap between Header and Weekday row
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(14 * Theme.uiScale)
            }

            // =================================================================
            // 2. Weekday Header (Sunday=Red, Mon-Fri=Subtext, Saturday=Blue)
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

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
                        height: Math.round(24 * Theme.uiScale)
                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            color: modelData.color
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            opacity: 0.90
                        }
                    }
                }
            }

            // =================================================================
            // 3. Deliberate Space between Weekdays (Sun ~ Sat) and Dates
            // This is the dedicated breathing room opening up the space between
            // the weekday header and the compact date numbers, shifting the dates
            // down to utilize the empty space at the bottom.
            // =================================================================
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(56 * Theme.uiScale)
            }

            // =================================================================
            // 4. Compact Date Grid: Original Beloved Compact Geometry
            // Flat Clean Text (Noise-Free, NO Rectangular Box Borders)
            // Number spacing is NOT stretched: 38px cell height, 4px rowSpacing
            // =================================================================
            GridLayout {
                id: daysGrid
                columns: 7
                rowSpacing: Math.round(4 * Theme.uiScale)
                columnSpacing: 0
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

                        // Circular Date Pill: Highlight ONLY "Today" and Hover state
                        Rectangle {
                            id: dayPill
                            anchors.centerIn: parent
                            width: Math.round(34 * Theme.uiScale)
                            height: Math.round(34 * Theme.uiScale)
                            radius: width / 2 // Perfect circular pill
                            border.width: 0

                            color: {
                                if (isToday) return Theme.accent;
                                if (dayMouse.containsMouse && isCurrentMonth) return Qt.rgba(255, 255, 255, 0.08);
                                return "transparent";
                            }

                            Behavior on color { ColorAnimation { duration: 120 } }
                            scale: (dayMouse.pressed && isCurrentMonth) ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: displayDay.toString()
                                color: {
                                    if (isToday) return "#000000"; // Deep contrast on accent circle
                                    if (!isCurrentMonth) return Qt.rgba(Theme.subtextDim.r, Theme.subtextDim.g, Theme.subtextDim.b, 0.28);
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

            // Balanced bottom negative space
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
