#!/usr/bin/env bash

WALLPAPER="$1"

if [ -z "$WALLPAPER" ]; then
    echo "Usage: set-wallpaper.sh /path/to/image.jpg"
    exit 1
fi

# 1. Update the wallpaper using awww
awww img "$WALLPAPER"

# 2. Extract colors with Pywal
wal -i "$WALLPAPER" -n -q

# 3. Notification
notify-send "Theme Updated" "wlogout and system colors updated from wallpaper."