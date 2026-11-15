#!/bin/bash

generate_sinks_eww() {
  CURRENT=$(pactl get-default-sink)
  OUTPUT="(box :orientation \"v\" :class \"sinks_selector_box\" :spacing 5 :valign \"center\" :halign \"center\" "

  while read -r line; do
    NAME=$(echo "$line" | cut -d'|' -f1)
    DESC=$(echo "$line" | cut -d'|' -f2 | sed -E 's/ (Audio|アナログ|HDMI).*//')

    CLASS="sink-item"
    ICON=""
    if [ "$NAME" = "$CURRENT" ]; then
      CLASS="sink-item-active"
      ICON=""
    fi
    OUTPUT+=" (eventbox :class \"sink-item-box\" :onclick \"pactl set-default-sink $NAME\" :cursor \"pointer\" :width \"220\" (box :class \"$CLASS\" :cursor \"pointer\" :orientation \"h\" :space-evenly false :spacing 50 (label :text \"$DESC\") (label :text \"$ICON  \")))"

  done < <(pactl list sinks | grep -E "Name:|Description:" | awk -F': ' '{print $2}' | sed 'N;s/\n/|/')
  OUTPUT+=")"
  echo "$OUTPUT"
}
generate_sinks_eww

pactl subscribe | grep --line-buffered "Event 'change' on server" | while read -r event; do
  generate_sinks_eww
done
