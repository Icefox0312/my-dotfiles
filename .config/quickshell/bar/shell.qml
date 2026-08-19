import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: rootWindow

    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.keyboardFocus: (notchModule.isLauncherOpen || notchModule.isWallpaperOpen)

    // =====================================================
    // WAYLAND CLICK PASSTHROUGH MASK
    // =====================================================
    mask: Region {
        // Left side pods
        Region { item: archPod }
        Region { item: workspacesPod }
        Region { item: notifPod }
        Region { item: hyprmodPod }
        Region { item: wallPod }
        Region { item: lockPod }
        Region { item: volPod }
        Region { item: briPod }

        // The Notch
        Region { item: notchModule }

        // Right side pods
        Region { item: btPod }
        Region { item: wifiPod }
        Region { item: powerPod }
        Region { item: batPod }
        Region { item: logoutPod }
    }

    // =====================================================
    // WINDOW
    // =====================================================

    // Large enough for the expanded notch.
    // The actual reserved bar space remains 48px.
    implicitHeight: 550
    exclusiveZone: 48

    color: "transparent"

    // =====================================================
    // COLORS
    // =====================================================

    property color walBg: "#0b0c07"
    property color walFg: "#dec9a3"
    property color walAccent: "#A16B2D"
    property color walAlert: "#465435"

    // =====================================================
    // SYSTEM STATE
    // =====================================================

    property int sysVolume: 50
    property int sysBrightness: 100

    // Bluetooth
    // 0 = off
    // 1 = on / not connected
    // 2 = connected
    property int sysBtState: 0
    property string sysBtName: ""

    // Wi-Fi
    property bool sysWifiEnabled: true
    property bool sysWifiConnected: false
    property string sysWifiName: ""

    // Battery
    property int sysBattery: 100
    property string sysBatState: "Unknown"

    // Power profile
    property string sysPpd: "balanced"

    // =====================================================
    // MEDIA
    // =====================================================

    property string sysMediaText: "No Media Playing"
    property bool sysMediaPlaying: false

    // =====================================================
    // STATUS DAEMON
    // =====================================================

    Process {
        id: statusDaemon

        command: [
            "bash",
            "-c",
            "bash /home/icefox/.config/quickshell/bar/update-status.sh"
        ]

        running: true
    }

    // =====================================================
    // PYWAL
    // =====================================================

    Process {
        id: pywalReader

        command: [
            "python3",
            "-c",
            `
import json, os

path = os.path.expanduser('~/.cache/wal/colors.json')

if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)

    print(
        f"{data.get('special', {}).get('background', '#0b0c07')}\\t"
        f"{data.get('special', {}).get('foreground', '#dec9a3')}\\t"
        f"{data.get('colors', {}).get('color4', '#A16B2D')}\\t"
        f"{data.get('colors', {}).get('color1', '#465435')}"
    )
`
        ]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split('\t')

                if (parts.length >= 4) {
                    rootWindow.walBg = parts[0]
                    rootWindow.walFg = parts[1]
                    rootWindow.walAccent = parts[2]
                    rootWindow.walAlert = parts[3]
                }
            }
        }
    }

    // =====================================================
    // SYSTEM READER
    // =====================================================

    Process {
        id: sysReader

        command: [
            "bash",
            "-c",
            "V=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -o '[0-9.]*' | awk '{print int($1*100)}'); B=$(brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d %); BT_PWR=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 1 || echo 0); BT_DEV=$(bluetoothctl devices Connected 2>/dev/null | head -n 1 | cut -d' ' -f3-); BAT_C=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1); BAT_S=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1); PPD=$(powerprofilesctl get 2>/dev/null); WIFI=$(nmcli -t -f WIFI general 2>/dev/null); WIFI_STATE=$(nmcli -t -f STATE general 2>/dev/null); WIFI_NAME=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1==\"yes\" {print $2; exit}'); echo \"${V:-0}|${B:-100}|${BT_PWR}|${BT_DEV}|${BAT_C:-100}|${BAT_S:-Unknown}|${PPD:-balanced}|${WIFI:-enabled}|${WIFI_STATE:-disconnected}|${WIFI_NAME}\""
        ]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split('|')

                if (parts.length >= 10) {

                    // -------------------------------------
                    // VOLUME
                    // -------------------------------------

                    if (volSlider && !volSlider.pressed)
                        rootWindow.sysVolume =
                            parseInt(parts[0]) || 0

                    // -------------------------------------
                    // BRIGHTNESS
                    // -------------------------------------

                    if (briSlider && !briSlider.pressed)
                        rootWindow.sysBrightness =
                            parseInt(parts[1]) || 0

                    // -------------------------------------
                    // BLUETOOTH
                    // -------------------------------------

                    let isPowered =
                        parts[2] === "1"

                    let devName =
                        parts[3]
                        ? parts[3].trim()
                        : ""

                    rootWindow.sysBtState =
                        !isPowered
                        ? 0
                        : (
                            devName !== ""
                            ? 2
                            : 1
                        )

                    rootWindow.sysBtName =
                        devName

                    // -------------------------------------
                    // BATTERY
                    // -------------------------------------

                    rootWindow.sysBattery =
                        parseInt(parts[4]) || 100

                    rootWindow.sysBatState =
                        parts[5] || "Unknown"

                    // -------------------------------------
                    // POWER PROFILE
                    // -------------------------------------

                    rootWindow.sysPpd =
                        parts[6] || "balanced"

                    // -------------------------------------
                    // WI-FI
                    // -------------------------------------

                    rootWindow.sysWifiEnabled =
                        parts[7].trim() === "enabled"

                    rootWindow.sysWifiConnected =
                        parts[8].trim() === "connected"

                    rootWindow.sysWifiName =
                        parts[9]
                        ? parts[9].trim()
                        : ""
                }
            }
        }
    }

    // =====================================================
    // MEDIA READER
    // =====================================================

    Process {
        id: mediaReader

        command: [
            "bash",
            "-c",
            "STATUS=$(playerctl status 2>/dev/null || echo 'Stopped'); ARTIST=$(playerctl metadata artist 2>/dev/null); TITLE=$(playerctl metadata title 2>/dev/null); if [ -n \"$TITLE\" ]; then if [ -n \"$ARTIST\" ]; then echo \"$STATUS|$ARTIST - $TITLE\"; else echo \"$STATUS|$TITLE\"; fi; else echo \"Stopped|No Media Playing\"; fi"
        ]

        stdout: SplitParser {
            onRead: data => {
                var parts =
                    data.trim().split('|')

                if (parts.length >= 2) {
                    rootWindow.sysMediaPlaying =
                        parts[0].trim() === "Playing"

                    let t =
                        parts[1].trim()

                    rootWindow.sysMediaText =
                        t !== ""
                        ? t
                        : "No Media Playing"
                }
            }
        }
    }

    // =====================================================
    // START READERS
    // =====================================================

    Component.onCompleted: {
        pywalReader.running = true
        sysReader.running = true
        mediaReader.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            pywalReader.running = true
            sysReader.running = true
            mediaReader.running = true
        }
    }

    // =====================================================
    // EXECUTOR
    // =====================================================

    CommandRunner {
        id: executor
    }

    // =====================================================
    // BAR
    // =====================================================

    Item {
        anchors.fill: parent

        // =================================================
        // LEFT SIDE
        // =================================================

        Row {
            anchors.left: parent.left
            anchors.top: parent.top

            anchors.leftMargin: 12
            anchors.topMargin: 8

            spacing: 8

            // ---------------------------------------------
            // ARCH
            // ---------------------------------------------

            Pod {
                id: archPod

                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg

                PodButton {
                    textContent: " "
                    fontSize: 17

                    fgColor:
                        rootWindow.walFg

                    hoverColor:
                        rootWindow.walAccent

                    onClicked:
                        executor.run(
                            "kitty fish -c 'fastfetch; exec fish'"
                        )
                }
            }

            // ---------------------------------------------
            // WORKSPACES
            // ---------------------------------------------

            Pod {
                id: workspacesPod
                
                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg
                customSpacing: 8

                Repeater {
                    model: 5

                    delegate: PodButton {
                        required property int index

                        property int wsId:
                            index + 1

                        property bool isFocused:
                            Hyprland.focusedWorkspace
                            ? Hyprland.focusedWorkspace.id === wsId
                            : false

                        textContent:
                            isFocused
                            ? "●"
                            : wsId.toString()

                        fontSize: 13

                        fgColor:
                            isFocused
                            ? rootWindow.walAccent
                            : Qt.rgba(
                                rootWindow.walFg.r,
                                rootWindow.walFg.g,
                                rootWindow.walFg.b,
                                0.4
                            )

                        hoverColor:
                            rootWindow.walAccent

                        onClicked:
                            executor.run(
                                "hyprctl dispatch workspace " +
                                wsId
                            )
                    }
                }
            }

            // ---------------------------------------------
            // NOTIFICATIONS
            // ---------------------------------------------

            Pod {
                id: notifPod

                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg

                PodButton {
                    textContent: "󰂚"

                    fgColor:
                        rootWindow.walFg

                    hoverColor:
                        rootWindow.walAccent

                    onClicked:
                        executor.run(
                            "swaync-client -t"
                        )
                }
            }

            // ---------------------------------------------
            // HYPRMOD
            // ---------------------------------------------

            Pod {
                id: hyprmodPod

                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg

                PodButton {
                    textContent: "󰒓"

                    fgColor:
                        rootWindow.walFg

                    hoverColor:
                        rootWindow.walAccent

                    onClicked:
                        executor.run("hyprmod")
                }
            }

            // ---------------------------------------------
            // WALLPAPER
            // ---------------------------------------------

            Pod {
                id: wallPod

                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg

                PodButton {
                    textContent: ""

                    fgColor:
                        rootWindow.walFg

                    hoverColor:
                        rootWindow.walAccent

                    onClicked:
                        executor.run(
                            'sh -c "echo toggle_wallpaper > /tmp/notch_ipc"'
                        )
                }
            }

            // ---------------------------------------------
            // LOCK
            // ---------------------------------------------

            Pod {
                id: lockPod

                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg

                PodButton {
                    textContent: "󰌾"

                    fgColor:
                        rootWindow.walFg

                    hoverColor:
                        rootWindow.walAccent

                    onClicked:
                        executor.run("hyprlock")
                }
            }
            // =================================================
            // VOLUME
            // =================================================

            Pod {
                id: volPod

                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg

                property bool isOpen: false

                Row {
                    spacing:
                        volPod.isOpen
                        ? 6
                        : 0

                    anchors.verticalCenter:
                        parent.verticalCenter

                    padding: 4
                    leftPadding: 12

                    rightPadding:
                        volPod.isOpen
                        ? 6
                        : 12

                    Text {
                        text:
                            rootWindow.sysVolume > 50
                            ? "󰕾"
                            : (
                                rootWindow.sysVolume > 0
                                ? "󰖀"
                                : "󰝟"
                            )

                        color:
                            volIconMouse.containsMouse
                            ? rootWindow.walAccent
                            : rootWindow.walFg

                        font.pixelSize: 15

                        anchors.verticalCenter:
                            parent.verticalCenter

                        MouseArea {
                            id: volIconMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked:
                                volPod.isOpen =
                                    !volPod.isOpen
                        }
                    }

                    Item {
                        width:
                            volPod.isOpen
                            ? 76
                            : 0

                        height: 24
                        clip: true

                        anchors.verticalCenter:
                            parent.verticalCenter

                        Behavior on width {
                            NumberAnimation {
                                duration: 350
                                easing.type:
                                    Easing.OutExpo
                            }
                        }

                        Slider {
                            id: volSlider

                            width: 76

                            from: 0
                            to: 100

                            value:
                                rootWindow.sysVolume

                            anchors.verticalCenter:
                                parent.verticalCenter

                            background: Rectangle {
                                x: volSlider.leftPadding

                                y:
                                    volSlider.topPadding +
                                    volSlider.availableHeight / 2 -
                                    height / 2

                                implicitWidth: 76
                                implicitHeight: 4

                                width:
                                    volSlider.availableWidth

                                height:
                                    implicitHeight

                                radius: 2

                                color:
                                    Qt.rgba(
                                        rootWindow.walFg.r,
                                        rootWindow.walFg.g,
                                        rootWindow.walFg.b,
                                        0.2
                                    )

                                Rectangle {
                                    width:
                                        volSlider.visualPosition *
                                        parent.width

                                    height:
                                        parent.height

                                    color:
                                        rootWindow.walAccent

                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x:
                                    volSlider.leftPadding +
                                    volSlider.visualPosition *
                                    (
                                        volSlider.availableWidth -
                                        width
                                    )

                                y:
                                    volSlider.topPadding +
                                    volSlider.availableHeight / 2 -
                                    height / 2

                                implicitWidth: 12
                                implicitHeight: 12

                                radius: 6

                                color:
                                    volSlider.pressed
                                    ? rootWindow.walAlert
                                    : rootWindow.walAccent
                            }

                            // Update the visible value while dragging, but let the
                            // system reader take care of the normal background sync.
                            onValueChanged: {
                                if (pressed) {
                                    rootWindow.sysVolume = Math.round(value)
                                }
                            }

                            // Apply the command once, when the user releases the slider.
                            onPressedChanged: {
                                if (!pressed) {
                                    const v = Math.max(0, Math.min(100, Math.round(value)))
                                    rootWindow.sysVolume = v
                                    executor.run(
                                        "wpctl set-volume @DEFAULT_AUDIO_SINK@ " +
                                        (v / 100).toFixed(2)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // BRIGHTNESS
            // =================================================

            Pod {
                id: briPod

                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg

                property bool isOpen: false

                Row {
                    spacing:
                        briPod.isOpen
                        ? 6
                        : 0

                    anchors.verticalCenter:
                        parent.verticalCenter

                    padding: 4
                    leftPadding: 12

                    rightPadding:
                        briPod.isOpen
                        ? 6
                        : 12

                    Text {
                        text: "󰃠"

                        color:
                            briIconMouse.containsMouse
                            ? rootWindow.walAccent
                            : rootWindow.walFg

                        font.pixelSize: 15

                        anchors.verticalCenter:
                            parent.verticalCenter

                        MouseArea {
                            id: briIconMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked:
                                briPod.isOpen =
                                    !briPod.isOpen
                        }
                    }

                    Item {
                        width:
                            briPod.isOpen
                            ? 76
                            : 0

                        height: 24
                        clip: true

                        anchors.verticalCenter:
                            parent.verticalCenter

                        Behavior on width {
                            NumberAnimation {
                                duration: 350
                                easing.type:
                                    Easing.OutExpo
                            }
                        }

                        Slider {
                            id: briSlider

                            width: 76

                            from: 0
                            to: 100

                            value:
                                rootWindow.sysBrightness

                            anchors.verticalCenter:
                                parent.verticalCenter

                            background: Rectangle {
                                x: briSlider.leftPadding

                                y:
                                    briSlider.topPadding +
                                    briSlider.availableHeight / 2 -
                                    height / 2

                                implicitWidth: 76
                                implicitHeight: 4

                                width:
                                    briSlider.availableWidth

                                height:
                                    implicitHeight

                                radius: 2

                                color:
                                    Qt.rgba(
                                        rootWindow.walFg.r,
                                        rootWindow.walFg.g,
                                        rootWindow.walFg.b,
                                        0.2
                                    )

                                Rectangle {
                                    width:
                                        briSlider.visualPosition *
                                        parent.width

                                    height:
                                        parent.height

                                    color:
                                        rootWindow.walAccent

                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x:
                                    briSlider.leftPadding +
                                    briSlider.visualPosition *
                                    (
                                        briSlider.availableWidth -
                                        width
                                    )

                                y:
                                    briSlider.topPadding +
                                    briSlider.availableHeight / 2 -
                                    height / 2

                                implicitWidth: 12
                                implicitHeight: 12

                                radius: 6

                                color:
                                    briSlider.pressed
                                    ? rootWindow.walAlert
                                    : rootWindow.walAccent
                            }

                            // Update the visible value while dragging.
                            onValueChanged: {
                                if (pressed) {
                                    rootWindow.sysBrightness = Math.round(value)
                                }
                            }

                            // Apply the command once, when the user releases the slider.
                            onPressedChanged: {
                                if (!pressed) {
                                    const v = Math.max(0, Math.min(100, Math.round(value)))
                                    rootWindow.sysBrightness = v
                                    executor.run(
                                        "brightnessctl set " +
                                        v +
                                        "%"
                                    )
                                }
                            }
                        }
                    }
                }
            } // <--- FIXED: Closes Brightness Pod
        } // <--- FIXED: Closes Left Side Row

        // =================================================
        // NOTCH
        // =================================================

        Notch {
            id: notchModule


            anchors.top:
                parent.top

            anchors.horizontalCenter:
                parent.horizontalCenter

            z: 999

            walBg:
                rootWindow.walBg

            walFg:
                rootWindow.walFg

            walAccent:
                rootWindow.walAccent

            sysMediaText:
                rootWindow.sysMediaText

            sysMediaPlaying:
                rootWindow.sysMediaPlaying
        }

        // =================================================
        // RIGHT SIDE
        // =================================================

        Row {
            anchors.right: parent.right
            anchors.top: parent.top

            anchors.rightMargin: 12
            anchors.topMargin: 8

            spacing: 8

            // =============================================
            // BLUETOOTH
            // =============================================

            Pod {
                id: btPod
                
                podBg:
                    rootWindow.walBg

                podBorder:
                    rootWindow.walFg

                Row {
                    anchors.verticalCenter:
                        parent.verticalCenter

                    spacing:
                        rootWindow.sysBtState > 0
                        ? 4
                        : 0

                    rightPadding:
                        rootWindow.sysBtState > 0
                        ? 14
                        : 0

                    PodButton {
                        textContent:
                            rootWindow.sysBtState === 0
                            ? "󰂲"
                            : (
                                rootWindow.sysBtState === 2
                                ? "󰂱"
                                : "󰂯"
                            )

                        fgColor:
                            rootWindow.sysBtState > 0
                            ? rootWindow.walAccent
                            : Qt.rgba(
                                rootWindow.walFg.r,
                                rootWindow.walFg.g,
                                rootWindow.walFg.b,
                                0.5
                            )

                        hoverColor:
                            rootWindow.walAlert

                        onClicked: mouse => {

                            if (
                                mouse.button ===
                                Qt.RightButton
                            ) {
                                executor.run(
                                    "quickshell -p ~/.config/quickshell/bluetooth-menu/ &"
                                )
                            } else {
                                executor.run(
                                    "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"
                                )
                            }
                        }
                    }

                    Text {
                        visible:
                            rootWindow.sysBtState > 0

                        text:
                            rootWindow.sysBtState === 2
                            ? rootWindow.sysBtName
                            : "  Not Connected"

                        color:
                            rootWindow.sysBtState === 2
                            ? rootWindow.walFg
                            : Qt.rgba(
                                rootWindow.walFg.r,
                                rootWindow.walFg.g,
                                rootWindow.walFg.b,
                                0.6
                            )

                        font.pixelSize: 13
                        font.family: "Inter"
                        font.bold:
                            true

                        anchors.verticalCenter:
                            parent.verticalCenter
                    }
                }
            }

            // =============================================
            // WI-FI
            // =============================================

            Pod {
                id: wifiPod

                podBg:
                    rootWindow.walBg

                podBorder:
                    rootWindow.walFg

                Row {
                    anchors.verticalCenter:
                        parent.verticalCenter

                    spacing:
                        rootWindow.sysWifiConnected
                        ? 5
                        : 0

                    rightPadding:
                        rootWindow.sysWifiConnected
                        ? 14
                        : 0

                    // -------------------------------------
                    // WIFI ICON
                    // -------------------------------------

                    PodButton {
                        textContent:
                            !rootWindow.sysWifiEnabled
                            ? "󰤮"
                            : (
                                rootWindow.sysWifiConnected
                                ? "󰤨"
                                : "󰤯"
                            )

                        fgColor:
                            !rootWindow.sysWifiEnabled
                            ? Qt.rgba(
                                rootWindow.walFg.r,
                                rootWindow.walFg.g,
                                rootWindow.walFg.b,
                                0.45
                            )
                            : (
                                rootWindow.sysWifiConnected
                                ? rootWindow.walAccent
                                : rootWindow.walFg
                            )

                        hoverColor:
                            rootWindow.walAccent

                        onClicked: mouse => {

                            // Right click:
                            // open NetworkManager editor
                            if (
                                mouse.button ===
                                Qt.RightButton
                            ) {
                                executor.run(
                                    "nm-connection-editor"
                                )

                                return
                            }

                            // Left click:
                            // toggle Wi-Fi
                            executor.run(
                                rootWindow.sysWifiEnabled
                                ? "nmcli radio wifi off"
                                : "nmcli radio wifi on"
                            )
                        }
                    }

                    // -------------------------------------
                    // NETWORK NAME
                    // -------------------------------------

                    Text {
                        visible:
                            rootWindow.sysWifiConnected

                        text:
                            rootWindow.sysWifiName

                        color:
                            rootWindow.walFg

                        font.pixelSize:
                            13

                        font.family:
                            "Inter"

                        font.bold:
                            true

                        anchors.verticalCenter:
                            parent.verticalCenter
                    }
                }
            }

            // =============================================
            // POWER PROFILE
            // =============================================

            Pod {
                id: powerPod
                
                podBg:
                    rootWindow.walBg

                podBorder:
                    rootWindow.walFg

                PodButton {
                    textContent:
                        rootWindow.sysPpd === "performance"
                        ? "󰓅"
                        : (
                            rootWindow.sysPpd === "power-saver"
                            ? "󰌪"
                            : "󰾆"
                        )

                    fgColor:
                        rootWindow.sysPpd === "performance"
                        ? rootWindow.walAlert
                        : (
                            rootWindow.sysPpd === "power-saver"
                            ? Qt.rgba(
                                rootWindow.walFg.r,
                                rootWindow.walFg.g,
                                rootWindow.walFg.b,
                                0.6
                            )
                            : rootWindow.walAccent
                        )

                    hoverColor:
                        rootWindow.walAccent

                    onClicked: {

                        if (
                            rootWindow.sysPpd ===
                            "power-saver"
                        ) {

                            executor.run(
                                "powerprofilesctl set balanced"
                            )

                            rootWindow.sysPpd =
                                "balanced"

                        } else if (
                            rootWindow.sysPpd ===
                            "balanced"
                        ) {

                            executor.run(
                                "powerprofilesctl set performance"
                            )

                            rootWindow.sysPpd =
                                "performance"

                        } else {

                            executor.run(
                                "powerprofilesctl set power-saver"
                            )

                            rootWindow.sysPpd =
                                "power-saver"
                        }
                    }
                }
            }

            // =============================================
            // BATTERY
            // =============================================

            Pod {
                id: batPod
                
                podBg: rootWindow.walBg
                podBorder: rootWindow.walFg

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    padding: 4
                    leftPadding: 12
                    rightPadding: 12

                    Text {
                        text: {
                            let b = rootWindow.sysBattery
                            // Trim whitespace to prevent match failures and account for 100% capacity
                            let state = rootWindow.sysBatState.toString().trim()
                            let isPluggedIn = (state === "Charging" || state === "Full")

                            if (isPluggedIn) {
                                return b > 90 ? "󰂅" : 
                                      (b > 80 ? "󰂋" : 
                                      (b > 60 ? "󰂊" : 
                                      (b > 40 ? "󰢞" : 
                                      (b > 20 ? "󰂇" : "󰢜"))))
                            }

                            return b > 90 ? "󰁹" : 
                                  (b > 50 ? "󰁿" : 
                                  (b > 20 ? "󰁼" : "󰂎"))
                        }

                        color: {
                            let state = rootWindow.sysBatState.toString().trim()
                            let isPluggedIn = (state === "Charging" || state === "Full")

                            if (rootWindow.sysBattery <= 20 && !isPluggedIn)
                                return rootWindow.walAlert
                            
                            if (isPluggedIn)
                                return rootWindow.walAccent
                                
                            return rootWindow.walFg
                        }

                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: rootWindow.sysBattery + "%"
                        color: rootWindow.walFg
                        font.pixelSize: 13
                        font.family: "Inter"
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            // =============================================
            // LOGOUT
            // =============================================

            Pod {
                id: logoutPod
                
                podBg:
                    rootWindow.walBg

                podBorder:
                    rootWindow.walFg

                PodButton {
                    textContent:
                        "󰐥"

                    fgColor:
                        rootWindow.walFg

                    hoverColor:
                        rootWindow.walAccent

                    onClicked:
                        executor.run("wlogout")
                }
            }
        }
    }
}