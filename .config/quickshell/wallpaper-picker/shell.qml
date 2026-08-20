import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal requestClose()
    signal requestLaunch(string cmd)

    property color pywalBg: "#0f0f11"
    property color pywalFg: "#eeeeee"
    property color pywalAccent: "#7aa2f7"
    property color pywalCard: "#16161e"

    anchors.fill: parent

    Keys.onEscapePressed: root.requestClose()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "󰸉"
                color: root.pywalAccent
                font.pixelSize: 24
                font.family: "JetBrainsMono Nerd Font"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Select Wallpaper"
                    color: root.pywalFg
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                }

                Text {
                    text: "Arrow keys to navigate • Enter to apply • ESC to close"
                    color: Qt.rgba(root.pywalFg.r, root.pywalFg.g, root.pywalFg.b, 0.5)
                    font.pixelSize: 11
                    font.family: "Inter"
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(root.pywalFg.r, root.pywalFg.g, root.pywalFg.b, 0.1)
        }

        // Grid (4 columns)
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true

            cellWidth: (grid.width - 30) / 4  // 4 columns
            cellHeight: 140
            model: wallpaperModel
            currentIndex: 0

            Component.onCompleted: forceActiveFocus()

            Keys.onReturnPressed: {
                if (grid.currentIndex >= 0 && grid.currentIndex < wallpaperModel.count) {
                    applyWallpaper(wallpaperModel.get(grid.currentIndex).path)
                }
            }
            Keys.onLeftPressed:  grid.moveCurrentIndexLeft()
            Keys.onRightPressed: grid.moveCurrentIndexRight()
            Keys.onUpPressed:    grid.moveCurrentIndexUp()
            Keys.onDownPressed:  grid.moveCurrentIndexDown()

            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 14
                    color: Qt.rgba(root.pywalCard.r, root.pywalCard.g, root.pywalCard.b, 0.6)
                    border.color: grid.currentIndex === index
                        ? root.pywalAccent
                        : (cardMouseArea.containsMouse 
                            ? Qt.rgba(root.pywalAccent.r, root.pywalAccent.g, root.pywalAccent.b, 0.5)
                            : Qt.rgba(root.pywalFg.r, root.pywalFg.g, root.pywalFg.b, 0.15))
                    border.width: grid.currentIndex === index ? 2 : (cardMouseArea.containsMouse ? 1.5 : 1)

                    Behavior on border.width {
                        NumberAnimation { duration: 100 }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    clip: true

                    // Image
                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: "file://" + model.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 600
                        sourceSize.height: 200
                        opacity: (grid.currentIndex === index || cardMouseArea.containsMouse) ? 0.95 : 0.7

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    // Overlay on hover/select
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, (grid.currentIndex === index ? 0.3 : (cardMouseArea.containsMouse ? 0.15 : 0)))
                        radius: 14

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        // Center icon on selection
                        Text {
                            anchors.centerIn: parent
                            text: grid.currentIndex === index ? "󰄬" : ""
                            color: root.pywalAccent
                            font.pixelSize: 24
                            font.family: "JetBrainsMono Nerd Font"
                            opacity: grid.currentIndex === index ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            grid.currentIndex = index
                            applyWallpaper(model.path)
                        }
                    }
                }
            }
        }
    }

    function applyWallpaper(path) {
        // Use direct absolute path instead of ~ or $HOME
        let cmd = "$HOME/.local/bin/apply_wallpaper.sh '" + path.replace(/'/g, "'\\''") + "' &"
        root.requestLaunch(cmd)
    }

    Process {
        id: colorProc
        command: ["python3", "-c", `
import json, os
path = os.path.expanduser('~/.cache/wal/colors.json')
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
    bg = data.get('special', {}).get('background', '#0f0f11')
    fg = data.get('special', {}).get('foreground', '#eeeeee')
    accent = data.get('colors', {}).get('color4', '#7aa2f7')
    card = data.get('colors', {}).get('color0', '#16161e')
    print(f"{bg}\t{fg}\t{accent}\t{card}")
`]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split('\t');
                if (parts.length >= 4) {
                    root.pywalBg = parts[0];
                    root.pywalFg = parts[1];
                    root.pywalAccent = parts[2];
                    root.pywalCard = parts[3];
                }
            }
        }
    }

    ListModel {
        id: wallpaperModel
    }

    Process {
        id: scanProc
        command: ["bash", "-c", "find $HOME/Pictures/Wallpapers -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var cleanPath = data.trim();
                if (cleanPath.length > 0) {
                    wallpaperModel.append({ "path": cleanPath });
                }
            }
        }
    }
}
