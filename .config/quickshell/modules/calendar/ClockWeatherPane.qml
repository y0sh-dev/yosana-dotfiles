import QtQuick
import QtQuick.Layouts
import "../../services"

ColumnLayout {
    id: clockWeatherPaneRoot

    signal openCitySelector()

    readonly property var currentTime: TimeService.now
    spacing: Math.round(14 * Theme.uiScale) // Clear 14px gap between the two cards

    // =========================================================================
    // CARD 1 (TOP): Clock & Date Widget (Surface Container)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(136 * Theme.uiScale)
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1
        radius: Math.round(18 * Theme.uiScale)

        Column {
            anchors.centerIn: parent
            spacing: Math.round(6 * Theme.uiScale)

            // 1. Clock Row: Exact Original Font Sizes (54px / 36px / 16px)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(8 * Theme.uiScale)

                // Hours and minutes (54px fgSoft Bold)
                Text {
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, "hh:mm")
                    color: Theme.fgSoft
                    font.pixelSize: Math.round(54 * Theme.uiScale)
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                // Seconds (36px subtextDim Bold)
                Text {
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, ":ss")
                    color: Theme.subtextDim
                    font.pixelSize: Math.round(36 * Theme.uiScale)
                    font.bold: true
                    font.family: Theme.fontFamily
                    anchors.baseline: parent.children[0].baseline
                }

                // Plain text GMT+9 (16px subtextDim Bold)
                Text {
                    text: "GMT+9"
                    color: Theme.subtextDim
                    font.pixelSize: Math.round(16 * Theme.uiScale)
                    font.bold: true
                    font.family: Theme.fontFamily
                    anchors.baseline: parent.children[0].baseline
                }
            }

            // 2. Weekday & Date: Exact Original Sizes (22px Weekday, 20px Date)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(8 * Theme.uiScale)

                // Weekday (22px bold fgSoft)
                Text {
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, "dddd")
                    color: Theme.fgSoft
                    font.pixelSize: Math.round(22 * Theme.uiScale)
                    font.bold: true
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "·"
                    color: Theme.subtextDim
                    font.pixelSize: Math.round(18 * Theme.uiScale)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Date: Month Day, Year (20px bold)
                Text {
                    text: Qt.formatDateTime(clockWeatherPaneRoot.currentTime, "MMMM d, yyyy")
                    color: Theme.subtextDim
                    font.pixelSize: Math.round(20 * Theme.uiScale)
                    font.bold: true
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // =========================================================================
    // CARD 2 (BOTTOM): Weather & Forecast Widget (Surface Container)
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1
        radius: Math.round(18 * Theme.uiScale)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(18 * Theme.uiScale)
            spacing: Math.round(12 * Theme.uiScale)

            // Section A: Current Weather Prominent Header (Exact Original Font Sizes: Icon 58px, Temp 44px)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(14 * Theme.uiScale)

                // Left: Weather Icon (58px) + [Temp (44px) -> Condition text (15px)]
                Row {
                    spacing: Math.round(14 * Theme.uiScale)
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: WeatherService.icon
                        color: Theme.accent
                        font.pixelSize: Math.round(58 * Theme.uiScale)
                        font.family: Theme.fontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: WeatherService.temp
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(44 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: WeatherService.desc
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(15 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Location Pill + Min/Max Stack (Exact Original 15px)
                Column {
                    spacing: Math.round(8 * Theme.uiScale)
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    // Location Pill
                    Rectangle {
                        implicitWidth: cityRow.implicitWidth + 24
                        implicitHeight: Math.round(30 * Theme.uiScale)
                        radius: height / 2
                        color: cityMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(1, 1, 1, 0.04)
                        border.color: cityMouse.containsMouse ? Theme.accent : Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1

                        Row {
                            id: cityRow
                            anchors.centerIn: parent
                            spacing: Math.round(7 * Theme.uiScale)

                            Text {
                                text: "󰍎"
                                color: Theme.accent
                                font.pixelSize: Math.round(14 * Theme.uiScale)
                                font.family: Theme.fontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: WeatherService.currentRomaji
                                color: Theme.fgSoft
                                font.pixelSize: Math.round(13 * Theme.uiScale)
                                font.bold: true
                                font.family: Theme.fontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "▾"
                                color: Theme.subtextDim
                                font.pixelSize: Math.round(11 * Theme.uiScale)
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

                    // Max / Min Text (15px bold)
                    Row {
                        anchors.right: parent.right
                        spacing: Math.round(8 * Theme.uiScale)

                        Text {
                            text: WeatherService.maxTemp + " ↑"
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(15 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: WeatherService.minTemp + " ↓"
                            color: Theme.subtextDim
                            font.pixelSize: Math.round(15 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }
                }
            }

            // Section B: Minimalist Metrics Pill Row (Rain, Wind, Humidity: Icons 18px, Text 13px bold)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * Theme.uiScale)

                // Metric Pill 1: Rain
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * Theme.uiScale)
                    radius: Math.round(10 * Theme.uiScale)
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(6 * Theme.uiScale)
                        Text {
                            text: "󰖖"
                            color: Theme.accent
                            font.pixelSize: Math.round(18 * Theme.uiScale)
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Rain " + WeatherService.rainChance
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Metric Pill 2: Wind
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * Theme.uiScale)
                    radius: Math.round(10 * Theme.uiScale)
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(6 * Theme.uiScale)
                        Text {
                            text: "󰖝"
                            color: Theme.accent
                            font.pixelSize: Math.round(18 * Theme.uiScale)
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: (WeatherService.windDir ? (WeatherService.windDir + " ") : "") + WeatherService.wind
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Metric Pill 3: Humidity
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * Theme.uiScale)
                    radius: Math.round(10 * Theme.uiScale)
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(6 * Theme.uiScale)
                        Text {
                            text: "󰖎"
                            color: Theme.accent
                            font.pixelSize: Math.round(18 * Theme.uiScale)
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Hum " + WeatherService.humidity
                            color: Theme.fgSoft
                            font.pixelSize: Math.round(13 * Theme.uiScale)
                            font.bold: true
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Divider: Subtle separator before Forecast
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
                opacity: 0.12
            }

            // Section C: Two-Day Forecast Cards (Exact Original Font Sizes: Day 16px, Icon 22px, Temp 15px, Rain/Wind 14px)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(10 * Theme.uiScale)

                Repeater {
                    model: WeatherService.forecast
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(96 * Theme.uiScale)
                        radius: Math.round(12 * Theme.uiScale)
                        color: Qt.rgba(1, 1, 1, 0.02)
                        border.color: Qt.rgba(255, 255, 255, 0.04)
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: Math.round(12 * Theme.uiScale)
                            spacing: Math.round(5 * Theme.uiScale)

                            // Row 1: Day Name (16px bold) + Icon (22px)
                            RowLayout {
                                width: parent.width

                                Text {
                                    text: modelData.day
                                    color: Theme.fgSoft
                                    font.pixelSize: Math.round(16 * Theme.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: modelData.icon
                                    color: Theme.accent
                                    font.pixelSize: Math.round(22 * Theme.uiScale)
                                    font.family: Theme.fontFamily
                                }
                            }

                            // Row 2: Temperatures (Max / Min: 15px bold)
                            Row {
                                spacing: Math.round(6 * Theme.uiScale)
                                Text {
                                    text: "󰔄"
                                    color: Theme.accent
                                    font.pixelSize: Math.round(14 * Theme.uiScale)
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.max + "  /  " + modelData.min
                                    color: Theme.fgSoft
                                    font.pixelSize: Math.round(15 * Theme.uiScale)
                                    font.bold: true
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Row 3: Rain Chance & Wind (14px bold)
                            Row {
                                spacing: Math.round(12 * Theme.uiScale)

                                Row {
                                    spacing: 4
                                    Text {
                                        text: "󰖖"
                                        color: Theme.accent
                                        font.pixelSize: Math.round(14 * Theme.uiScale)
                                        font.family: Theme.fontFamily
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.rainChance
                                        color: Theme.subtextDim
                                        font.pixelSize: Math.round(14 * Theme.uiScale)
                                        font.bold: true
                                        font.family: Theme.fontFamily
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Row {
                                    spacing: 4
                                    Text {
                                        text: "󰖝"
                                        color: Theme.accent
                                        font.pixelSize: Math.round(14 * Theme.uiScale)
                                        font.family: Theme.fontFamily
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: (modelData.windDir ? (modelData.windDir + " ") : "") + modelData.windSpeed
                                        color: Theme.subtextDim
                                        font.pixelSize: Math.round(14 * Theme.uiScale)
                                        font.bold: true
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
    }
}
