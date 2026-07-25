-- #############################
-- ### ENVIRONMENT VARIABLES ###
-- #############################

-- See https://wiki.hypr.land/Configuring/Environment-variables/


-- --- GPU & Backend (Aquamarine) ---
hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0")
hl.env("AQ_NO_ATOMIC", "0")

-- --- Graphics & Performance (Mesa/RADV) ---
hl.env("RADV_PERFTEST", "ext_sync")
hl.env("RADV_DEBUG", "syncshaders")
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")
hl.env("ANGLE_DEFAULT_PLATFORM", "vulkan")

-- --- Toolkit Backends (Wayland Native) ---
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- --- XDG Specifications ---
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- --- Display & UI Scaling ---
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("GDK_SCALE", "auto")
hl.env("XWAYLAND_NO_GLAMOR", "0")

-- --- Cursor (Hyprcursor) ---
hl.env("HYPRCURSOR_THEME", "Hakurei Reimu-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "24")
-- hl.env("XCURSOR_THEME", "Hakurei Reimu-hyprcursor")
-- hl.env("XCURSOR_SIZE", "24")

-- --- IME (Fcitx5) ---
hl.env("XMODIFIERS", "@im=fcitx")
