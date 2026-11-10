import QtQuick
import QtQuick.Layouts
import "../services"

// Ghost instrument pill. Never a consumer toggle: a dark recessed capsule that
// lights with a thin accent edge only when touched. `accent` marks a primary
// action; `dim` renders a disabled state.
Rectangle {
    id: pill

    property string label: ""
    property string glyph: ""
    property bool accent: false
    property bool dim: false

    signal tapped()

    implicitHeight: Math.round(28 * Theme.uiScale)
    implicitWidth: pillRow.implicitWidth + 22
    radius: height / 2

    readonly property bool hovered: pillMouse.containsMouse && !pill.dim

    color: pill.accent
           ? (pill.hovered
              ? Qt.tint(Theme.surfaceHover, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25))
              : Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)))
           : (pill.hovered ? Theme.surfaceHover : Qt.rgba(0, 0, 0, 0.42))
    border.color: pill.accent ? Theme.accent
                 : (pill.hovered ? Theme.accent : Qt.rgba(255, 255, 255, 0.08))
    border.width: 1
    opacity: pill.dim ? 0.4 : 1.0

    scale: (pillMouse.pressed && !pill.dim) ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 90 } }
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on opacity { NumberAnimation { duration: 120 } }

    RowLayout {
        id: pillRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: pill.glyph.length > 0
            text: pill.glyph
            color: pill.accent ? Theme.accent : Theme.subtextDim
            font.pixelSize: Math.round(12 * Theme.uiScale)
            font.family: Theme.fontFamily
        }

        Text {
            text: pill.label
            color: pill.accent ? Theme.accent : (pill.hovered ? Theme.fg : Theme.fgSoft)
            font.pixelSize: Math.round(10 * Theme.uiScale)
            font.bold: true
            font.letterSpacing: 0.8
            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        enabled: !pill.dim
        hoverEnabled: true
        cursorShape: pill.dim ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: pill.tapped()
    }
}
