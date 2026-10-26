-- RoomType: per-room categorical assignment, mirroring Biome.lua.
-- Pure data (no love, no services).
local RoomType = {}

-- Fixed order: the cumulative weighted roll must not iterate pairs().
local ORDER = { "shop", "storeroom", "ruins" }

-- Shared per-type definitions.
--   weight:   relative probability (1:1:8)
--   items / mobs: how many to generate in a room of this type
--   *_pool:   item/mob TYPE KEYS to draw from (strings; no model imports)
local defs = {
    shop = {
        name = "Shop", weight = 1,
        items = 0, item_pool = {},
        mobs  = 0, mob_pool  = {},
        npcs  = 1, npc_pool  = { "shopkeeper" },
        constructs = 1, construct_pool = { "shelf" },
    },
    storeroom = {
        name = "Storeroom", weight = 1,
        items = 2, item_pool = { "medkit", "sword", "plate", "coin", "pistol" },
        mobs  = 0, mob_pool  = {},
        npcs  = 0, npc_pool  = {},
        constructs = 0, construct_pool = {},
    },
    ruins = {
        name = "Ruins", weight = 8,
        items = 0, item_pool = {},
        mobs  = 2, mob_pool  = { "rat", "bat", "scavenger" },
        npcs  = 0, npc_pool  = {},
        constructs = 1, construct_pool = { "chest" },
    },
}

-- Weighted roll. With weights {1,1,8}: 1 -> shop, 2 -> storeroom, 3..10 -> ruins.
RoomType.pick = function ()
    local total = 0
    for _, key in ipairs(ORDER) do total = total + defs[key].weight end
    local roll = math.random(total)
    for _, key in ipairs(ORDER) do
        roll = roll - defs[key].weight
        if roll <= 0 then return key end
    end
    return ORDER[#ORDER]               -- unreachable; keeps the return total
end

-- Assign a type to every room in the generated map. Mirrors Biome:assign:
-- generation-time, per-room data on the Cell, no tile writes, no content.
RoomType.assign = function (map)
    for _, room in ipairs(map.cell_list) do
        room.room_type = RoomType.pick()
    end
end

-- Nil-safe lookup; an unassigned room falls back to the empty type.
RoomType.def_of = function (room)
    local t = room and room.room_type
    return defs[t] or defs.shop
end

RoomType.defs = defs

return RoomType
