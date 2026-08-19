import QtQuick

Item {
    id: root
    property string textContent: ""
    
    property color fgColor: "#eeeeee"
    property color hoverColor: "#88888f"
    
    property int fontSize: 15
    signal clicked(var mouse)

    width: textItem.implicitWidth
    height: 32

    Text {
        id: textItem
        anchors.centerIn: parent
        text: root.textContent
        
        color: mouseArea.containsMouse ? root.hoverColor : root.fgColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.fontSize
        font.weight: Font.Medium
        
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        // This is the magic line that allows left AND right clicks
        acceptedButtons: Qt.LeftButton | Qt.RightButton 
        
        onClicked: (mouse) => root.clicked(mouse)
    }
}