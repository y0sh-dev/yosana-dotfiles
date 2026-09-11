#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"

find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | while read imageFile; do
  echo -en "$(basename "$imageFile")\0icon\x1fthumbnail://$imageFile\n"
done | rofi -dmenu -i -show-icons -config ~/.config/rofi/config.rasi >/tmp/selected_wallpaper_name.txt

SELECTED_WALLPAPER_NAME=$(cat /tmp/selected_wallpaper_name.txt)
rm /tmp/selected_wallpaper_name.txt

if [ -z "$SELECTED_WALLPAPER_NAME" ]; then
  exit 0
fi

FULL_PATH="$WALLPAPER_DIR/$SELECTED_WALLPAPER_NAME"

awww img "$FULL_PATH" --transition-type center --transition-step 199 --transition-duration 2.9

wpg -s "$FULL_PATH"

echo "$FULL_PATH" >~/.config/hypr/current_wallpaper_awww

sleep 1s
hyprctl reload
bash ~/.config/eww/scripts/set_hyprlock.sh
eww reload
