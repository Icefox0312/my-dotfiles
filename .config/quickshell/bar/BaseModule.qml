import QtQuick

Rectangle {
    id: root
    
    property string textContent: "?"
    property int fontSize: 15
    property color fgColor: "#eeeeee"
    
    // Explicit sizing so the layout never collapses
    width: Math.max(40, textItem.implicitWidth + 24)
    height: 32
    radius: 17
    
    // Matching your Waybar CSS colors
    color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0.06, 0.06, 0.07, 0.86)
    border.color: Qt.rgba(1, 1, 1, 0.15)
    border.width: 1
    
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        id: textItem
        anchors.centerIn: parent
        text: root.textContent
        color: root.fgColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.fontSize
        font.weight: Font.Medium
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked() 
    }
    
    signal clicked()
}