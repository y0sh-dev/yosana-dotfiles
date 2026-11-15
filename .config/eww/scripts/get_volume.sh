#!/bin/bash

update() {
  VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n1)
  MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes' && echo 1 || echo 0)
  printf '{"vol": %d, "mute": %d}\n' "${VOL:-0}" "${MUTE:-0}"
}
update

pactl subscribe | grep --line-buffered -E "Event 'change' on (server|sink|sink-input)" | while read -r _; do
  update
done
