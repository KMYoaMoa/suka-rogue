-- Mob definitions are data-only. Behavior lives in modules/actors.
local defs = {
    rat = {
        name = "Rat", kind = "enemy",
        glyph = "r", color = {0.75, 0.60, 0.45},
        tags = { "enemy" },
        stats = { health = 5, attack = 2, defense = 0, speed = 2 },
        equipment = {},
        drops = { { type = "coin", qty = 1 } },
    },
    bat = {
        name = "Bat", kind = "enemy",
        glyph = "b", color = {0.65, 0.55, 0.75},
        tags = { "enemy" },
        stats = { health = 3, attack = 1, defense = 0, speed = 2 },
        equipment = {},
        drops = { { type = "coin", qty = 1 } },
    },
    scavenger = {
        name = "Scavenger", kind = "enemy",
        glyph = "s", color = {0.90, 0.70, 0.30},
        tags = { "enemy" },
        stats = { health = 12, attack = 4, defense = 1, speed = 3 },
        equipment = { weapon = "sword", armor = "plate" },
        drops = { { type = "medkit", qty = 1 }, { type = "coin", qty = 3 } },
    },
    unknown = {
        name = "Something", kind = "enemy",
        glyph = "?", color = {0.80, 0.80, 0.80},
        tags = { "enemy" },
        stats = { health = 1, attack = 1, defense = 0, speed = 1 },
        equipment = {},
        drops = {},
    },
}

return defs
