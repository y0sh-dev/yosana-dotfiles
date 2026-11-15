#!/bin/bash

WALLPAPER_FILE="$HOME/.config/hypr/current_wallpaper_awww"
WALLPAPER_PATH=$(cat "$WALLPAPER_FILE")
CONFIG_PATH="$HOME/.config/hypr/hyprlock.conf"

cat <<EOD >"$CONFIG_PATH"
background {
  monitor=DP-1
  blur_passes=1
  blur_size=7
  noise=0.011700
  path=$WALLPAPER_PATH
}

background {
  monitor=HDMI-A-1
  blur_passes=2
  blur_size=7
  noise=0.011700
  path=$WALLPAPER_PATH
}

image {
  monitor=DP-1
  halign=center
  path=/home/yukkkk1/Pictures/icons/nano_ai_2d_download_2.png
  position=0, 50
  valign=center
}

input-field {
  monitor=DP-1
  size=200,50
  check_color=rgb(30, 107, 204)
  dots_center=true
  dots_size=0.200000
  dots_spacing=0.350000
  fade_on_empty=false
  font_color=rgba(240, 248, 255, 0.8)
  halign=center
  hide_input=false
  inner_color=rgba(0, 0, 0, 0.7)
  outer_color=rgba(0, 0, 0, 0.4)
  outline_thickness=2
  placeholder_text=<i><span foreground="##cdd6f4">Input Password...</span></i>
  position=0, -100
  rounding=-1
  valign=center
}

label {
  monitor=DP-1
  color=rgba(242, 243, 244, 0.75)
  font_family=FiraCode Nerd Font
  font_size=95
  halign=center
  position=0, 300
  text=$TIME
  valign=center
}

label {
  monitor=DP-1
  color=rgba(242, 243, 244, 0.75)
  font_family=FiraCode Nerd Font
  font_size=22
  halign=center
  position=0, 200
  text=cmd[update:1000] echo \$(date +"%A, %B %d")\

  valign=center
}

EOD
