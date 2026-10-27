-- Mob: one *definition* per type (shared, immutable; the tile.lua/Item.lua
-- pattern) and one *instance* per concrete creature on the map.
local Mob = {}

local Item = require "models.item.Item"

-- Shared per-type definitions. Keyed by type name.
--   kind:      "enemy" today (beasts will be a tag, not a different kind)
--   tags:      capability/classification flags ("enemy", later "beast")
--   stats:     health (max HP), attack, defense, speed (ticks between turns)
--   equipment: slot -> item type key; instantiated on spawn into mob.equipped
--   drops:     { { type = <item type key>, qty = n }, ... }
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
        equipment = { weapon = "sword", armor = "plate" },   -- the mob HAS items
        drops = { { type = "medkit", qty = 1 }, { type = "coin", qty = 3 } },
    },
    unknown = {   -- nil-safe fallback; unknown names spawn this
        name = "Something", kind = "enemy",
        glyph = "?", color = {0.80, 0.80, 0.80},
        tags = { "enemy" },
        stats = { health = 1, attack = 1, defense = 0, speed = 1 },
        equipment = {},
        drops = {},
    },
}

-- Create a mob instance of `type_name`. Note: `type` is the REGISTRY KEY
-- (not def.name): the display name lives in the def, so a future
-- spawn-by-type never resolves to the wrong definition.
Mob.new = function (type_name)
    local def = defs[type_name] or defs.unknown
    return {
        type     = type_name,            -- registry key (see note above)
        def      = def,
        name     = def.name,             -- generic occupant contract (DungeonService)
        glyph    = def.glyph,            -- generic occupant contract (rendering)
        color    = def.color,
        x        = 0,
        y        = 0,
        health   = def.stats.health,     -- current HP; max is def.stats.health
        equipped = { weapon = nil, armor = nil },
        dead     = false,                -- soft-cancel for the scheduled invoker
        invoker  = nil,                  -- set by MobService.spawn
        ai       = {
            state        = "wander",   -- "wander" | "pursue" | "patrol" | "return"
            territory    = nil,        -- Cell room where the mob was born
            wait         = 2,           -- mob actions to wait before the next loop
            steps_left   = 0,           -- steps left in the current 3-step run
            dir          = nil,         -- {dx, dy} for the current run
            patrol_loops = 0,           -- remaining patrol loops
            last_seen    = nil,         -- {x, y} of the pursued target
            target       = nil,         -- Player table or Npc instance
        },
    }
end

Mob.def_of = function (mob) return mob and mob.def or defs.unknown end
Mob.name   = function (mob) return Mob.def_of(mob).name end
Mob.glyph  = function (mob) return Mob.def_of(mob).glyph end
Mob.color  = function (mob) return Mob.def_of(mob).color end

-- Tag queries, same shape as Item.has_tag (future: "beast").
Mob.has_tag = function (mob, tag)
    for _, t in ipairs(Mob.def_of(mob).tags) do
        if t == tag then return true end
    end
    return false
end

-- Derived stats: base + composed equipment. Pure model logic, shared by
-- MobService and MobAIService without a service-level cycle.
Mob.attack_of = function (mob)
    local weapon = mob and mob.equipped and mob.equipped.weapon
    return Mob.def_of(mob).stats.attack
         + ((weapon and Item.def_of(weapon).stats.damage) or 0)
end

Mob.defense_of = function (mob)
    local armor = mob and mob.equipped and mob.equipped.armor
    return Mob.def_of(mob).stats.defense
         + ((armor and Item.def_of(armor).stats.defense) or 0)
end

return Mob
