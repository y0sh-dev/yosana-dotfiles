#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
HIST="$HOME/.config/hypr/.wallpaper_history"
touch "$HIST"

NEW_IMAGES=$(
  find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -printf "%T@ %f\n" \
    | sort -rn | cut -d' ' -f2- | grep -F -v -x -f "$HIST"
)

if [ -n "$NEW_IMAGES" ]; then
  (echo "$NEW_IMAGES"; cat "$HIST") > "$HIST.tmp" && mv "$HIST.tmp" "$HIST"
fi

SELECTED_WALLPAPER_NAME=$(
  while read -r name; do
    [[ -f "$WALLPAPER_DIR/$name" ]] && echo -en "$name\0icon\x1fthumbnail://$WALLPAPER_DIR/$name\n"
  done < "$HIST" | rofi -dmenu -i -show-icons -config ~/.config/rofi/config.rasi
)

[[ -z "$SELECTED_WALLPAPER_NAME" ]] && exit 0

(echo "$SELECTED_WALLPAPER_NAME"; grep -vxF "$SELECTED_WALLPAPER_NAME" "$HIST") > "$HIST.tmp" && mv "$HIST.tmp" "$HIST"

FULL_PATH="$WALLPAPER_DIR/$SELECTED_WALLPAPER_NAME"

awww img "$FULL_PATH" --transition-type center --transition-step 199 --transition-duration 2.9
wpg -s "$FULL_PATH"
echo "$FULL_PATH" > ~/.config/hypr/current_wallpaper_awww

sleep 1s
hyprctl reload
bash ~/.config/eww/scripts/set_hyprlock.sh
eww reload
