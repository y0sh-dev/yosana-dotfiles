import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../modules/calendar"

PanelWindow {
    id: calendarRoot

    property bool isOpen: false

    // Switch TimeService to 1-second precision only while opened; otherwise drops to zero-idle minute sync
    onIsOpenChanged: {
        TimeService.highPrecision = isOpen;
        if (!isOpen) {
            isCitySelectorOpen = false;
        }
    }

    // City selector popover navigation state
    property bool isCitySelectorOpen: false

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

            // VIEW A: Main Clock & Weather Info
            ClockWeatherPane {
                anchors.fill: parent
                visible: !calendarRoot.isCitySelectorOpen
                onOpenCitySelector: {
                    citySelectorModal.reset();
                    calendarRoot.isCitySelectorOpen = true;
                }
            }

            // VIEW B: Full 47 Prefectures & Municipalities City Selector Modal
            CitySelectorModal {
                id: citySelectorModal
                anchors.fill: parent
                visible: calendarRoot.isCitySelectorOpen
                onCloseRequested: {
                    calendarRoot.isCitySelectorOpen = false;
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

            MonthView {
                anchors.fill: parent
            }
        }
    }
}
