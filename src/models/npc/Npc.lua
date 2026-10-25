
-- Npc: one *definition* per type (shared, immutable; the Mob.lua pattern)
-- and one *instance* per immovable neutral creature.
local Npc = {}

local defs = {
    shopkeeper = {
        name = "Shopkeeper", kind = "npc",
        glyph = "n", color = {0.30, 0.90, 0.30},      -- green (draft)
        tags = { "npc", "neutral" },
        stats = { health = 10 },
    },
    unknown = {   -- nil-safe fallback
        name = "Someone", kind = "npc",
        glyph = "n", color = {0.30, 0.90, 0.30},
        tags = { "npc", "neutral" },
        stats = { health = 1 },
    },
}

-- `type` is the registry key (not def.name); `room` is set at spawn and is
-- what room-scoped conditions (e.g. "npc_alive_in_room") compare against.
Npc.new = function (type_name)
    local def = defs[type_name] or defs.unknown
    return {
        type   = type_name,
        def    = def,
        name   = def.name,
        glyph  = def.glyph,      -- generic occupant contract (rendering)
        color  = def.color,
        x      = 0,
        y      = 0,
        room   = nil,
        health = def.stats.health,
        dead   = false,          -- kept in the list when dead (see §3.5)
    }
end

Npc.def_of = function (npc) return npc and npc.def or defs.unknown end
Npc.name   = function (npc) return Npc.def_of(npc).name end
Npc.glyph  = function (npc) return Npc.def_of(npc).glyph end
Npc.color  = function (npc) return Npc.def_of(npc).color end

Npc.has_tag = function (npc, tag)
    for _, t in ipairs(Npc.def_of(npc).tags) do
        if t == tag then return true end
    end
    return false
end

return Npc