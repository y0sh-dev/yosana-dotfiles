#!/bin/bash

if [[ -z $(eww active-windows | grep 'powermenu') ]]; then
    /usr/bin/eww open powermenu && /usr/bin/eww update powerrev=true
else
    /usr/bin/eww update powerrev=false
    (sleep 0.2 && /usr/bin/eww close powermenu) &
fi
