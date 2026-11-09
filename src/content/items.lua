-- Item definitions are data-only. Runtime behavior lives in modules/items.
local defs = {
    sword   = { name = "Rusty Sword",  kind = "melee",
                glyph = "/", color = {0.85, 0.85, 0.85},
                tags = { "equippable", "weapon" },
                stats = { damage = 12, range = 1 } },
    pistol  = { name = "Pistol",       kind = "ranged",
                glyph = ")", color = {0.80, 0.80, 0.88},
                tags = { "equippable", "weapon" },
                stats = { damage = 6, accuracy = 0.75 } },
    plate   = { name = "Iron Plate",   kind = "armor",
                glyph = "]", color = {0.55, 0.60, 0.70},
                tags = { "equippable" },
                stats = { defense = 8 } },
    medkit  = { name = "Medkit",       kind = "base",
                glyph = "+", color = {0.30, 0.90, 0.30},
                tags = { "usable", "consumable", "stackable" },
                stats = { heal = 30 } },
    coin    = { name = "Coin",         kind = "base",
                glyph = "o", color = {0.95, 0.85, 0.25},
                tags = { "stackable" },
                stats = { value = 1 } },
}

return defs
