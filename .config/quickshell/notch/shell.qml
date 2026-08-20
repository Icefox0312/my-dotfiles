import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import notch

PanelWindow {
    id: notchRoot

    WlrLayershell.layer: WlrLayer.Overlay

    // Anchor to top, left, and right to span the screen width cleanly for centering
    anchors { top: true; left: true; right: true }
    
    implicitHeight: notchContainer.height
    color: "transparent"

    property color walBg: "#0b0c07"
    property color walFg: "#dec9a3"
    property color walAccent: "#A16B2D"

    property string sysMediaText: "No Media Playing"
    property bool sysMediaPlaying: false

    Process {
        id: pywalReader
        command: ["python3", "-c", `
import json, os
path = os.path.expanduser('~/.cache/wal/colors.json')
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
    print(f"{data.get('special', {}).get('background', '#0b0c07')}\t{data.get('special', {}).get('foreground', '#dec9a3')}\t{data.get('colors', {}).get('color4', '#A16B2D')}")
`]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split('\t');
                if (parts.length >= 3) {
                    notchRoot.walBg = parts[0];
                    notchRoot.walFg = parts[1];
                    notchRoot.walAccent = parts[2];
                }
            }
        }
    }

    Process {
        id: mediaReader
        command: ["bash", "-c", "paste -d '|' /tmp/quickshell-bar/status.txt /tmp/quickshell-bar/media.txt 2>/dev/null || echo 'Paused|No Media Playing'"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split('|');
                if (parts.length >= 2) {
                    notchRoot.sysMediaPlaying = (parts[0].trim() === "Playing");
                    let t = parts[1].trim();
                    notchRoot.sysMediaText = (t !== "") ? t : "No Media Playing";
                }
            }
        }
    }

    Component.onCompleted: { pywalReader.running = true; mediaReader.running = true; }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: { pywalReader.running = true; mediaReader.running = true; } }
    
    Process { 
        id: executor 
        property string pendingCmd: ""
        command: ["bash", "-c", pendingCmd]
        function run(cmd) {
            pendingCmd = cmd;
            running = true;
        }
    }

    component PodButton: Item {
        id: podBtn
        property string textContent: ""
        property int fontSize: 15
        property color fgColor: notchRoot.walFg
        property color hoverColor: notchRoot.walAccent
        signal clicked(var mouse)

        implicitWidth: btnText.implicitWidth + 8
        implicitHeight: btnText.implicitHeight + 4

        Text {
            id: btnText
            anchors.centerIn: parent
            text: podBtn.textContent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: podBtn.fontSize
            color: mouseArea.containsMouse ? podBtn.hoverColor : podBtn.fgColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => podBtn.clicked(mouse)
        }
    }

    Item {
        id: notchContainer
        property bool isMediaOpen: false
        
        width: isMediaOpen ? 320 : 130
        height: isMediaOpen ? 130 : 42 
        
        // Perfectly centers the notch horizontally inside the window, layering right over your bar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        
        clip: true 
        
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        Rectangle {
            width: parent.width
            height: parent.height + 16 
            y: -16 
            radius: 18

            color: Qt.rgba(notchRoot.walBg.r, notchRoot.walBg.g, notchRoot.walBg.b, 0.92)
            border.color: Qt.rgba(notchRoot.walFg.r, notchRoot.walFg.g, notchRoot.walFg.b, 0.18)
            border.width: 1

            Item {
                y: 16
                width: parent.width
                height: parent.height - 16

                // Clock
                Item {
                    width: 130; height: 26; anchors.centerIn: parent
                    opacity: notchContainer.isMediaOpen ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 250 } }

                    PodButton {
                        id: clockBtn
                        anchors.centerIn: parent
                        property bool showDate: false
                        property var currentTime: new Date()
                        textContent: "<b>" + (showDate ? Qt.formatDateTime(currentTime, "dddd, dd MMMM") : Qt.formatDateTime(currentTime, "h:mm")) + "</b>"
                        fontSize: 15; fgColor: notchRoot.walFg; hoverColor: notchRoot.walAccent
                        Timer { interval: 1000; running: true; repeat: true; onTriggered: clockBtn.currentTime = new Date() }
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) clockBtn.showDate = !clockBtn.showDate;
                            else notchContainer.isMediaOpen = true;
                        }
                    }
                }

                // Media Content
                Item {
                    width: 320; height: 114; anchors.centerIn: parent
                    opacity: notchContainer.isMediaOpen ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 350 } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: notchContainer.isMediaOpen = false
                        cursorShape: Qt.PointingHandCursor
                    }

                    Column {
                        anchors.centerIn: parent; spacing: 16

                        Item {
                            width: 280; height: 20; clip: true; anchors.horizontalCenter: parent.horizontalCenter
                            Text {
                                id: trackText
                                text: notchRoot.sysMediaText
                                color: notchRoot.walFg; font.family: "Inter"; font.pixelSize: 15; font.bold: true
                                width: Math.max(implicitWidth, 280); horizontalAlignment: Text.AlignHCenter
                                property real maxScroll: Math.max(0, trackText.implicitWidth - 280)
                                SequentialAnimation {
                                    running: trackText.maxScroll > 0 && notchContainer.isMediaOpen
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: 1000 }
                                    NumberAnimation { target: trackText; property: "x"; to: -trackText.maxScroll; duration: trackText.maxScroll * 35; easing.type: Easing.InOutSine }
                                    PauseAnimation { duration: 1500 }
                                    NumberAnimation { target: trackText; property: "x"; to: 0; duration: trackText.maxScroll * 35; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 28 
                            PodButton { textContent: "󰒮"; fontSize: 22; fgColor: notchRoot.walFg; hoverColor: notchRoot.walAccent; onClicked: executor.run("playerctl previous") } 
                            PodButton { 
                                textContent: notchRoot.sysMediaPlaying ? "󰏤" : "󰐊"
                                fontSize: 28; fgColor: notchRoot.walFg; hoverColor: notchRoot.walAccent
                                onClicked: { notchRoot.sysMediaPlaying = !notchRoot.sysMediaPlaying; executor.run("playerctl play-pause"); }
                            }
                            PodButton { textContent: "󰒭"; fontSize: 22; fgColor: notchRoot.walFg; hoverColor: notchRoot.walAccent; onClicked: executor.run("playerctl next") } 
                        }
                    }
                }
            }
        }
    }
}