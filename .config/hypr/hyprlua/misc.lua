-- ################################
-- ### Rendering / Optimization ###
-- ################################

-- See https://wiki.hypr.land/Configuring/Basics/Variables/#misc
-- and https://wiki.hypr.land/Configuring/Basics/Variables/#render
-- https://wiki.hypr.land/Configuring/Basics/Variables/#xwayland
-- https://wiki.hypr.land/Configuring/Basics/Variables/#debug


hl.config({
    misc = {
        -- Visuals and resource reduction
        disable_hyprland_logo           = true,
        disable_splash_rendering        = true,
        force_default_wallpaper         = 0,
        background_color                = 0x000000,
        render_unfocused_fps            = 24,

        -- Fullscreen and focus control
        on_focus_under_fullscreen       = 0,
        exit_window_retains_fullscreen  = false,
        focus_on_activate               = false,
        initial_workspace_tracking      = 1,

        -- Mouse, keyboard, and layer behavior
        mouse_move_focuses_monitor      = true,
        always_follow_on_dnd            = true,
        layers_hog_keyboard_focus       = true,

        -- Monitor control and power management
        vrr                             = 3,
        mouse_move_enables_dpms         = false,
        key_press_enables_dpms          = true,

        -- Animation overrides
        animate_manual_resizes          = false,
        animate_mouse_windowdragging    = false,

        -- Session resilience and warning suppression
        allow_session_lock_restore      = true,
        disable_autoreload              = false,
        disable_hyprland_guiutils_check = true,
    },

    render = {
        -- Frame synchronization and rendering stability
        direct_scanout             = 0,
        commit_timing_enabled      = true,
        new_render_scheduling      = false,
        xp_mode                    = false,

        -- SDR/HDR color management
        cm_enabled                 = true,
        cm_sdr_eotf                = "gamma22force",
        non_shader_cm              = 2,
        non_shader_cm_interop      = 2,
        cm_auto_hdr                = 0,

        -- Display communication and effects
        send_content_type          = false,
        ctm_animation              = 2,
        use_fp16                   = 2,

        -- Fixes for image textures and screen sharing bugs
        expand_undersized_textures = true,
        keep_unmodified_copy       = 2,
    },

    xwayland = {
        -- XWayland compatibility settings
        enabled            = true,
        force_zero_scaling = true,
    },

    debug = {
        -- Power saving and frame resource minimization
        vfr                  = true,
        damage_tracking      = 2,
        invalidate_fp16      = 1,

        -- Scaling and pixel alignment
        disable_scale_checks = true,

        -- Storage protection and disk I/O reduction
        disable_logs         = true,
        disable_time         = true,
        enable_stdout_logs   = false,

        -- Error bar and notification control
        suppress_errors      = false,
    },
})
