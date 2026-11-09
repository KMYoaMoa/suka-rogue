local Dungeon          = require "models.dungeon.Dungeon"
local World            = require "game.World"
local RoomType         = require "models.dungeon.RoomType"
local DungeonService   = require "services.DungeonService"
local Items            = require "modules.items"
local Actors           = require "modules.actors"
local MobService       = Actors.MobService
local NpcService       = Actors.NpcService
local ConstructService = Actors.ConstructService
local Context          = require "game.Context"

local function random(...)
    local game = Context.current
    if game and game.rng then return game.rng:random(...) end
    return math.random(...)
end

local SpawnService = {}

local MAX_TRIES = 50

-- A tile that may receive room content: in bounds, passable, unoccupied
-- (including the player), and no existing item. When `avoid_entrance` is true
-- (immovable NPCs/constructs), room entrance/exit tiles are excluded too.
SpawnService.tile_available = function (x, y, avoid_entrance)
    return World.is_free(x, y)
       and #World.items_at(x, y) == 0
       and not (avoid_entrance and DungeonService.is_entrance(x, y))
end

-- A random available tile inside `room`, or nil after bounded retries.
-- A tiny or already-full room must never hang generation.
SpawnService.random_tile = function (room, avoid_entrance)
    for _ = 1, MAX_TRIES do
        local x = random(room.x_pos, room:x_pos_end())
        local y = random(room.y_pos, room:y_pos_end())
        if SpawnService.tile_available(x, y, avoid_entrance) then return x, y end
    end
    return nil
end

local function populate_room(room, def)
    if def.items > 0 and #def.item_pool > 0 then
        for _ = 1, def.items do
            local x, y = SpawnService.random_tile(room)
            if not x then break end                       -- room is full; stop
            local item_type = def.item_pool[random(#def.item_pool)]
            World.place_item(Items.Item.new(item_type), x, y)
        end
    end
    if def.mobs > 0 and #def.mob_pool > 0 then
        for _ = 1, def.mobs do
            local x, y = SpawnService.random_tile(room)
            if not x then break end
            local mob_type = def.mob_pool[random(#def.mob_pool)]
            MobService.spawn(mob_type, x, y, room)
        end
    end
    if def.npcs > 0 and #def.npc_pool > 0 then
        for _ = 1, def.npcs do
            local x, y = SpawnService.random_tile(room, true)   -- keep entrances open
            if not x then break end
            local npc_type = def.npc_pool[random(#def.npc_pool)]
            NpcService.spawn(npc_type, x, y, room)
        end
    end
    if def.constructs > 0 and #def.construct_pool > 0 then
        for _ = 1, def.constructs do
            local x, y = SpawnService.random_tile(room, true)   -- keep entrances open
            if not x then break end
            local c_type = def.construct_pool[random(#def.construct_pool)]
            ConstructService.spawn(c_type, x, y, room)
        end
    end
end

-- Populate every room except the spawn room. Call AFTER PlayerController.init
-- (the player's tile is known) and before the first tick is processed.
SpawnService.populate = function ()
    local spawn_room = DungeonService.getSpawnRoom()
    for _, room in ipairs(Dungeon.rooms) do
        if room ~= spawn_room then
            populate_room(room, RoomType.def_of(room))
        end
    end
end

return SpawnService
