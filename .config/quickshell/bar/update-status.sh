#!/bin/bash
mkdir -p /tmp/quickshell-bar

echo "No Media Playing" > /tmp/quickshell-bar/media.txt
echo "Paused" > /tmp/quickshell-bar/status.txt

# Initial creation to establish the inode for Quickshell
if [ -f ~/.cache/wal/colors.json ]; then
    cat ~/.cache/wal/colors.json > /tmp/quickshell-bar/colors.json
else
    echo "{}" > /tmp/quickshell-bar/colors.json
fi

LAST_WAL_TIME=""

while true; do
    # Check for pywal updates
    if [ -f ~/.cache/wal/colors.json ]; then
        WAL_TIME=$(stat -c %Y ~/.cache/wal/colors.json 2>/dev/null)
        if [ "$WAL_TIME" != "$LAST_WAL_TIME" ]; then
            # Using cat modifies in-place, preventing Quickshell's FileView from breaking!
            cat ~/.cache/wal/colors.json > /tmp/quickshell-bar/colors.json
            LAST_WAL_TIME="$WAL_TIME"
        fi
    fi

    TRACK=$(playerctl -a metadata --format '{{ artist }} - {{ title }}' 2>/dev/null | head -n 1)
    if [ -z "$TRACK" ] || [ "$TRACK" = " - " ]; then
        TRACK=$(playerctl -a metadata --format '{{ title }}' 2>/dev/null | head -n 1)
    fi

    if [ -n "$TRACK" ] && [ "$TRACK" != " - " ]; then
        echo "$TRACK" > /tmp/quickshell-bar/media.txt
    else
        echo "No Media Playing" > /tmp/quickshell-bar/media.txt
    fi

    STATUS=$(playerctl -a status 2>/dev/null | head -n 1)
    if [ -n "$STATUS" ]; then
        echo "$STATUS" > /tmp/quickshell-bar/status.txt
    else
        echo "Paused" > /tmp/quickshell-bar/status.txt
    fi

    sleep 1
done