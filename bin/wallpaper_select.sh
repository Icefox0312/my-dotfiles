#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallpaper-picker.rasi"

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpaper Picker" "Directory $WALLPAPER_DIR does not exist!"
    exit 1
fi

if ! pgrep -x "awww-daemon" > /dev/null && ! pgrep -x "awww" > /dev/null; then
    awww-daemon &
    sleep 0.5
fi

# Build thumbnail list
CHOICES=""
for file in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp,gif,JPG,JPEG,PNG,WEBP,GIF}; do
    [ -f "$file" ] || continue
    filename="$(basename "$file")"
    CHOICES+="${filename}\0icon\x1f${file}\n"
done

# Show picker matching launcher style
SELECTED=$(printf "%b" "$CHOICES" | rofi -dmenu \
    -show-icons \
    -p "󰸉 Wallpaper" \
    -theme "$ROFI_THEME")

if [ -n "$SELECTED" ]; then
    FULL_PATH="$WALLPAPER_DIR/$SELECTED"
    
    if [ -f "$FULL_PATH" ]; then
        # Apply wallpaper[cite: 3]
        awww img "$FULL_PATH" \
            --transition-type grow \
            --transition-pos center \
            --transition-fps 60 \
            --transition-step 90

        # Generate pywal colors[cite: 3]
        wal -i "$FULL_PATH" -n -q

        # Reload Waybar[cite: 3]
        killall -SIGUSR2 waybar

        # Reload SwayNC[cite: 3]
        if pgrep -x "swaync" > /dev/null; then
            swaync-client -R -rs
        fi

        # Restart Quickshell and status tracker to apply new wallpaper colors instantly
        pkill -f update-status.sh
        bash ~/.config/quickshell/bar/update-status.sh &
        pkill quickshell
        quickshell -p ~/.config/quickshell/bar/ &
    else
        notify-send "Wallpaper Error" "Could not find file: $FULL_PATH"[cite: 3]
    fi
fi