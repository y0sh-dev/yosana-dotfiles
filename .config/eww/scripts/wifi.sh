#!/bin/bash

if [[ -z $(eww active-windows | grep 'wifi_menu') ]]; then
    /usr/bin/eww open wifi_menu && /usr/bin/eww update wifirev=true
else
    /usr/bin/eww update wifirev=false
    (sleep 0.2 && /usr/bin/eww close wifi_menu) &
fi
