import QtQuick

Rectangle {
    id: root

    default property alias content: container.data

    property int hPadding: 12
    property int customSpacing: 6

    property color podBg: "#0f0f11"
    property color podBorder: "#eeeeee"

    width: Math.max(
        32,
        container.implicitWidth + (hPadding * 2)
    )

    height: 32
    radius: 16

    color: Qt.rgba(
        podBg.r,
        podBg.g,
        podBg.b,
        0.86
    )

    border.color: Qt.rgba(
        podBorder.r,
        podBorder.g,
        podBorder.b,
        0.15
    )

    border.width: 1

    scale:
        hoverArea.containsMouse
            ? 1.05
            : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutBack
        }
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent

        hoverEnabled: true

        acceptedButtons:
            Qt.NoButton
    }

    Row {
        id: container

        anchors.centerIn: parent

        spacing:
            root.customSpacing
    }
}