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
    WlrLayershell.exclusiveZone: -1 // Never squish or resize background windows
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Center anchored under the clock island
    anchors {
        top: true
    }
    margins.top: Math.round(58 * Theme.uiScale) // 48 (barHeight) + 4 (topMargin) + 6 (gap)

    // Baseline dimensions: 920px x 472px
    // At uiScale 1.0 this yields 432x432 square cards:
    //   width  = (920 - 2*20 margins - 16 gap) / 2 = 432
    //   height = 472 - 2*20 margins = 432
    // Shrinking from 540 to 472 removes the ~92px calendar bottom void while
    // preserving the deliberate 56px weekday->date breathing space.
    implicitWidth: Math.round(920 * Theme.uiScale)
    implicitHeight: Math.round(472 * Theme.uiScale)
    color: "transparent"

    visible: isOpen || contentMonolith.opacity > 0

    // Smooth subtle slide-down & fade
    Rectangle {
        id: contentMonolith
        anchors.fill: parent
        // Deep obsidian black with gentle translucency (90%) allowing Hyprland blur to shine through
        color: Qt.rgba(0, 0, 0, 0.90)
        radius: Math.round(Theme.radiusIsland * Theme.uiScale) // 20px
        border.width: 0

        opacity: calendarRoot.isOpen ? 1.0 : 0.0
        transform: Translate {
            y: calendarRoot.isOpen ? 0 : -10
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ====================================================================
        // UNIFIED CARD LAYOUT: Left (Clock/Date & Weather) + Right (Calendar)
        // Clean Proximity: Generous external padding and 16px inter-card space
        // ====================================================================
        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.round(20 * Theme.uiScale)
            spacing: Math.round(16 * Theme.uiScale)

            // LEFT COLUMN (Clock & Date Card + Weather Card)
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1

                ClockWeatherPane {
                    anchors.fill: parent
                    visible: !calendarRoot.isCitySelectorOpen
                    onOpenCitySelector: {
                        citySelectorModal.reset();
                        calendarRoot.isCitySelectorOpen = true;
                    }
                }

                CitySelectorModal {
                    id: citySelectorModal
                    anchors.fill: parent
                    visible: calendarRoot.isCitySelectorOpen
                    onCloseRequested: {
                        calendarRoot.isCitySelectorOpen = false;
                    }
                }
            }

            // RIGHT COLUMN (Calendar Card)
            MonthView {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1
            }
        }
    }
}
