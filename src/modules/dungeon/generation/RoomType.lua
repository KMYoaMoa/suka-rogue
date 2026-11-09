-- RoomType: per-room categorical assignment, mirroring Biome.lua.
-- Pure data (no love, no services).
local RoomType = {}

local data = require "content.rooms"
local ORDER = data.ORDER
local defs = data.defs


-- Weighted roll. With weights {1,1,8}: 1 -> shop, 2 -> storeroom, 3..10 -> ruins.
RoomType.pick = function (rng)
    local random = rng and function (...) return rng:random(...) end or math.random
    local total = 0
    for _, key in ipairs(ORDER) do total = total + defs[key].weight end
    local roll = random(total)
    for _, key in ipairs(ORDER) do
        roll = roll - defs[key].weight
        if roll <= 0 then return key end
    end
    return ORDER[#ORDER]               -- unreachable; keeps the return total
end

-- Assign a type to every room in the generated map. Mirrors Biome:assign:
-- generation-time, per-room data on the Cell, no tile writes, no content.
RoomType.assign = function (map, rng)
    for _, room in ipairs(map.cell_list) do
        room.room_type = RoomType.pick(rng)
    end
end

-- Nil-safe lookup; an unassigned room falls back to the neutral empty type.
RoomType.def_of = function (room)
    local t = room and room.room_type
    return defs[t] or defs.empty
end


return RoomType
