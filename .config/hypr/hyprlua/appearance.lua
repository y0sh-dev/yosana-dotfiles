-- ##################
-- ### APPEARANCE ###
-- ##################

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration


local colors = require("hyprlua.color")

hl.config({
    general = {
        -- Gaps and borders
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,

        ["col.active_border"] = colors.color2,
        ["col.inactive_border"] = colors.color7,

        -- Layout and basic behavior
        layout = "dwindle",
        allow_tearing = false,

        -- Mouse resize optimization
        resize_on_border = true,
        extend_border_grab_area = 15,
        hover_icon_on_border = true,

        -- Window snapping settings
        snap = {
            enabled = true,
            window_gap = 10,
            monitor_gap = 10,
            border_overlap = true,
            respect_gaps = false,
        },
    },

    decoration = {
        -- Window geometry and corners
        rounding = 6,
        rounding_power = 4.0,

        -- Window opacity
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,

        -- Dimming effects
        dim_modal = true,
        dim_inactive = false,

        -- Shadow configuration
        shadow = {
            enabled = true,
            range = 15,
            render_power = 3,
            color = colors.color0,
            offset = {0, 2},
            scale = 1.0,
        },

        -- Blur configuration
        blur = {
            enabled = true,
            size = 1,
            passes = 3,
            new_optimizations = true,
            xray = false,
            ignore_opacity = true,
            vibrancy = 0.1696,

            -- Target extensions for blur
            popups = true,
            popups_ignorealpha = 0.2,
        },
    },
})
