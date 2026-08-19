#!/bin/bash

if swaync-client -D | grep -q "true"; then
    echo '{"text":"󰂛","class":"dnd","tooltip":"Do Not Disturb: ON"}'
else
    echo '{"text":"󰂚","class":"normal","tooltip":"Do Not Disturb: OFF"}'
fi
