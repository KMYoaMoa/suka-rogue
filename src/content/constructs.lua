-- Construct definitions are data-only.
local defs = {
    chest = {
        name = "Chest", kind = "construct",
        glyph = "$", color = {0.90, 0.75, 0.25},
        tags = { "construct" },
        requires = {},
    },
    shelf = {
        name = "Shelf", kind = "construct",
        glyph = "=", color = {0.65, 0.45, 0.25},
        tags = { "construct" },
        requires = { "npc_alive_in_room" },
    },
    unknown = {
        name = "Object", kind = "construct",
        glyph = "?", color = {0.80, 0.80, 0.80},
        tags = { "construct" },
        requires = {},
    },
}

return defs
