local t = require "tests.support"
local World = require "game.World"
local GameApplication = require "GameApplication"
local Player = require "modules.player.Player"
local Dungeon = require "modules.dungeon.model.Dungeon"
local DungeonService = require "modules.dungeon.DungeonService"
local MobService = require "modules.actors.mob.MobService"
local NpcService = require "modules.actors.npc.NpcService"
local ConstructService = require "modules.actors.construct.ConstructService"
local DungeonGenerate = require "modules.dungeon.generation.DungeonGenerate"
local RNG = require "core.rng"
local conf = require "conf"

t.test("player and blocking actors cannot share a passable tile", function ()
    t.with_clean_world(function ()
        local room = t.make_room(10, 10, 7, 7)
        Player.x, Player.y = 13, 13
        t.falsy(World.is_free(Player.x, Player.y))
        t.truthy(World.occupant_at(Player.x, Player.y) == Player)
        t.falsy(MobService.spawn("rat", Player.x, Player.y, room))
        t.falsy(NpcService.spawn("shopkeeper", Player.x, Player.y, room))
        t.falsy(ConstructService.spawn("chest", Player.x, Player.y, room))

        local mob = MobService.spawn("rat", 11, 11, room)
        t.truthy(mob)
        t.falsy(World.is_free(mob.x, mob.y))
    end)
end)

t.test("out-of-bounds terrain is not passable and floor never touches map edge", function ()
    t.equal(DungeonService.is_passable(-1, 0), false)
    t.equal(DungeonService.is_passable(conf.SIZE_X, 0), false)
    for seed = 201, 240 do
        local map = DungeonGenerate.create(20, 3, RNG.new(seed))
        t.truthy(#map.cell_list > 0)
        t.truthy(DungeonService.getSpawnRoom())
        for x = 0, conf.SIZE_X - 1 do
            t.falsy(DungeonService.getTile(x, 0).type == "floor")
            t.falsy(DungeonService.getTile(x, conf.SIZE_Y - 1).type == "floor")
        end
        for y = 0, conf.SIZE_Y - 1 do
            t.falsy(DungeonService.getTile(0, y).type == "floor")
            t.falsy(DungeonService.getTile(conf.SIZE_X - 1, y).type == "floor")
        end
        for _, room in ipairs(map.cell_list) do
            t.truthy(room.x_pos >= 1 and room:x_pos_end() <= conf.SIZE_X - 2)
            t.truthy(room.y_pos >= 1 and room:y_pos_end() <= conf.SIZE_Y - 2)
        end
    end
end)

t.test("vision updates visible/discovered states while pure mob FOV leaves player state untouched", function ()
    t.with_clean_world(function ()
        local VisionService = require "modules.vision"
        local Tile = require "modules.dungeon.model.Tile"
        t.make_room(10, 10, 7, 7)
        Player.x, Player.y = 13, 13
        local before_visible = DungeonService.getTile(13, 13).visible
        local local_fov = VisionService.compute_visible(11, 11, 3)
        t.truthy(next(local_fov) ~= nil)
        t.equal(DungeonService.getTile(13, 13).visible, before_visible)
        VisionService.update()
        local player_tile = DungeonService.getTile(13, 13)
        t.truthy(player_tile.visible)
        t.truthy(player_tile.discovered)

        local undiscovered = Tile.new("floor")
        t.equal(VisionService.state_of(undiscovered), "undiscovered")
        undiscovered.discovered = true
        t.equal(VisionService.state_of(undiscovered), "discovered")
    end)
end)
