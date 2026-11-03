import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
    id: clockWeatherPaneRoot

    signal openCitySelector()

    readonly property var currentTime: TimeService.now

    Column {
        id: mainWeatherColumn
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

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
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, "hh:mm")
                    color: Theme.fgSoft
                    font.pixelSize: Math.round(54 * Theme.uiScale)
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                // Seconds (36px = 2/3 size, uniform secondary dim)
                Text {
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, ":ss")
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
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, "dddd")
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
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, "MMMM").toLowerCase()
                    color: Theme.subtextDim
                    font.pixelSize: Math.round(20 * Theme.uiScale)
                    font.bold: true
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Day with 2-digit fixed reserve width (20px bold)
                Text {
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, "d")
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
                    text: ", " + Qt.formatDateTime(clockWeatherPaneRoot.currentTime, "yyyy")
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
                        onClicked: clockWeatherPaneRoot.openCitySelector()
                    }
                }

                // Max & Min Temperature Stack (Soft off-white matching surrounding text, zero glare)
                Text {
                    text: "Max  " + WeatherService.maxTemp + " ↑"
                    color: Theme.fgSoft
                    font.pixelSize: 15
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                Text {
                    text: "Min  " + WeatherService.minTemp + " ↓"
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
                    text: "Rain " + WeatherService.rainChance
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
                    text: "Humidity " + WeatherService.humidity
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
                                    text: "Rain " + modelData.rainChance
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
}
