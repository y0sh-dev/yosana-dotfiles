-- ######################
-- ### INPUT / CURSOR ###
-- ######################

-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- https://wiki.hypr.land/Configuring/Basics/Variables/#cursor


hl.config({
    input = {
        -- Keyboard settings
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 300,
        repeat_rate = 35,

        -- Mouse sensitivity and acceleration profile
        sensitivity = 0,
        accel_profile = "flat",

        -- Scroll on button press configuration
        scroll_method = "on_button_down",
        scroll_button = 274,

        -- Window focus behavior
        follow_mouse = 1,
        float_switch_override_focus = 0,

        -- Touchpad configuration
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.3,
        },
    },


    cursor = {
        -- Theme and system synchronization
        sync_gsettings_theme = true,
        enable_hyprcursor = true,

        -- Rendering and performance profiles
        no_hardware_cursors = 2,
        use_cpu_buffer = 0,

        -- Stutter prevention for Variable Refresh Rate (VRR)
        no_break_fs_vrr = 1,
        min_refresh_rate = 60,

        -- Cursor movement and visibility control
        no_warps = true,
        hide_on_key_press = true,
    },
})
