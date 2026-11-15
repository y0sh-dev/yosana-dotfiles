#!/bin/bash

# 環境に合わせてインターフェース名を指定してください（例: wlan0, wlp15s0）
IFACE="wlan0"

generate_wifi_ui() {
  # 1. 現在の接続SSIDを取得 (iwd用)
  current_wifi=$(iwctl station "$IFACE" show | grep 'Connected network' | awk '{print $3}')
  [ -z "$current_wifi" ] && current_wifi="Disconnected"

  # 2. Wi-Fiスキャン結果の取得 (iwd用: 制御文字を除去して整形)
  data=$(iwctl station "$IFACE" get-networks | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | grep -E '^[* >\s]+' | grep -vE 'Network name|Available networks|---' | sed 's/^[* >]*//' | awk '{print $1}')

  # 3. 全体コンテナ
  output="(eventbox :onhoverlost \"eww update selected_obj='{\\\"name\\\": \\\"\\\", \\\"connected\\\": false}' && ~/.config/eww/scripts/wifi.sh \" "
  output+="(box :class 'wifi-container' :orientation 'vertical' :space-evenly false :spacing 10 "

  # 4. 上段: Info Box
  output+="(box :class 'manage-info-box' :orientation 'vertical' :space-evenly false (label :class 'window-title' :text 'Wi-Fi Manager (iwd)') (label :class 'current-ssid' :text 'Connected: $current_wifi ' :halign 'start') ) "

  # 5. 中段: SSID List Box
  output+="(box :class 'ssid-list-box' :orientation 'vertical' :space-evenly false :spacing 5 "
  while read -r ssid type; do
    [[ -z "${ssid// /}" ]] && continue
    item="(eventbox :class 'ssid-item-box' :width \"150\" :cursor \"pointer\" :onclick \"eww update selected_obj='{\\\"name\\\": \\\"$ssid\\\", \\\"connected\\\": false}'\" (box :class \"ssid-item\" :width \"150\" (label :text \"$ssid\" :halign \"start\")))"
    output+="$item "
  done <<<"$data"
  output+=")"

  # 6. 下段: Manage Box
  manage_box="(box :class 'manage-box' :orientation 'vertical' :visible {selected_obj.name != ''} :halign \"start\" :spacing 5 "
  manage_box+="(label :class 'manage-title' :wrap true :limit-width 28 :text \"Settings for: \${selected_obj.name}\") "

  manage_box+="(input :class 'wifi-input' :valign \"start\" :password {wifi_password == '' ? false : true} "
  manage_box+="        :onchange \"eww update wifi_password='{}'\" "
  manage_box+="        :onaccept \"iwctl station $IFACE connect '\${selected_obj.name}' --pass '{}' && eww update wifi_password=''\" "
  manage_box+="        :visible {selected_obj.name != '$current_wifi'} ) "

  manage_box+="(box :class 'button-group' :spacing 10 :halign 'center' "

  manage_box+="(eventbox :class 'btn-conn' :cursor \"pointer\" "
  manage_box+="          :onclick \"iwctl station $IFACE connect '\${selected_obj.name}' && eww update wifi_password=''\" "
  manage_box+="          :visible {selected_obj.name != '$current_wifi'} (box :class 'btn-conn-box' (label :text 'Connect'))) "

  manage_box+="(eventbox :class 'btn-disc' :cursor \"pointer\" "
  manage_box+="          :onclick \"iwctl station $IFACE disconnect\" "
  manage_box+="          :visible {selected_obj.name == '$current_wifi'} (box :class 'btn-disc-box' (label :text 'Disconnect'))) "

  manage_box+="(eventbox :class 'btn-rem' :cursor \"pointer\" "
  manage_box+="          :onclick \"iwctl known-networks '\${selected_obj.name}' forget\" (box :class 'btn-rem-box' (label :text 'Forget')))"
  manage_box+=")) "

  echo "$output $manage_box ))"
}

# 初回実行
generate_wifi_ui

# リアルタイム監視 (iwdはnmcli monitorのような手軽な監視がないため、ループで対応)
dbus-monitor --system "type='signal',sender='net.connman.iwd',interface='org.freedesktop.DBus.Properties'" \
  "type='signal',sender='net.connman.iwd',interface='org.freedesktop.DBus.ObjectManager'" |
  while read -r line; do
    generate_wifi_ui
  done
