#!/bin/bash

if swaync-client --get-dnd | grep -q "true"; then
    echo "󰂛"
else
    echo "󰂚"
fi
