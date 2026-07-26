#!/bin/bash

RDIR=${XDG_RUNTIME_DIR:-/tmp}
HYPR_DIR=$(ls -td "$RDIR/hypr/"* 2>/dev/null | head -n1)

if [[ -z "$HYPR_DIR" ]]; then
    echo "Error: Hyprland instance directory not found in $RDIR/hypr/" >&2
    exit 1
fi
SOCKET_PATH="$HYPR_DIR/.socket2.sock"

generate_eww_output() {
    MONITORS_JSON=$(hyprctl monitors -j)
    FOCUSED_WS_ID=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
    DISPLAYED_WS_ID=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.focused == false) | .activeWorkspace.id')
    ALL_WORKSPACES=$(seq 1 9)

    OUTPUT_EWw="(box :class \"ws\" :halign \"start\" :valign \"center\" :orientation \"h\" :spacing 5"

    for i in $ALL_WORKSPACES; do
        CLASS_NAME="inactive"
        ICON=""
        if [ "$i" -eq "$FOCUSED_WS_ID" ]; then
            CLASS_NAME="focused"
            ICON=""
        elif [ "$i" -eq "$DISPLAYED_WS_ID" ]; then
            CLASS_NAME="displayed"
            ICON=""
        fi
        OUTPUT_EWw+=" (eventbox :onclick \"hyprctl dispatch 'hl.dsp.focus({ workspace = $i })'\" :cursor \"pointer\" :class \"ws-$CLASS_NAME\" (label :text \"$ICON \"))"
    done

    OUTPUT_EWw+=")"
    echo "$OUTPUT_EWw"
}
generate_eww_output

socat -u "UNIX-CONNECT:$SOCKET_PATH" - | while read -r line; do
    if [[ "$line" == "workspace>>"* ]] ||
        [[ "$line" == "monitor>>"* ]] ||
        [[ "$line" == "createworkspace>>"* ]] ||
        [[ "$line" == "destroyworkspace>>"* ]] ||
        [[ "$line" == "monitorfocused>>"* ]] ||
        [[ "$line" == "activewindow>>"* ]]; then
        generate_eww_output
    fi
done
