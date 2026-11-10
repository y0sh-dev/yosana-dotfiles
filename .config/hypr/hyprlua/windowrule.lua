-- #############################################################################
-- ### HYPRLAND CONFIGURATION: WINDOW & LAYER RULES (HYPRLUA SPECIFICATION) ###
-- #############################################################################
-- Official Documentation:
-- - Window Rules: https://wiki.hyprland.org/Configuring/Window-Rules/
-- - Lua Configuration: https://wiki.hyprland.org/Configuring/Lua/
--
-- =============================================================================
-- [1] WINDOW RULES SYNTAX: hl.window_rule({ ... })
-- Applies to normal client applications (Toplevel windows: browsers, editors, etc.)
--
-- Syntax & Common Properties:
--   hl.window_rule({
--       name = "optional-unique-rule-name",
--       match = {
--           class            = "^(regex)$",  -- Window class (check via `hyprctl clients`)
--           title            = "^(regex)$",  -- Window title
--           initial_class    = "^(regex)$",  -- Initial class upon application launch
--           initial_title    = "^(regex)$",  -- Initial title upon application launch
--           float            = true/false,   -- Matches only floating / tiled windows
--           fullscreen       = true/false,   -- Matches only fullscreen windows
--           xwayland         = true/false,   -- Matches XWayland vs native Wayland windows
--           pin              = true/false,   -- Matches pinned windows
--           workspace        = "1" / "name", -- Matches windows on target workspace
--       },
--       -- Effects:
--       float             = true,            -- Float the window
--       center            = true,            -- Center on screen
--       size              = "width height",  -- e.g. "900 600" or { 1200, 850 }
--       move              = "x y",           -- e.g. "73% 72%" or "100 100"
--       opacity           = "active [inactive]", -- e.g. "0.8 0.8"
--       opaque            = true,            -- Force 100% opacity
--       no_blur           = true,            -- Disable blur behind this window
--       no_shadow         = true,            -- Disable shadow
--       no_anim           = true,            -- Disable animations
--       no_focus          = true,            -- Prevent stealing focus
--       no_initial_focus  = true,            -- Don't focus on initial map
--       suppress_event    = "maximize",      -- Suppress specific events (e.g. maximize)
--       pin               = true,            -- Show on all workspaces
--       keep_aspect_ratio = true,
--   })
--
-- =============================================================================
-- [2] LAYER RULES SYNTAX: hl.layer_rule({ ... })
-- Applies to Wayland Layer Shell surfaces (TopBar, panels, notifications, modals, etc.)
-- Inspect active layers using: `hyprctl layers`
--
-- Syntax & Common Properties:
--   hl.layer_rule({
--       name = "optional-unique-layer-rule-name",
--       match = {
--           namespace = "^(regex)$", -- Layer namespace from `hyprctl layers`
--       },
--       -- Effects:
--       blur         = true/false, -- Enable background blur (uses size/passes in appearance.lua)
--       ignore_alpha = float,      -- [0.0 - 1.0] Pixels with alpha <= threshold are NOT blurred.
--                                  --   • Status bars & notifications: 0.5 ~ 0.79 (prevents fuzzy edges & shadows)
--                                  --   • Fullscreen overlays / modals: 0.0 ~ 0.2 (allows semi-transparent backdrop blur)
--       xray         = true/false, -- true: only blurs wallpaper behind; false: blurs all windows behind
--       no_anim      = true/false, -- Disable animations for this layer
--       animation    = "style",    -- Specific animation style
--       dim_around   = true/false, -- Compositor-level darkening behind the layer
--       order        = int,        -- Stacking order relative to other layer surfaces
--   })
-- #############################################################################

-----------------------
--- SYSTEM / FIXES   ---
------------------------

-- Ignore maximize requests from windows
hl.window_rule({
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    match = { class = "^(fcitx)$" },
    no_focus = false,
    no_anim = true,
    no_shadow = true,
})

-- Fix drag-and-drop bugs on XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^()$",
        title      = "^()$",
        xwayland   = true,
        float      = true,
    },
    no_focus = true,
})

-- Make XWayland video bridge invisible for clean screen sharing
hl.window_rule({
    name = "^(xwayland-video-bridge-fixes)$",
    match = { class = "^(xwaylandvideobridge)$" },

    opacity          = 0.0,
    no_initial_focus = true,
    no_focus         = true,
    no_anim          = true,
    no_blur          = true,
    max_size         = "1 1",
})

-- Preventing Blurring in the XWayland Context Menu
hl.window_rule({
    match   = { class = "^()$", title = "^()$" },
    no_blur = true,
})

-- Fixed focus/redraw issues in JetBrains IDEs
hl.window_rule({
    name = "JetBrains Fix",
    match = {
        class = "^(jetbrains-).*$",
        float = true,
        title = "^$|^\\s$|^win\\d+$",
    },
    no_initial_focus = true,
})


------------------------
--- DIALOGS & UI     ---
------------------------

-- Center and float the main dialog
hl.window_rule({
    name = "Global Dialogs",
    match = {
        title = "Open File|Save As|Select a File|Choose wallpaper|Library|File Upload|.*wants to save|.*wants to open|Confirm to replace files|Select a Folder"
    },
    float  = true,
    center = true,
})

-- Float system tools
hl.window_rule({
    name = "System Tools",
    match = {
        class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueberry.py|nwg-look|qt6ct|kvantummanager|org.freedesktop.impl.portal.desktop.kde)$"
    },
    float  = true,
    center = true,
    size   = "900 600",
})


------------------------
--- GAMING           ---
------------------------

-- Settings to enable tearing and minimize latency
hl.window_rule({
    name = "Gamer Immediate Mode",
    match = {
        title = ".*\\.exe|.*minecraft.*",
        class = "^(steam_app).*|^(cs2)$"
    },
    --immediate = true,
})

-- Do not apply shadows to tiled windows
hl.window_rule({
    match    = { float = false },
    no_shadow = true,
})

-- Optimize OBS performance when unfocused
hl.window_rule({
    name             = "OBS Performance",
    match            = { class = "^(obs)$" },
    render_unfocused = false,
})


------------------------
--- APP SPECIFIC     ---
------------------------

-- Thunar: Set opacity for main window
hl.window_rule({
    match   = { class = "^(thunar|Thunar)$" },
    opacity = "0.8 0.8", -- active inactive
    float   = true,
    size    = { 1200, 850 },
})

-- Vivaldi: Always keep fully opaque
hl.window_rule({
    match  = { class = "^(vivaldi-stable)$" },
    opaque = true,
})

-- Powerful Regular Expressions for Picture-in-Picture
hl.window_rule({
    name = "Picture-in-Picture Fix",
    match = {
        title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
    },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    move              = "73% 72%", 
    size              = "25% 25%",
})

hl.window_rule({
    name = "Satty-screenshot Fix",
    match = { class = "^(com.gabm.satty)$" },
    float = true,
})

------------------------
--- GAMER / TOOLS    ---
------------------------

-- Float and center secondary Steam windows
hl.window_rule({
    name = "Steam floating windows",
    match = {
        class = "^(steam)$",
        title = "Friends List|Steam - News|.* - Chat|Settings|.* - Shop"
    },
    float  = true,
    center = true,
})

-- Steam Games: Force full-screen launch automatically
hl.window_rule({
    name = "Steam Games",
    match = { class = "^(steam_app_)(.*)$" },
    fullscreen = true,
})

hl.window_rule({
    name = "Steam Proton",
    match = { class = "^(steam_proton)(.*)$" },
    fullscreen = true,
})

-- War Thunder: Processing optimization
hl.window_rule({
    match = { class = "^(War Thunder)(.*)$" },
    render_unfocused = false,
    fullscreen = true,
    content = "game",
    immediate = true,
    no_anim = true,
    no_blur = true,
    no_dim = true
})

------------------------
--- LAYER RULES      ---
------------------------

-- 1. Quickshell PowerMenu (Full-screen overlay blur)
-- Backdrop dim is opacity 0.38; ignore_alpha 0.2 ensures the entire screen is blurred smoothly
hl.layer_rule({
    name         = "quickshell-powermenu-blur",
    match        = { namespace = "^(powermenu)$" },
    blur         = true,
    ignore_alpha = 0.2,
    xray         = false,
})

-- Quickshell Calendar & Meteorology Popup Blur
hl.layer_rule({
    name         = "quickshell-calendar-blur",
    match        = { namespace = "^(calendar)$" },
    blur         = true,
    ignore_alpha = 0.2,
    xray         = false,
})

-- Quickshell Audio Panel Blur
hl.layer_rule({
    name         = "quickshell-audio-blur",
    match        = { namespace = "^(quickshell-audio)$" },
    blur         = true,
    ignore_alpha = 0.2,
    xray         = false,
})

-- 2. Quickshell TopBar Islands Blur (Floating bar pill blur)
-- ignore_alpha 0.5 prevents transparent padding/gaps between islands from blurring
hl.layer_rule({
    name         = "quickshell-topbar-blur",
    match        = { namespace = "^(quickshell)$" },
    blur         = true,
    ignore_alpha = 0.5,
})


-- 4. Notifications (SwayNC) & System Dialogs
hl.layer_rule({
    name         = "notifications-and-dialogs-blur",
    match        = { namespace = "^(swaync-control-center|swaync-notification-window|dunst|notifications|logout_dialog)$" },
    blur         = true,
    ignore_alpha = 0.2,
    xray         = false,
})

-- 5. Fast UI Tools (Disable animations for instant response)
hl.layer_rule({
    name    = "no-anim-selectors",
    match   = { namespace = "^(selection|hyprpicker|indicator.*)$" },
    no_anim = true,
})

