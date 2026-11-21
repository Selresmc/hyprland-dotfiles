-- monitor.lua
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Catch-all default monitor
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Internal laptop display (eDP-1).
-- The panel reports 60 Hz as its preferred mode but also supports 120 Hz.
-- "highrr" picks the highest refresh rate (resolution as tie-breaker).
-- This rule must come AFTER the catch-all: the last matching rule wins.
hl.monitor({
    output   = "eDP-1",
    mode     = "highrr",
    position = "auto",
    scale    = 2,
    bitdepth = 10,
})
