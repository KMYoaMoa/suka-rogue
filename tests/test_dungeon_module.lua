local t = require "tests.support"
local Game = require "game.Game"
local DungeonModule = require "modules.dungeon"

t.test("dungeon facade exposes map data, queries, generation, and content", function ()
    local game = Game.new(1401)
    game:init()

    t.truthy(DungeonModule.Dungeon)
    t.truthy(DungeonModule.Tile)
    t.truthy(DungeonModule.Service)
    t.truthy(DungeonModule.Generator)
    t.truthy(DungeonModule.Palette)
    t.truthy(DungeonModule.RoomType)

    local floor = DungeonModule.Tile.new("floor")
    t.truthy(DungeonModule.Tile.passable(floor))
    t.falsy(DungeonModule.Tile.opaque(floor))
    t.truthy(DungeonModule.Palette.color_for("BiomeA", "floor"))
    t.truthy(DungeonModule.RoomType.def_of({ room_type = "shop" }).npcs)

    t.truthy(DungeonModule.Service.getSpawnRoom())
    t.truthy(DungeonModule.Service.is_passable(13, 13))
end)
