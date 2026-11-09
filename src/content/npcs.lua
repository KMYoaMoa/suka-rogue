-- NPC definitions are data-only.
local defs = {
    shopkeeper = {
        name = "Shopkeeper", kind = "npc",
        glyph = "n", color = {0.30, 0.90, 0.30},
        tags = { "npc", "neutral" },
        stats = { health = 10 },
    },
    unknown = {
        name = "Someone", kind = "npc",
        glyph = "n", color = {0.30, 0.90, 0.30},
        tags = { "npc", "neutral" },
        stats = { health = 1 },
    },
}

return defs
