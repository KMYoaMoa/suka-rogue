-- Tile definitions are data-only.
local defs = {
    floor = { name = "floor",  passable = true,  opaque = false, glyph = ".", color = {0.6, 0.0, 0.0} },
    wall  = { name = "wall",   passable = false, opaque = true,  glyph = "#", color = {0.8, 0.0, 0.0} },
    void  = { name = "void",   passable = false, opaque = true,  glyph = "X", color = {0.4, 0, 0} },
    stairs_down = { name = "stairs_down", passable = true, opaque = false, glyph = ">", color = {0.9, 0.9, 0.2} },
    stairs_up   = { name = "stairs_up",   passable = true, opaque = false, glyph = "<", color = {0.9, 0.9, 0.2} },
    trap        = { name = "trap",        passable = true, opaque = false, glyph = "^", color = {0.9, 0.2, 0.2} },
    door        = { name = "door",        passable = true, opaque = false, glyph = "+", color = {0.7, 0.5, 0.2} },
}
return defs
