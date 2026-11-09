local t = require "tests.support"
local Game = require "game.Game"
local AI = require "modules.ai"
local Vision = require "modules.vision"
local DungeonService = require "services.DungeonService"
local Player = require "modules.player.Player"

t.test("AI and vision facades expose their systems and vision updates the map", function ()
    local game = Game.new(1201)
    game:init()
    local room = t.make_room(10, 10, 7, 7)
    Player.x, Player.y = 13, 13

    t.truthy(AI.act)
    t.truthy(Vision.update)
    Vision.update()
    local tile = DungeonService.getTile(13, 13)
    t.truthy(tile.visible)
    t.truthy(tile.discovered)

    local fov = Vision.compute_visible(11, 11, 3)
    t.truthy(next(fov) ~= nil)
    t.equal(Vision.state_of(tile), "visible")
end)
