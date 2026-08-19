#!/bin/bash

if ! bluetoothctl show | grep -q "Powered: yes"; then
    echo '{"text":"󰂲  Off","class":"off","tooltip":"Bluetooth: Off"}'
    exit 0
fi

device=$(bluetoothctl devices Connected | sed 's/^Device [^ ]* //' | head -n 1)

if [ -n "$device" ]; then
    echo "{\"text\":\"󰂯  $device\",\"class\":\"connected\",\"tooltip\":\"Connected: $device\"}"
else
    echo '{"text":"󰂯  Not connected","class":"disconnected","tooltip":"Bluetooth: No device connected"}'
fi
