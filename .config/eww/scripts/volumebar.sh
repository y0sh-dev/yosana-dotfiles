#!/bin/bash

if [[ -z $(eww active-windows | grep 'select_sinks') ]]; then
    /usr/bin/eww open select_sinks && /usr/bin/eww update sinksrev=true
else
    /usr/bin/eww update sinksrev=false
    (sleep 0.2 && /usr/bin/eww close select_sinks) &
fi
