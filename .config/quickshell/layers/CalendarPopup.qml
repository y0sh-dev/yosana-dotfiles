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
    margins.top: Math.round(58 * Theme.uiScale) // 48 (barHeight) + 4 (topMargin) + 6 (gap)

    // Scaled adaptively via Theme.uiScale: WQHD baseline 860px x 490px
    // 1080p: ~645px x 368px, 1440p: 860px x 490px, 4K: 1290px x 735px
    implicitWidth: Math.round(860 * Theme.uiScale)
    implicitHeight: Math.round(490 * Theme.uiScale)
    color: "transparent"

    visible: isOpen || contentMonolith.opacity > 0

    // Smooth subtle slide-down & fade
    Rectangle {
        id: contentMonolith
        anchors.fill: parent
        // Deep obsidian black with gentle translucency (90%) allowing Hyprland blur to shine through
        color: Qt.rgba(0, 0, 0, 0.90)
        radius: Math.round(Theme.radiusIsland * Theme.uiScale) // ~20px
        border.width: 0 // Pure matte aesthetic: zero harsh border lines

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
            anchors.topMargin: Math.round(20 * Theme.uiScale)
            anchors.bottomMargin: Math.round(20 * Theme.uiScale)
            width: 1
            color: Theme.border
            opacity: 0.25 // Subtle matte separation
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
            anchors.leftMargin: Math.round(24 * Theme.uiScale)
            anchors.rightMargin: Math.round(24 * Theme.uiScale)
            anchors.topMargin: Math.round(20 * Theme.uiScale)
            anchors.bottomMargin: Math.round(20 * Theme.uiScale)

            // ================================================================
            // VIEW A: Main Info View (Clock + Weather)
            // Vertically centered inside leftHalf: exact equal breathing room top & bottom
            // ================================================================
            Column {
                id: mainWeatherColumn
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0
                visible: !calendarRoot.isCitySelectorOpen

                // 1. Time & Full Date (Strict geometric center of Left Half)
                Column {
                    width: parent.width
                    spacing: 4

                    // Full Seconds Clock: hh:mm (54px fgSoft) + :ss (36px subtextDim) + plain GMT+9 (16px subtextDim)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Math.round(8 * Theme.uiScale)

                        // Hours and minutes (54px eye-friendly soft off-white)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, "hh:mm")
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(54 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        // Seconds (36px = 2/3 size, uniform secondary dim)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, ":ss")
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(36 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.baseline: parent.children[0].baseline
                        }

                        // Plain text GMT+9 (16px ≈ 1/3 size, uniform secondary dim)
                        Text {
                            text: "GMT+9"
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(16 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.baseline: parent.children[0].baseline
                        }
                    }

                    // Weekday & Date (Weekday fgSoft matching hh:mm; Date subtextDim matching :ss & GMT)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Math.round(8 * Theme.uiScale)

                        // Weekday (22px bold fgSoft: exactly same brightness as hh:mm)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, "dddd")
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(22 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "•"
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(16 * Theme.uiScale)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Month (20px bold, lowercase: november)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, "MMMM").toLowerCase()
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(20 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Day with 2-digit fixed reserve width (20px bold)
                        Text {
                            text: Qt.formatDateTime(calendarRoot.currentTime, "d")
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(20 * Theme.uiScale)
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
                            font.pixelSize: Math.round(20 * Theme.uiScale)
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Breathing Space between Time & Weather (Refined target spacing: 14px + 1px line + 14px)
                Item { width: 1; height: 14 }
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                    opacity: 0.2 // Soft matte line
                }
                Item { width: 1; height: 14 }

                // 2. Weather Section (Current Weather with JMA Model Data)
                Item {
                    width: parent.width
                    height: 88 // Generous height for unconstrained breathing space

                    // Left Block: Icon (58px) + [Temp (44px) -> Directly Below: Condition text (15px)]
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Text {
                            text: WeatherService.icon
                            color: Theme.accent
                            font.pixelSize: 58
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Column: Temperature on top, Condition directly underneath temperature
                        Column {
                            spacing: 3
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: WeatherService.temp
                                color: Theme.fgSoft
                                font.pixelSize: 44
                                font.bold: true
                                font.family: Theme.fontFamily
                            }

                            Text {
                                text: WeatherService.desc
                                color: Theme.subtext
                                font.pixelSize: 15
                                font.bold: true
                                font.family: Theme.fontFamily
                                elide: Text.ElideRight
                                width: 150
                            }
                        }
                    }

                    // Right Block: Location Pill -> Directly Below: Max & Min Temperature Stack (Generous 10px spacing)
                    Column {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9 // Relaxed breathing room between location pill and temps

                        // Location Pill (Romaji representation: Tokyo, Toride, Mito, etc.)
                        Rectangle {
                            implicitWidth: cityRow.implicitWidth + 24
                            implicitHeight: 30
                            radius: 15
                            color: cityMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                            border.color: cityMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.4)
                            border.width: 1

                            Row {
                                id: cityRow
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: "󰍎"
                                    color: Theme.accent
                                    font.pixelSize: 14
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

                        // Max & Min Temperature Stack (Soft off-white matching surrounding text, zero glare)
                        Text {
                            text: "最高  " + WeatherService.maxTemp + " ↑"
                            color: Theme.fgSoft
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: "最低  " + WeatherService.minTemp + " ↓"
                            color: Theme.fgSoft
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }
                }

                // Breathing Space between Weather and Metrics
                Item { width: 1; height: 6 }
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                    opacity: 0.2 // Soft matte line
                }
                Item { width: 1; height: 6 }

                // 3. Detailed Weather Metrics: Vertical Hierarchy (Icon on top, stat below)
                // [ Icon ]      [ Icon ]      [ Icon ]
                // 降水 10%    北 5km/h       湿度 45%
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 38

                    // 降水確率
                    Column {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "󰖖"
                            color: Theme.accent
                            font.pixelSize: 22
                            font.family: Theme.fontFamily
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "降水 " + WeatherService.rainChance
                            color: Theme.fgSoft
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // 風速 & 風向
                    Column {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "󰖝"
                            color: Theme.accent
                            font.pixelSize: 22
                            font.family: Theme.fontFamily
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: (WeatherService.windDir ? (WeatherService.windDir + " ") : "") + WeatherService.wind
                            color: Theme.fgSoft
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // 湿度
                    Column {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "󰖎"
                            color: Theme.accent
                            font.pixelSize: 22
                            font.family: Theme.fontFamily
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "湿度 " + WeatherService.humidity
                            color: Theme.fgSoft
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Breathing Space between Metrics and Forecast Cards
                Item { width: 1; height: 18 }
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                    opacity: 0.2 // Soft matte line
                }
                Item { width: 1; height: 18 }

                // 4. Two-Day Forecast: Frameless Minimalist Layout with Single Thin Subtle Divider
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Repeater {
                        model: WeatherService.forecast
                        delegate: Row {
                            spacing: 16

                            // Day Column
                            Item {
                                implicitWidth: 164
                                implicitHeight: 104

                                Column {
                                    anchors.fill: parent
                                    spacing: 5

                                    // Row 1: Day (TUE / WED) + Forecast Weather Icon
                                    RowLayout {
                                        width: parent.width

                                        Text {
                                            text: modelData.day
                                            color: Theme.fgSoft
                                            font.pixelSize: 16
                                            font.bold: true
                                            font.family: Theme.fontFamily
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: modelData.icon
                                            color: Theme.accent
                                            font.pixelSize: 22
                                            font.family: Theme.fontFamily
                                        }
                                    }

                                    // Row 2: 気温 (Max / Min) - Prominent 15px bold
                                    Row {
                                        spacing: 8
                                        Text {
                                            text: "󰔄"
                                            color: Theme.accent
                                            font.pixelSize: 15
                                            font.family: Theme.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: modelData.max + "  /  " + modelData.min
                                            color: Theme.fgSoft
                                            font.pixelSize: 15
                                            font.bold: true
                                            font.family: Theme.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    // Row 3: 降水確率 - Prominent 14px bold
                                    Row {
                                        spacing: 8
                                        Text {
                                            text: "󰖖"
                                            color: Theme.accent
                                            font.pixelSize: 15
                                            font.family: Theme.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "降水 " + modelData.rainChance
                                            color: Theme.fgSoft
                                            font.pixelSize: 14
                                            font.bold: true
                                            font.family: Theme.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    // Row 4: 風速 & 風向 - Prominent 14px bold
                                    Row {
                                        spacing: 8
                                        Text {
                                            text: "󰖝"
                                            color: Theme.accent
                                            font.pixelSize: 15
                                            font.family: Theme.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: (modelData.windDir ? (modelData.windDir + " ") : "") + modelData.windSpeed
                                            color: Theme.fgSoft
                                            font.pixelSize: 14
                                            font.bold: true
                                            font.family: Theme.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            // Subtle vertical separator between tomorrow and day-after-tomorrow
                            Rectangle {
                                visible: index === 0
                                width: 1
                                height: 84
                                color: Theme.border
                                opacity: 0.25
                                anchors.verticalCenter: parent.verticalCenter
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
            anchors.margins: Math.round(20 * Theme.uiScale)

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
                            if (calendarRoot.viewMonth === 0) {
                                calendarRoot.viewMonth = 11;
                                calendarRoot.viewYear--;
                            } else {
                                calendarRoot.viewMonth--;
                            }
                        } else if (wheel.angleDelta.y < 0) {
                            if (calendarRoot.viewMonth === 11) {
                                calendarRoot.viewMonth = 0;
                                calendarRoot.viewYear++;
                            } else {
                                calendarRoot.viewMonth++;
                            }
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
                                    text: monthNames[calendarRoot.viewMonth]
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
                                anchors.left: monthDivider.right
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
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
                                    text: calendarRoot.viewYear.toString()
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
                                onClicked: calendarRoot.viewYear--
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
                                onClicked: calendarRoot.viewYear++
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
                                onClicked: {
                                    calendarRoot.viewYear = calendarRoot.currentTime.getFullYear();
                                    calendarRoot.viewMonth = calendarRoot.currentTime.getMonth();
                                }
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
                        height: Math.round(32 * Theme.uiScale)
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
    }
}
