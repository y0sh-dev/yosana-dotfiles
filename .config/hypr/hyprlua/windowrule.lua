-- ##############################
-- ### WINDOWS AND WORKSPACES ###
-- ##############################

-- https://wiki.hyprland.org/Configuring/Window-Rules/


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

-- Batch Apply Background Blur
hl.layer_rule({
    match        = { namespace = "eww-powerwd|dunst|notifications|logout_dialog" },
    blur         = true,
    ignore_alpha = 0.5,
})

-- Disable animation for a specific layer
hl.layer_rule({
    match   = { namespace = "selection|hyprpicker|indicator.*" },
    no_anim = true,
})

-- X-ray effect on a layer
hl.layer_rule({
    match = { namespace = ".*" },
    xray  = true,
})

