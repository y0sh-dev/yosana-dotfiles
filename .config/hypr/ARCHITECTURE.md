# Hyprland-Lua Architecture & Dispatcher Specification

This document details the unique Lua configuration mechanism, dispatcher syntax, and troubleshooting rules for this Hyprland setup.

---

## 1. Core Architecture: Hyprland with Lua Backend

Unlike standard Hyprland installations that use the proprietary Hyprlang syntax (`hyprland.conf`), this setup runs a **native Lua scripting backend** (`hyprland.lua`).

```
~/.config/hypr/
├── hyprland.lua               # Master entry point (requires modules below)
└── hyprlua/
    ├── monitors.lua          # Monitor resolutions & refresh rates
    ├── workspace.lua         # Workspace assignments & persistent rules
    ├── autostart.lua         # Startup background daemons
    ├── environment.lua       # Session environment variables
    ├── appearance.lua        # Borders, gaps, rounding, active colors
    ├── animations.lua        # Bezier curves & layout transitions
    ├── layout.lua            # Dwindle / Master tiling configuration
    ├── misc.lua              # Misc compositor settings (VFR, VRR)
    ├── input.lua             # Keyboard layout, mouse sensitivity & touchpad
    ├── keybindings.lua       # Keyboard shortcuts via hl.bind & hl.dsp
    └── windowrule.lua        # Window & Layer surface behavior rules
```

---

## 2. The Dispatcher Gotcha: Calling `hl.dsp` via CLI

### Why standard `hyprctl dispatch` fails
In standard Hyprland:
```bash
# STANDARD HYPRLAND (Fails in Hyprland-Lua!)
hyprctl dispatch exit
hyprctl dispatch killactive
```
In Hyprland-Lua, `hyprctl dispatch <arg>` executes an internal Lua expression: `return hl.dispatch(<arg>)`.
Passing raw tokens like `exit` results in `error: expected a dispatcher or a lua function (code 7)` because `exit` is an undefined Lua identifier.

### The Correct Syntax
You must invoke the **`hl.dsp`** Lua namespace with function parentheses and shell quotes:

```bash
# Correct Hyprland-Lua CLI commands:
hyprctl dispatch 'hl.dsp.exit()'
hyprctl dispatch 'hl.dsp.window.close()'
hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })'
hyprctl dispatch 'hl.dsp.workspace({ target = "1" })'
hyprctl dispatch 'hl.dsp.exec_cmd("kitty")'
```

### Quickshell / IPC Integration Rule
When triggering actions from external tools (Quickshell, Python, or shell scripts):
```qml
// In Quickshell (e.g., PowerMenu.qml):
Hyprland.dispatch("hl.dsp.exit()")       // Correct
Hyprland.dispatch("exit")                 // WRONG: Triggers error code 7
```

---

## 3. Key Dispatcher Cheatsheet (`hl.dsp`)

| Action | Standard Hyprlang | Hyprland-Lua (`hl.dsp`) |
| :--- | :--- | :--- |
| **Exit Hyprland** | `exit` | `hl.dsp.exit()` |
| **Close Active Window** | `killactive` | `hl.dsp.window.close()` |
| **Toggle Floating** | `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| **Toggle Split (Dwindle)**| `togglesplit` | `hl.dsp.layout("togglesplit")` |
| **Move Focus** | `movefocus, l/r/u/d` | `hl.dsp.focus({ direction = "left" })` |
| **Move Window** | `movewindow, l/r/u/d`| `hl.dsp.window.move({ direction = "left" })` |
| **Change Workspace** | `workspace, 2` | `hl.dsp.workspace({ target = "2" })` |
| **Move to Workspace** | `movetoworkspace, 3` | `hl.dsp.window.move_to_workspace({ target = "3" })` |
| **Execute Command** | `exec, <command>` | `hl.dsp.exec_cmd("<command>")` |

---

## 4. Window Rules & Layer Rules Syntax (`windowrule.lua`)

Window rules and Layer rules are declared as structured Lua tables instead of comma-separated strings.

### Window Rules (`hl.window_rule`)
Target normal applications (browsers, editors, terminals):
```lua
hl.window_rule({
    name = "floating-picture-in-picture",
    match = {
        class = "^(firefox|google-chrome|vivaldi)$",
        title = "^(Picture-in-Picture)$",
    },
    float = true,
    pin = true,
    size = "640 360",
    move = "100%-650 100%-370",
})
```

### Layer Rules (`hl.layer_rule`)
Target Wayland Layer Shell surfaces (Quickshell panels, SwayNC, Rofi, Applets):
```lua
hl.layer_rule({
    name = "quickshell-island-blur",
    match = {
        namespace = "quickshell",
    },
    blur = true,
    no_anim = true,
})
```

---

## 5. Diagnostic Tools

### 1. Identify Window Properties (Class & Title)
To find the exact `class` and `title` to write window rules for:
```bash
hyprctl clients | grep -E "(class|title)"
```

### 2. Identify Active Layer Shell Surfaces
To find the exact `namespace` to write layer rules for:
```bash
hyprctl layers
```

### 3. Reload Configuration
```bash
hyprctl reload
```
