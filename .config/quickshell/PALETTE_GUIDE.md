# Pywal & wpgtk Color Palette Guide (SSOT for Rice Theming)

This document provides a comprehensive reference on how **Pywal** and **wpgtk (`wpg`)** extract, calculate, and assign colors from wallpapers to `colors.json`, `colors.css`, and terminal slots (`color0` - `color15`).

---

## 1. Palette Overview & ANSI Structure

A generated Pywal theme produces **16 ANSI terminal colors** plus **3 special properties**:

```text
┌────────────────────────────────────────────────────────┐
│ Special:  [background]  [foreground]  [cursor]         │
├────────────────────────────────────────────────────────┤
│ Normal:   [0: Black]  [1: Red]    [2: Green]  [3: Yellow]  │
│           [4: Blue]   [5: Magenta][6: Cyan]   [7: White]   │
├────────────────────────────────────────────────────────┤
│ Bright:   [8: Gray]   [9: B.Red]  [10: B.Grn] [11: B.Yel]  │
│           [12: B.Blu] [13: B.Mag] [14: B.Cya] [15: B.Whi]  │
└────────────────────────────────────────────────────────┘
```

---

## 2. Detailed Color Semantics & Extraction Logic

### Special Colors
| Key | Default Nature & Extraction Logic | Recommended UI Role |
| :--- | :--- | :--- |
| **`background`** | Darkest dominant tone extracted from the image. Darkened slightly by Pywal to ensure a rich base. | **Island/Window Background** (`Theme.bg`) |
| **`foreground`** | Lightest dominant color with high contrast relative to `background`. | **Main Text / Primary Glyphs** (`Theme.fg`) |
| **`cursor`** | Typically identical to `foreground`. | Cursor, focus indicators |

### Normal Colors (`color0` - `color7`)
Standard ANSI 8-color palette.
| Slot | ANSI Name | Extraction & Character | Recommended UI Role |
| :---: | :--- | :--- | :--- |
| **`color0`** | Black | Very dark tone, close to `background` (often slightly darker or matched). | Surface background, subtle card fills |
| **`color1`** | Red | Warmest/Reddest tone extracted. | **Urgent / Power / Warning** (`Theme.urgent`, shutdown button) |
| **`color2`** | Green | Greenish / earthy mid-tone. | Success, battery charging, active status |
| **`color3`** | Yellow | Golden, amber, or warm accent. | Caution, volume warning, highlights |
| **`color4`** | Blue | Prominent cool/blue tone. **Pywal often assigns the strongest wallpaper identity here.** | **Primary Accent** (`Theme.accent`, active workspaces) |
| **`color5`** | Magenta / Purple | Secondary cool/magenta tone. | Secondary accent, media pill highlight, DND switch |
| **`color6`** | Cyan / Sky | Bright cool tone. | Header titles, network indicators, info tags |
| **`color7`** | White / Light Gray | Soft body-text light gray. | Secondary body text, inactive icons |

### Bright / High-Intensity Colors (`color8` - `color15`)
Bright / bold variants.
| Slot | ANSI Name | Extraction & Character | Recommended UI Role |
| :---: | :--- | :--- | :--- |
| **`color8`** | Bright Black (Dark Gray) | Calculated as a dimmed/lightened variant of the background. | **Subtext, Inactive Workspaces, Borders** (`Theme.subtext`, `Theme.border`) |
| **`color9`** | Bright Red | Saturated/lighter version of `color1`. | Hover state for urgent/danger buttons |
| **`color10`** | Bright Green | Saturated/lighter version of `color2`. | Vibrant status badges |
| **`color11`** | Bright Yellow | Saturated/lighter version of `color3`. | Active notification badges |
| **`color12`** | Bright Blue | Saturated/lighter version of `color4`. | Hover state for primary accent elements |
| **`color13`** | Bright Magenta | Saturated/lighter version of `color5`. | Music player active state |
| **`color14`** | Bright Cyan | Saturated/lighter version of `color6`. | Special highlights |
| **`color15`** | Bright White | Purest/highest luminance light tone in the image. | Selected text, active clock glyph |

---

## 3. How Pywal vs. wpgtk (`wpg`) Assigns Colors

### Standard Pywal Behavior
Pywal delegates color extraction to backends (e.g. `imagemagick`, `colorthief`, `haishoku`). 
- Raw image extraction returns colors ordered purely by **pixel frequency** or **luminance**.
- Pywal assigns them sequentially without strictly enforcing semantic hue (e.g., if a wallpaper is monochromatic blue, `color1` might be navy blue instead of red).

### wpgtk (`wpg`) Smart Sort Algorithm
`wpgtk` improves upon raw pywal by applying **Euclidean Distance sorting in CIELAB color space**:
1. It compares extracted colors against canonical ANSI target hues (Red, Green, Yellow, Blue, Magenta, Cyan).
2. It assigns the color that is *closest in hue distance* to the corresponding ANSI slot.
3. This ensures that `color1` remains warm/red-ish, `color2` remains green-ish, and `color4` remains cool/blue-ish across different wallpapers.

---

## 4. UI Theming Recipe (Recommended Mapping in `Theme.qml`)

For an elegant, quiet, and minimal Rice:

```text
[ Base Surfaces ]
• Island Background:  special.background (#000000 or deep night)
• Hover Fill:         color0 or slight alpha tint of surface (10% white)
• Border/Divider:     border.width: 0 (borderless islands) OR color8 with 0.15 alpha

[ Text & Icons ]
• Primary Heading:    special.foreground (Crisp & clear)
• Subtext / Inactive: color8 (Quiet gray, does not distract)
• Empty Dots:         color8 (with opacity 0.35)

[ Accent & Interaction ]
• Primary Accent:     color4 (Default key accent) or color5
• Power / Urgent:     color1 or color3
• Notifications:      color4 / color6
```

---

## 5. Hot Reloading Architecture in Quickshell

When `wpg` changes the wallpaper:
1. `wpg` updates `~/.cache/wal/colors.json` and `~/.cache/wal/colors.css`.
2. Quickshell's `FileView` has `watchChanges: true` and triggers `theme.reload()`.
3. Properties (`Theme.bg`, `Theme.fg`, `Theme.accent`) reactively notify all QML bindings.
4. TopBar, PowerMenu, and components update their colors instantly without restarting Quickshell.
