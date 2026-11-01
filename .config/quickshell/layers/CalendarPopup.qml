import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: calendarRoot
    property bool isOpen: false
    property string dateText: ""
    
    readonly property date today: new Date()
    property int viewMonth: today.getMonth()
    property int viewYear: today.getFullYear()

    function getDaysInMonth(m, y) { return new Date(y, m + 1, 0).getDate(); }
    function getFirstDay(m, y) { return new Date(y, m, 1).getDay(); }

    WlrLayershell.layer: WlrLayershell.Overlay
    
    // 修正ポイント: horizontalCenter を削除
    // top だけを true にし、left/right を指定しないことで中央配置になります
    anchors {
        top: true
    }
    
    margins.top: 45
    implicitWidth: 320
    implicitHeight: 380
    
    visible: isOpen || content.opacity > 0

    Rectangle {
        id: content
        anchors.fill: parent
        color: "#1a1b26"
        radius: 12
        border.color: "#333"
        border.width: 1
        
        opacity: calendarRoot.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: dateText
                color: "#7aa2f7"
                font.pixelSize: 18
                font.bold: true
            }

            Row {
                spacing: 0
                Layout.fillWidth: true
                Repeater {
                    model: ["日", "月", "火", "水", "木", "金", "土"]
                    delegate: Text {
                        width: (calendarRoot.implicitWidth - 40) / 7
                        text: modelData
                        color: "#565f89"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            GridLayout {
                columns: 7
                rowSpacing: 10
                columnSpacing: 0
                Layout.fillWidth: true

                Repeater {
                    model: 42 
                    delegate: Item {
                        implicitWidth: (calendarRoot.implicitWidth - 40) / 7
                        implicitHeight: 30

                        readonly property int dayNum: index - calendarRoot.getFirstDay(calendarRoot.viewMonth, calendarRoot.viewYear) + 1
                        readonly property bool isCurrentMonth: dayNum > 0 && dayNum <= calendarRoot.getDaysInMonth(calendarRoot.viewMonth, calendarRoot.viewYear)
                        readonly property bool isToday: isCurrentMonth && dayNum === calendarRoot.today.getDate() && calendarRoot.viewMonth === calendarRoot.today.getMonth()

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28; height: 28
                            radius: 14
                            color: isToday ? "#7aa2f7" : "transparent"
                            opacity: 0.3
                            visible: isToday
                        }

                        Text {
                            anchors.centerIn: parent
                            text: isCurrentMonth ? dayNum : ""
                            color: isToday ? "#7aa2f7" : (isCurrentMonth ? "white" : "transparent")
                            font.pixelSize: 14
                            font.bold: isToday
                        }
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
}
