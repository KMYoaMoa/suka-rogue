local Context         = require "game.Context"
local Dungeon         = require "models.dungeon.Dungeon"
local DungeonService  = require "services.DungeonService"
local Player          = require "modules.player.Player"

-- World owns the spatial/run state: the map, actors, and ground items.
-- Occupancy is composed from map passability and live occupant positions.
local World = {}
World.__index = World

function World.new()
    return setmetatable({
        dungeon = Dungeon.new_state(),
        mobs = {},
        npcs = {},
        constructs = {},
        items = {},
    }, World)
end

function World.current()
    local game = Context.current
    assert(game and game.world, "no active World")
    return game.world
end

function World.clear()
    local world = World.current()
    world.mobs = {}
    world.npcs = {}
    world.constructs = {}
    world.items = {}
end

local function scan(list, x, y)
    for _, actor in ipairs(list) do
        if not actor.dead and actor.x == x and actor.y == y then
            return actor
        end
    end
    return nil
end

-- Occupant contract: x, y, name, glyph, color, and optional `dead`.
-- The player, mobs, NPCs, and constructs block; ground items do not.
function World.occupant_at(x, y)
    local world = World.current()
    if Player.x == x and Player.y == y then return Player end
    return scan(world.mobs, x, y)
        or scan(world.npcs, x, y)
        or scan(world.constructs, x, y)
end

function World.is_free(x, y)
    return DungeonService.is_passable(x, y)
       and World.occupant_at(x, y) == nil
end

-- Ground-item queries. Items may share a tile; they never block movement.
function World.place_item(item, x, y)
    local items = World.current().items
    items[#items + 1] = { x = x, y = y, item = item }
end

function World.items_at(x, y)
    local out = {}
    for _, entry in ipairs(World.current().items) do
        if entry.x == x and entry.y == y then out[#out + 1] = entry end
    end
    return out
end

function World.take_items_at(x, y)
    local world = World.current()
    local taken, keep = {}, {}
    for _, entry in ipairs(world.items) do
        if entry.x == x and entry.y == y then
            taken[#taken + 1] = entry
        else
            keep[#keep + 1] = entry
        end
    end
    world.items = keep
    return taken
end

return World
