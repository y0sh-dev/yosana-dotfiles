import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: calendarRoot

    property bool isOpen: false

    // Real-time ticking clock
    property var currentTime: new Date()
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: calendarRoot.currentTime = new Date()
    }

    // Calendar state
    property int viewYear: currentTime.getFullYear()
    property int viewMonth: currentTime.getMonth() // 0-indexed

    // City selector popover navigation state
    property bool isCitySelectorOpen: false
    property string selectorView: "prefectures" // "prefectures" or "cities"
    property var selectedPrefecture: null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "calendar"
    WlrLayershell.exclusiveZone: -1 // Never squish or resize background windows!
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Center anchored under the clock island
    anchors {
        top: true
    }
    margins.top: 58 // 48 (barHeight) + 4 (topMargin) + 6 (gap)

    // Scaled for WQHD (2560x1440): Width 860px, Height 490px
    implicitWidth: 860
    implicitHeight: 490
    color: "transparent"

    visible: isOpen || contentMonolith.opacity > 0

    // Smooth subtle slide-down & fade
    Rectangle {
        id: contentMonolith
        anchors.fill: parent
        // Deep obsidian black with gentle translucency (84%) allowing Hyprland blur to shine through
        color: Qt.rgba(0, 0, 0, 0.84)
        radius: Theme.radiusIsland // 20px
        border.color: Theme.border
        border.width: 1

        opacity: calendarRoot.isOpen ? 1.0 : 0.0
        transform: Translate {
            y: calendarRoot.isOpen ? 0 : -10
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ====================================================================
        // ABSOLUTE CENTER SEPARATOR (Aligns 100% with screen center & clock)
        // ====================================================================
        Rectangle {
            id: centerAxis
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 20
            anchors.bottomMargin: 20
            width: 1
            color: Theme.border
            opacity: 0.7
        }

        // ====================================================================
        // LEFT COLUMN: Time & Meteorology (Left half: 0 to 430px)
        // ====================================================================
        Item {
            id: leftHalf
            anchors.left: parent.left
            anchors.right: centerAxis.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 20
            anchors.bottomMargin: 20

            // ================================================================
            // VIEW A: Main Info View (Clock + Weather)
            // ================================================================
            Column {
                id: mainWeatherColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 12
                visible: !calendarRoot.isCitySelectorOpen

                // 1. Time & Full Date (Strict geometric center of Left Half)
                Column {
                    width: parent.width
                    spacing: 4

                    // Full Seconds Clock: hh:mm (54px fgSoft) + :ss (36px subtextDim) + plain GMT+9 (16px subtextDim)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        // Hours and minutes (54px eye-friendly soft off-white)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, "hh:mm")
                            color: Theme.fgSoft
                            font.pixelSize: 54
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        // Seconds (36px = 2/3 size, uniform secondary dim)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, ":ss")
                            color: Theme.subtextDim
                            font.pixelSize: 36
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.baseline: parent.children[0].baseline
                        }

                        // Plain text GMT+9 (16px ≈ 1/3 size, uniform secondary dim)
                        Text {
                            text: "GMT+9"
                            color: Theme.subtextDim
                            font.pixelSize: 16
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.baseline: parent.children[0].baseline
                        }
                    }

                    // Weekday & Date (Weekday fgSoft matching hh:mm; Date subtextDim matching :ss & GMT)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        // Weekday (22px bold fgSoft: exactly same brightness as hh:mm)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, "dddd")
                            color: Theme.fgSoft
                            font.pixelSize: 22
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "•"
                            color: Theme.subtextDim
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Month (20px bold, lowercase: november)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, "MMMM").toLowerCase()
                            color: Theme.subtextDim
                            font.pixelSize: 20
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Day with 2-digit fixed reserve width (20px bold)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, "d")
                            color: Theme.subtextDim
                            font.pixelSize: 20
                            font.bold: true
                            font.family: Theme.fontFamily
                            width: font.pixelSize * 1.3
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Year (20px)
                        Text {
                            text: ", " + Qt.formatDateTime(calendarRoot.currentTime, "yyyy")
                            color: Theme.subtextDim
                            font.pixelSize: 20
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Divider 1 (Tightened spacing bringing weather cleanly upwards)
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                    opacity: 0.5
                }

                // 2. Weather Section (Current Weather with JMA Model Data)
                Item {
                    width: parent.width
                    height: 94 // Comfortable height giving generous breathing room

                    // Left Block: Icon (56px) + Temp (44px) -> Below: Condition text (15px)
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7 // Breathing margin between Icon/Temp and condition

                        Row {
                            spacing: 12
                            Text {
                                text: WeatherService.icon
                                color: Theme.accent
                                font.pixelSize: 54
                                font.family: Theme.fontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: WeatherService.temp
                                color: Theme.fgSoft
                                font.pixelSize: 42
                                font.bold: true
                                font.family: Theme.fontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Condition text with gentle breathing margin
                        Text {
                            text: WeatherService.desc
                            color: Theme.subtextDim
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                            width: 175
                        }
                    }

                    // Right Block: Location Pill (Romaji) -> Below: Max & Min Stack
                    Column {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7 // Generous breathing room between Location pill and Max/Min

                        // Location Pill (Romaji representation: Tokyo, Toride, Mito, etc.)
                        Rectangle {
                            implicitWidth: cityRow.implicitWidth + 22
                            implicitHeight: 28
                            radius: 14
                            color: cityMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                            border.color: cityMouse.containsMouse ? Theme.accent : Theme.border
                            border.width: 1

                            Row {
                                id: cityRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰍎"
                                    color: Theme.accent
                                    font.pixelSize: 13
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: WeatherService.currentRomaji
                                    color: Theme.fgSoft
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "▾"
                                    color: Theme.subtextDim
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: cityMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    calendarRoot.selectorView = "prefectures";
                                    calendarRoot.isCitySelectorOpen = true;
                                }
                            }
                        }

                        // Max & Min Temperature Stack
                        Text {
                            text: "最高  " + WeatherService.maxTemp + " ↑"
                            color: Theme.colorSun
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: "最低  " + WeatherService.minTemp + " ↓"
                            color: Theme.colorSat
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }
                }

                // Divider 2
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                    opacity: 0.5
                }

                // 3. Detailed Weather Metrics: Rain Probability, Wind (Dir + Speed), Humidity
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24

                    // 降水確率
                    Row {
                        spacing: 6
                        Text { text: "󰖖"; color: Theme.accent; font.pixelSize: 15; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "降水 " + WeatherService.rainChance; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                    }

                    // 風速 & 風向
                    Row {
                        spacing: 6
                        Text { text: "󰖝"; color: Theme.accent; font.pixelSize: 15; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: (WeatherService.windDir ? (WeatherService.windDir + " ") : "") + WeatherService.wind
                            color: Theme.subtextDim
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // 湿度
                    Row {
                        spacing: 6
                        Text { text: "󰖎"; color: Theme.accent; font.pixelSize: 15; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "湿度 " + WeatherService.humidity; color: Theme.subtextDim; font.pixelSize: 13; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // Divider 3
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                    opacity: 0.5
                }

                // 4. Two-Day Forecast with Temp, Rain Chance, and Wind
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Repeater {
                        model: WeatherService.forecast
                        delegate: Rectangle {
                            implicitWidth: 180
                            implicitHeight: 54
                            radius: 10
                            color: Theme.surface
                            border.color: Theme.border
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                // Row 1: Day + Icon + Max/Min Temp
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 8

                                    Text {
                                        text: modelData.day
                                        color: Theme.fg
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: Theme.fontFamily
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.icon
                                        color: Theme.accent
                                        font.pixelSize: 16
                                        font.family: Theme.fontFamily
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.max + " / " + modelData.min
                                        color: Theme.fgSoft
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: Theme.fontFamily
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Row 2: Rain chance + Wind dir & speed
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 8

                                    Row {
                                        spacing: 4
                                        Text { text: "󰖖"; color: Theme.accent; font.pixelSize: 11; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: modelData.rainChance; color: Theme.subtextDim; font.pixelSize: 11; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                                    }

                                    Row {
                                        spacing: 4
                                        Text { text: "󰖝"; color: Theme.accent; font.pixelSize: 11; font.family: Theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                                        Text {
                                            text: (modelData.windDir ? (modelData.windDir + " ") : "") + modelData.windSpeed
                                            color: Theme.subtextDim
                                            font.pixelSize: 11
                                            font.family: Theme.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================================================================
            // VIEW B: Full 47 Prefectures & Municipalities City Selector
            // ================================================================
            Item {
                id: citySelectorMonolith
                anchors.fill: parent
                visible: calendarRoot.isCitySelectorOpen

                // 1. Navigation Top Bar
                RowLayout {
                    id: selectorHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 34

                    // Left Action: Back (if in cities) or Close (if in prefectures)
                    Rectangle {
                        implicitWidth: backRow.implicitWidth + 14
                        implicitHeight: 28
                        radius: 6
                        color: backMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.color: Theme.border
                        border.width: 1

                        Row {
                            id: backRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: calendarRoot.selectorView === "cities" ? "‹" : "✕"
                                color: Theme.accent
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: calendarRoot.selectorView === "cities" ? "戻る" : "閉じる"
                                color: Theme.fg
                                font.pixelSize: 12
                                font.bold: true
                                font.family: Theme.fontFamily
                            }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (calendarRoot.selectorView === "cities") {
                                    calendarRoot.selectorView = "prefectures";
                                } else {
                                    calendarRoot.isCitySelectorOpen = false;
                                }
                            }
                        }
                    }

                    // Center: Title of the current selector level
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            if (calendarRoot.selectorView === "cities" && calendarRoot.selectedPrefecture) {
                                return calendarRoot.selectedPrefecture.name + " (" + calendarRoot.selectedPrefecture.romaji + ")";
                            }
                            return "地域を選択 (47都道府県)";
                        }
                        color: Theme.fgSoft
                        font.pixelSize: 14
                        font.bold: true
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                    }

                    // Right Action: "この県で決定" (Save / Select prefecture as whole)
                    Rectangle {
                        visible: calendarRoot.selectorView === "cities" && calendarRoot.selectedPrefecture !== null
                        implicitWidth: selectPrefRow.implicitWidth + 14
                        implicitHeight: 28
                        radius: 6
                        color: selectPrefMouse.containsMouse ? Theme.accent : Theme.surface
                        border.color: Theme.accent
                        border.width: 1

                        Row {
                            id: selectPrefRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "󰄬"
                                color: selectPrefMouse.containsMouse ? "#000000" : Theme.accent
                                font.pixelSize: 12
                            }
                            Text {
                                text: "県全体で決定"
                                color: selectPrefMouse.containsMouse ? "#000000" : Theme.fg
                                font.pixelSize: 12
                                font.bold: true
                                font.family: Theme.fontFamily
                            }
                        }

                        MouseArea {
                            id: selectPrefMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (calendarRoot.selectedPrefecture) {
                                    var pref = calendarRoot.selectedPrefecture;
                                    WeatherService.setCity({
                                        name: pref.name,
                                        romaji: pref.romaji,
                                        lat: pref.lat,
                                        lon: pref.lon
                                    }, pref.name);
                                    calendarRoot.isCitySelectorOpen = false;
                                }
                            }
                        }
                    }
                }

                // 2. Scrollable Content Area (Prefectures Grid OR Cities Grid)
                Rectangle {
                    anchors.top: selectorHeader.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 8
                    color: "transparent"
                    clip: true

                    Flickable {
                        id: selectorFlickable
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: contentColumn.height + 16
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            id: vbar
                            active: true
                            policy: ScrollBar.AsNeeded
                        }

                        Column {
                            id: contentColumn
                            width: parent.width - (vbar.visible ? 12 : 0)
                            spacing: 8

                            // --- SUBVIEW 1: 47 Prefectures Grid ---
                            GridLayout {
                                id: prefGrid
                                width: parent.width
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 8
                                visible: calendarRoot.selectorView === "prefectures"

                                Repeater {
                                    model: WeatherService.locations
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 38
                                        radius: 8
                                        color: prefItemMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                                        border.color: WeatherService.currentPref === modelData.name ? Theme.accent : Theme.border
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12

                                            Text {
                                                text: modelData.name
                                                color: WeatherService.currentPref === modelData.name ? Theme.accent : Theme.fg
                                                font.pixelSize: 13
                                                font.bold: true
                                                font.family: Theme.fontFamily
                                            }

                                            Item { Layout.fillWidth: true }

                                            Text {
                                                text: modelData.romaji
                                                color: Theme.subtextDim
                                                font.pixelSize: 11
                                                font.family: Theme.fontFamily
                                            }

                                            Text {
                                                text: "›"
                                                color: Theme.subtextDim
                                                font.pixelSize: 14
                                            }
                                        }

                                        MouseArea {
                                            id: prefItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                calendarRoot.selectedPrefecture = modelData;
                                                calendarRoot.selectorView = "cities";
                                                selectorFlickable.contentY = 0;
                                            }
                                        }
                                    }
                                }
                            }

                            // --- SUBVIEW 2: Municipalities Grid for Selected Prefecture ---
                            GridLayout {
                                id: cityGrid
                                width: parent.width
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 8
                                visible: calendarRoot.selectorView === "cities"

                                Repeater {
                                    model: (calendarRoot.selectedPrefecture && calendarRoot.selectedPrefecture.cities) ? calendarRoot.selectedPrefecture.cities : []
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 38
                                        radius: 8
                                        color: cityItemMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                                        border.color: WeatherService.currentCityName === modelData.name ? Theme.accent : Theme.border
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12

                                            Text {
                                                text: modelData.name
                                                color: WeatherService.currentCityName === modelData.name ? Theme.accent : Theme.fg
                                                font.pixelSize: 13
                                                font.bold: WeatherService.currentCityName === modelData.name
                                                font.family: Theme.fontFamily
                                            }

                                            Item { Layout.fillWidth: true }

                                            Text {
                                                text: modelData.romaji
                                                color: Theme.subtextDim
                                                font.pixelSize: 11
                                                font.family: Theme.fontFamily
                                            }
                                        }

                                        MouseArea {
                                            id: cityItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                WeatherService.setCity(modelData, calendarRoot.selectedPrefecture ? calendarRoot.selectedPrefecture.name : "");
                                                calendarRoot.isCitySelectorOpen = false;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ====================================================================
        // RIGHT COLUMN: Calendar Enclosure (Right half: 430px to 860px)
        // ====================================================================
        Item {
            id: rightHalf
            anchors.left: centerAxis.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 20

            // Solid Framed Enclosure Card for Calendar
            Rectangle {
                anchors.fill: parent
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                radius: 14

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // 1. Navigation Header: Bi-split Capsule Navigation (◀ Month ▶ / ◀ Year ▶)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // ─── Bi-split Month Capsule ───
                        Rectangle {
                            id: monthCapsule
                            implicitWidth: 190
                            implicitHeight: 36
                            radius: 18
                            color: "transparent"
                            border.color: Theme.border
                            border.width: 1
                            clip: true

                            // Left-half rounded highlight (Previous Month)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                radius: 18
                                color: prevMonthArea.containsMouse ? Theme.surfaceHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Right-half rounded highlight (Next Month)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                radius: 18
                                color: nextMonthArea.containsMouse ? Theme.surfaceHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Center Content
                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "◀"
                                    color: prevMonthArea.containsMouse ? Theme.accent : Theme.subtext
                                    font.pixelSize: 13
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                Text {
                                    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                                    text: monthNames[calendarRoot.viewMonth]
                                    color: Theme.fg
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                }

                                Text {
                                    text: "▶"
                                    color: nextMonthArea.containsMouse ? Theme.accent : Theme.subtext
                                    font.pixelSize: 13
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }

                            // Left-half hit area (◀ to center)
                            MouseArea {
                                id: prevMonthArea
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (calendarRoot.viewMonth === 0) {
                                        calendarRoot.viewMonth = 11;
                                        calendarRoot.viewYear--;
                                    } else {
                                        calendarRoot.viewMonth--;
                                    }
                                }
                            }

                            // Right-half hit area (center to ▶)
                            MouseArea {
                                id: nextMonthArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (calendarRoot.viewMonth === 11) {
                                        calendarRoot.viewMonth = 0;
                                        calendarRoot.viewYear++;
                                    } else {
                                        calendarRoot.viewMonth++;
                                    }
                                }
                            }
                        }

                        // ─── Bi-split Year Capsule ───
                        Rectangle {
                            id: yearCapsule
                            implicitWidth: 120
                            implicitHeight: 36
                            radius: 18
                            color: "transparent"
                            border.color: Theme.border
                            border.width: 1
                            clip: true

                            // Left-half rounded highlight (Previous Year)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                radius: 18
                                color: prevYearArea.containsMouse ? Theme.surfaceHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Right-half rounded highlight (Next Year)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                radius: 18
                                color: nextYearArea.containsMouse ? Theme.surfaceHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Center Content
                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "◀"
                                    color: prevYearArea.containsMouse ? Theme.accent : Theme.subtext
                                    font.pixelSize: 12
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                Text {
                                    text: calendarRoot.viewYear.toString()
                                    color: Theme.fg
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                }

                                Text {
                                    text: "▶"
                                    color: nextYearArea.containsMouse ? Theme.accent : Theme.subtext
                                    font.pixelSize: 12
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }

                            // Left-half hit area (◀ to center)
                            MouseArea {
                                id: prevYearArea
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarRoot.viewYear--
                            }

                            // Right-half hit area (center to ▶)
                            MouseArea {
                                id: nextYearArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width / 2
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarRoot.viewYear++
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // ─── Reset to Today Button ───
                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 18
                            color: todayMouse.containsMouse ? Theme.surfaceHover : "transparent"
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰃭"
                                color: todayMouse.containsMouse ? Theme.accent : Theme.subtext
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: todayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    calendarRoot.viewYear = calendarRoot.currentTime.getFullYear();
                                    calendarRoot.viewMonth = calendarRoot.currentTime.getMonth();
                                }
                            }
                        }
                    }

                    // 2. Weekday Header (Sun=Red, Mon-Fri=Subtext, Sat=Blue)
                    Row {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: [
                                { name: "Sun", color: Theme.colorSun },  // Pywal Red
                                { name: "Mon", color: Theme.subtext },
                                { name: "Tue", color: Theme.subtext },
                                { name: "Wed", color: Theme.subtext },
                                { name: "Thu", color: Theme.subtext },
                                { name: "Fri", color: Theme.subtext },
                                { name: "Sat", color: Theme.colorSat }   // Pywal Blue
                            ]
                            delegate: Item {
                                width: (rightHalf.width - 72) / 7
                                height: 28
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: modelData.color
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                }
                            }
                        }
                    }

                    // 3. Days Grid (42 Cells: 7 cols x 6 rows)
                    GridLayout {
                        columns: 7
                        rowSpacing: 4
                        columnSpacing: 0
                        Layout.fillWidth: true

                        Repeater {
                            model: 42
                            delegate: Item {
                                implicitWidth: (rightHalf.width - 72) / 7
                                implicitHeight: 34

                                readonly property int firstDayOfWeek: new Date(calendarRoot.viewYear, calendarRoot.viewMonth, 1).getDay()
                                readonly property int daysInCurrentMonth: new Date(calendarRoot.viewYear, calendarRoot.viewMonth + 1, 0).getDate()
                                readonly property int daysInPrevMonth: new Date(calendarRoot.viewYear, calendarRoot.viewMonth, 0).getDate()

                                readonly property int dayOffset: index - firstDayOfWeek + 1
                                readonly property bool isCurrentMonth: dayOffset > 0 && dayOffset <= daysInCurrentMonth
                                readonly property int displayDay: {
                                    if (dayOffset <= 0) return daysInPrevMonth + dayOffset;
                                    if (dayOffset > daysInCurrentMonth) return dayOffset - daysInCurrentMonth;
                                    return dayOffset;
                                }

                                readonly property bool isToday: isCurrentMonth &&
                                    calendarRoot.viewYear === calendarRoot.currentTime.getFullYear() &&
                                    calendarRoot.viewMonth === calendarRoot.currentTime.getMonth() &&
                                    displayDay === calendarRoot.currentTime.getDate()

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 32; height: 32
                                    radius: 16
                                    color: {
                                        if (isToday) return Theme.accent;
                                        if (dayMouse.containsMouse) return Theme.surfaceHover;
                                        return "transparent";
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: displayDay.toString()
                                        color: {
                                            if (isToday) return "#000000"; // Black high-contrast on solid accent pill
                                            if (!isCurrentMonth) return "#252c38"; // Quiet dim tone for other months
                                            if (index % 7 === 0) return Theme.colorSun; // Sunday Red
                                            if (index % 7 === 6) return Theme.colorSat; // Saturday Blue
                                            return Theme.fg;
                                        }
                                        font.pixelSize: 14
                                        font.bold: isToday
                                        font.family: Theme.fontFamily
                                    }
                                }

                                MouseArea {
                                    id: dayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
