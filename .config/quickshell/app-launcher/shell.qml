import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal requestClose()
    signal requestLaunch(string cmd)

    // --- Dynamic Color Variables (Default fallbacks if pywal isn't loaded) ---
    property color pywalBg: "#0f0f11"
    property color pywalFg: "#eeeeee"
    property color pywalAccent: "#7aa2f7"
    property color pywalCard: "#16161e"

    anchors.fill: parent

    Keys.onEscapePressed: root.requestClose()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // Search Bar
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 12
            color: Qt.rgba(root.pywalCard.r, root.pywalCard.g, root.pywalCard.b, 0.85)
            border.color: searchInput.activeFocus 
                ? root.pywalAccent 
                : Qt.rgba(root.pywalFg.r, root.pywalFg.g, root.pywalFg.b, 0.15)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "󰍉"
                    color: root.pywalAccent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: root.pywalFg
                    font.family: "Inter"
                    font.pixelSize: 14
                    clip: true

                    Component.onCompleted: forceActiveFocus()

                    onTextChanged: filterModel(text)

                    // Close on Escape key even while typing
                    Keys.onEscapePressed: root.requestClose()

                    Keys.onDownPressed: {
                        appList.currentIndex = Math.min(appList.currentIndex + 1, appList.count - 1)
                    }
                    Keys.onUpPressed: {
                        appList.currentIndex = Math.max(appList.currentIndex - 1, 0)
                    }
                    Keys.onReturnPressed: {
                        if (appList.count > 0 && appList.currentIndex >= 0) {
                            launchApp(filteredModel.get(appList.currentIndex).exec)
                        }
                    }
                }
            }
        }

        // Application List
        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: filteredModel
            currentIndex: 0

            delegate: Rectangle {
                width: appList.width
                height: 46
                radius: 10
                color: (appList.currentIndex === index)
                    ? root.pywalAccent
                    : (mArea.containsMouse ? Qt.rgba(root.pywalFg.r, root.pywalFg.g, root.pywalFg.b, 0.08) : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    // App Icon
                    Item {
                        width: 30
                        height: 30

                        Image {
                            anchors.fill: parent
                            source: model.iconPath ? "file://" + model.iconPath : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            visible: model.iconPath !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰣆"
                            color: (appList.currentIndex === index) ? root.pywalBg : root.pywalAccent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            visible: model.iconPath === ""
                        }
                    }

                    // App Name
                    Text {
                        Layout.fillWidth: true
                        text: model.name
                        color: (appList.currentIndex === index) ? root.pywalBg : root.pywalFg
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.bold: appList.currentIndex === index
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: mArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launchApp(model.exec)
                }
            }
        }
    }

    Process { id: execProc }
    ListModel { id: masterModel }
    ListModel { id: filteredModel }

    function launchApp(command) {
        if (!command) return;
        var cleanCmd = command.replace(/%[a-zA-Z]/g, "").trim();
        root.requestLaunch("setsid -f " + cleanCmd + " >/dev/null 2>&1 &");
    }

    function filterModel(query) {
        filteredModel.clear();
        var q = query.toLowerCase().trim();
        for (var i = 0; i < masterModel.count; i++) {
            var item = masterModel.get(i);
            if (q === "" || item.name.toLowerCase().includes(q)) {
                filteredModel.append(item);
            }
        }
        appList.currentIndex = 0;
    }

    // 1. Pywal Color Loader
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

    // 2. Application Scanner
    Process {
        id: scanProc
        command: ["python3", "-c", `
import os, glob

try:
    import gi
    gi.require_version('Gtk', '3.0')
    from gi.repository import Gtk
    icon_theme = Gtk.IconTheme.get_default()
except Exception:
    icon_theme = None

def resolve_icon(icon_name):
    if not icon_name:
        return ''
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        return icon_name
    if icon_theme:
        info = icon_theme.lookup_icon(icon_name, 48, 0)
        if info:
            return info.get_filename() or ''
    return ''

dirs = ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')]
entries = {}

for d in dirs:
    for f in glob.glob(os.path.join(d, '*.desktop')):
        try:
            name, exec_cmd, icon, nodisplay = '', '', '', False
            with open(f, 'r', encoding='utf-8', errors='ignore') as fp:
                for line in fp:
                    line = line.strip()
                    if line.startswith('Name=') and not name:
                        name = line.split('=', 1)[1]
                    elif line.startswith('Exec=') and not exec_cmd:
                        exec_cmd = line.split('=', 1)[1]
                    elif line.startswith('Icon=') and not icon:
                        icon = line.split('=', 1)[1]
                    elif line.startswith('NoDisplay=true'):
                        nodisplay = True
            if name and exec_cmd and not nodisplay and name not in entries:
                icon_path = resolve_icon(icon)
                entries[name] = (exec_cmd, icon_path)
        except Exception:
            pass

for name in sorted(entries.keys(), key=lambda s: s.lower()):
    exec_cmd, icon_path = entries[name]
    print(f"{name}\t{exec_cmd}\t{icon_path}")
`]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var lines = data.split('\n');
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('\t');
                    if (parts.length >= 2 && parts[0].trim().length > 0) {
                        var entry = {
                            "name": parts[0].trim(),
                            "exec": parts[1].trim(),
                            "iconPath": parts.length > 2 ? parts[2].trim() : ""
                        };
                        masterModel.append(entry);
                        filteredModel.append(entry);
                    }
                }
            }
        }
    }
}
