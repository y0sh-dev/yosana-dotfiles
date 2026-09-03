-- #################
-- ### AUTOSTART ###
-- #################

-- https://wiki.hypr.land/Configuring/Basics/Autostart/


hl.on("hyprland.start", function()
    local commands = {
        -- 1. Infrastructure (Essential to prevent application bugs)
        "dbus-update-activation-environment --all",
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "systemctl --user start hyprpolkitagent",

        -- 2. Input & Clipboard (Utility)
        "fcitx5 -d --replace",
        --"wl-paste --type text --watch cliphist store",
        --"wl-paste --type image --watch cliphist store",
        "y4p daemon",

        -- 3. Visuals & Themes (High priority for user feedback)
        'hyprctl setcursor "Hakurei Reimu-hyprcursor" 24',
        "~/.config/hypr/scripts/wallpaper_start.sh",

        -- 4. UI & Daemons
        "hypridle",
        "gsr-ui",
        "~/.config/eww/launch_bar.sh",
        "easyeffects --hide-window --service-mode",
        "sleep 0.5s; swaync",

        -- 5. Background Tasks & Post-processing
        "sleep 1s; ~/.config/hypr/scripts/dns-warmup.sh",
    }

    -- Execute all commands in the background
    for i = 1, #commands do
        hl.exec_cmd(commands[i] .. " &")
    end
end)

