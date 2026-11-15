-- ##################
-- ### animations ###
-- ##################
-- Concept: "Rapid transit in a silent midnight station"
-- Arrives with fierce momentum, settles in absolute stillness without bounce,
-- and departs into the distance as if nothing was ever there.

-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

-- Bezier Curves
hl.curve("trainArrive", { type = "bezier", points = { {0.28, 0.01}, {0.12, 1.0} } }) -- Subtle approach tremor -> fierce entry -> silent glide to stop
hl.curve("trainDepart", { type = "bezier", points = { {0.55, 0.02}, {0.92, 0.16} } }) -- Gentle brake-release tremor -> instant acceleration into emptiness
hl.curve("railSlide",   { type = "bezier", points = { {0.20, 0.03}, {0.14, 1.0} } }) -- Weighted departure -> precision lateral glide without overshot
hl.curve("signalFade",  { type = "bezier", points = { {0.25, 0.05}, {0.20, 1.0} } }) -- Subtle signal pre-glow -> calm illumination
hl.curve("liner",       { type = "bezier", points = { {0.0, 0.0},   {1.0, 1.0} } })  -- True linear curve

-- Windows
-- hl.animation({ leaf = "windows",     enabled = true, speed = 4.2, bezier = "trainArrive", style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4.2, bezier = "trainArrive", style = "slidefade 18%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.8, bezier = "trainDepart", style = "slidefade 12%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.2, bezier = "railSlide",   style = "slide" })

-- Borders & Fades
hl.animation({ leaf = "border",      enabled = true, speed = 1.0, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 1.0, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3.5, bezier = "signalFade" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 3.8, bezier = "trainArrive" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 2.6, bezier = "trainDepart" })

-- Workspaces (Zero bounce: precision express transit)
hl.animation({ leaf = "workspaces",    enabled = true, speed = 4.4, bezier = "railSlide",   style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 4.4, bezier = "trainArrive", style = "slidefade 10%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.2, bezier = "trainDepart", style = "slidefade 10%" })

-- Layers (Default fallback: refined slidefade instead of generic popin)
hl.animation({ leaf = "layers",      enabled = true, speed = 3.8, bezier = "trainArrive", style = "fade" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 4.0, bezier = "trainArrive", style = "slidefade 8%" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 2.6, bezier = "trainDepart", style = "fade" })
