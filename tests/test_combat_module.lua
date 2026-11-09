local t = require "tests.support"
local Game = require "game.Game"
local Combat = require "modules.combat"
local World = require "game.World"
local Player = require "modules.player.Player"

t.test("combat facade resolves visible targets and applies attacks/death/drops", function ()
    local game = Game.new(991)
    game:init()
    World.clear()
    local room = t.make_room(10, 10, 7, 7)
    Player.x, Player.y = 13, 13
    Player.mode = "unarmed"

    local mob = require "modules.actors".MobService.spawn("scavenger", 14, 13, room)
    t.truthy(mob)
    mob.health = 1
    require "services.DungeonService".getTile(14, 13).visible = true
    Combat.update_targets()
    t.truthy(Combat.is_target(14, 13))
    t.equal(#Combat.targets, 1)

    Combat.commands.attack().execute()
    t.equal(#World.current().mobs, 0)
    t.equal(#World.current().items, 2)
end)
