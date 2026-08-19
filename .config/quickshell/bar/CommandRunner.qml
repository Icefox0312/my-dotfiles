import QtQuick
import Quickshell.Io

Item {
    id: runner

    function run(cmd) {
        proc.command = ["bash", "-c", cmd]
        proc.running = true
    }

    Process {
        id: proc
    }
}