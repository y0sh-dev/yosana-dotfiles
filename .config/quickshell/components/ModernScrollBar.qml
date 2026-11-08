import QtQuick
import QtQuick.Controls
import "../services"

// Minimal telemetry scrollbar:
//  - 6px wide handle, 3px radius, accent-tinted.
//  - A 2px near-invisible rail grounds the handle without adding noise.
//  - Fully hidden when scrolling is unnecessary.
//  - Idle → opacity 0.0; scrolling / hover / drag → 0.85 in 250ms.
ScrollBar {
    id: modernBar

    property Flickable targetFlickable: null

    hoverEnabled: true
    policy: ScrollBar.AsNeeded
    visible: targetFlickable ? (targetFlickable.contentHeight > targetFlickable.height) : false

    implicitWidth: 6
    width: 6

    readonly property bool engaged: (targetFlickable && (targetFlickable.moving || targetFlickable.flinging))
                                    || modernBar.hovered || modernBar.active

    opacity: engaged ? 0.85 : 0.0
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    // Faint rail: a whisper of structure, never a visible "track".
    background: Rectangle {
        implicitWidth: 2
        width: 2
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 1
        color: Qt.rgba(255, 255, 255, 0.05)
    }

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 36
        radius: 3
        color: modernBar.engaged
               ? Theme.accent
               : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.65)
        border.width: 1
        border.color: modernBar.engaged
                      ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
                      : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }
}
