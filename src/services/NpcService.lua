local Npc              = require "models.npc.Npc"
local Dungeon          = require "models.dungeon.Dungeon"
local DungeonService   = require "services.DungeonService"
local MessageService   = require "services.MessageService"

local NpcService = {}

NpcService.can_spawn_at = function (x, y)
    return DungeonService.is_free(x, y)
       and not DungeonService.is_entrance(x, y)
end

-- Spawn interface. `room` is optional but required for room-scoped conditions.
NpcService.spawn = function (type_name, x, y, room)
    if not NpcService.can_spawn_at(x, y) then return nil end
    local npc = Npc.new(type_name)
    npc.x, npc.y, npc.room = x, y, room
    Dungeon.npcs[#Dungeon.npcs + 1] = npc
    return npc
end

-- NPCs are immovable: no invoker, no reschedule, no act. They never take turns.

NpcService.alive_in_room = function (room)
    for _, npc in ipairs(Dungeon.npcs) do
        if npc.room == room and not npc.dead then return true end
    end
    return false
end

NpcService.dead_in_room = function (room)
    for _, npc in ipairs(Dungeon.npcs) do
        if npc.room == room and npc.dead then return true end
    end
    return false
end

-- Kill interface: the dead entry is kept in Dungeon.npcs so
-- "NPC dead in room" conditions still work; occupant_at ignores it, so its
-- tile becomes free.
NpcService.kill = function (npc)
    if npc.dead then return end
    npc.dead = true
    MessageService.add(string.format("The %s dies.", npc.name), "info")
end

return NpcService