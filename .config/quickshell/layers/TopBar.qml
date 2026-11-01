import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"

PanelWindow {
    property int focusedWs: 0
    property var displayedWs: []
    property var occupiedWs: []
    property string timeText: ""

    signal clockClicked()
    signal volumeClicked()
    signal networkClicked()
    signal powerClicked()

    WlrLayershell.layer: WlrLayershell.Top
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    implicitHeight: 40
    exclusiveZone: implicitHeight
    color: "#1a1b26"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15

        // 左：ワークスペース
        Workspaces {
            activeId: focusedWs
            displayedList: displayedWs
            occupiedList: occupiedWs
        }

        Item { Layout.fillWidth: true }

        // 中央：時計
        Clock {
            displayTime: timeText
            onClicked: clockClicked()
        }

        Item { Layout.fillWidth: true }
        
        // 右：ボリューム / ネットワーク / 電源
        RowLayout {
            spacing: 16
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            Volume {
                onClicked: volumeClicked()
            }

            Network {
                onClicked: networkClicked()
            }

            PowerButton {
                onClicked: powerClicked()
            }
        }
    }
}
