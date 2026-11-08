import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../services"

Item {
    id: citySelectorRoot

    signal closeRequested()

    property string selectorView: "prefectures" // "prefectures" or "cities"
    property var selectedPrefecture: null

    function reset() {
        selectorView = "prefectures";
        selectedPrefecture = null;
    }

    // Unified Surface Container Card
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1
        radius: Math.round(18 * Theme.uiScale)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(16 * Theme.uiScale)
            spacing: Math.round(10 * Theme.uiScale)

            // 1. Navigation Top Bar
            RowLayout {
                id: selectorHeader
                Layout.fillWidth: true
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
                            text: citySelectorRoot.selectorView === "cities" ? "‹" : "✕"
                            color: Theme.accent
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            text: citySelectorRoot.selectorView === "cities" ? "Back" : "Close"
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
                            if (citySelectorRoot.selectorView === "cities") {
                                citySelectorRoot.selectorView = "prefectures";
                            } else {
                                citySelectorRoot.closeRequested();
                            }
                        }
                    }
                }

                // Center: Title of the current selector level
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        if (citySelectorRoot.selectorView === "cities" && citySelectorRoot.selectedPrefecture) {
                            return citySelectorRoot.selectedPrefecture.name + " (" + citySelectorRoot.selectedPrefecture.romaji + ")";
                        }
                        return "Select Region (47 Prefectures)";
                    }
                    color: Theme.fgSoft
                    font.pixelSize: 14
                    font.bold: true
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                }

                // Right Action: "Select Prefecture" (Save / Select prefecture as whole)
                Rectangle {
                    visible: citySelectorRoot.selectorView === "cities" && citySelectorRoot.selectedPrefecture !== null
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
                            text: "Select Prefecture"
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
                            if (citySelectorRoot.selectedPrefecture) {
                                var pref = citySelectorRoot.selectedPrefecture;
                                WeatherService.setCity({
                                    name: pref.name,
                                    romaji: pref.romaji,
                                    lat: pref.lat,
                                    lon: pref.lon
                                }, pref.name);
                                citySelectorRoot.closeRequested();
                            }
                        }
                    }
                }
            }

            // 2. Scrollable Content Area (Prefectures Grid OR Cities Grid)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
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
                    visible: citySelectorRoot.selectorView === "prefectures"

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
                                    citySelectorRoot.selectedPrefecture = modelData;
                                    citySelectorRoot.selectorView = "cities";
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
                    visible: citySelectorRoot.selectorView === "cities"

                    Repeater {
                        model: (citySelectorRoot.selectedPrefecture && citySelectorRoot.selectedPrefecture.cities) ? citySelectorRoot.selectedPrefecture.cities : []
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
                                    WeatherService.setCity(modelData, citySelectorRoot.selectedPrefecture ? citySelectorRoot.selectedPrefecture.name : "");
                                    citySelectorRoot.closeRequested();
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
}
