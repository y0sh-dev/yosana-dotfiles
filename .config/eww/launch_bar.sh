#!/bin/bash

# すでにewwが起動していたら終了させる（二重起動の非効率性を排除）
eww kill

eww daemon

# 'top_bar' という名前のウィンドウを定義して開く
sleep 1s
eww open bar_widget --config ~/.config/eww/
