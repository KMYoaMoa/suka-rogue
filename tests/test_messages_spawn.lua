local t = require "tests.support"
local Game = require "game.Game"
local MessageLog = require "game.MessageLog"
local SpawnService = require "game.SpawnService"
local World = require "game.World"
local Dungeon = require "modules.dungeon.model.Dungeon"
local Cell = require "modules.dungeon.model.Cell"
local Tile = require "modules.dungeon.model.Tile"
local DungeonService = require "modules.dungeon.DungeonService"

t.test("message log is game-owned and resets with the Game", function ()
    local game = Game.new(1301)
    game:init()
    t.truthy(#MessageLog.recent() >= 1)
    MessageLog.add("marker", "info")
    local count = #MessageLog.recent()
    t.truthy(count >= 2)
    game:reset()
    t.equal(#MessageLog.recent(), 0)
end)

t.test("SpawnService populates non-spawn rooms through the actor/item modules", function ()
    local game = Game.new(1302)
    game:init()
    World.clear()

    local spawn = Cell:new(10, 10, 5, 5)
    local other = Cell:new(20, 10, 5, 5)
    Dungeon.rooms = { spawn, other }
    other.room_type = "storeroom"

    for _, room in ipairs({spawn, other}) do
        for x = room.x_pos, room:x_pos_end() do
            for y = room.y_pos, room:y_pos_end() do
                local tile = Tile.new("floor")
                tile.biome = "BiomeA"
                tile.darkness = 1
                DungeonService.setTile(tile, x, y)
            end
        end
    end

    SpawnService.populate()
    t.truthy(#World.current().items > 0)
end)
