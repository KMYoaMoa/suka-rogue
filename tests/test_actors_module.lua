local t = require "tests.support"
local Game = require "game.Game"
local Actors = require "modules.actors"
local World = require "game.World"
local Dungeon = require "modules.dungeon.model.Dungeon"

t.test("actors facade exposes models, services, and the actor contract", function ()
    local game = Game.new(881)
    game:init()
    t.truthy(Actors.Actor)
    t.truthy(Actors.Mob)
    t.truthy(Actors.MobService)
    t.truthy(Actors.Npc)
    t.truthy(Actors.NpcService)
    t.truthy(Actors.Construct)
    t.truthy(Actors.ConstructService)

    World.clear()
    local room = t.make_room(40, 10, 6, 6)
    Dungeon.rooms = { room }

    local mob = Actors.MobService.spawn("scavenger", 41, 11, room)
    t.truthy(mob)
    t.equal(mob.equipped.weapon.type, "Rusty Sword")
    t.equal(mob.equipped.armor.type, "Iron Plate")
    t.truthy(Actors.Actor.at(mob, 41, 11))
    t.equal(#World.current().mobs, 1)

    local npc = Actors.NpcService.spawn("shopkeeper", 42, 11, room)
    t.truthy(npc)
    t.truthy(Actors.NpcService.alive_in_room(room))

    local shelf = Actors.ConstructService.spawn("shelf", 43, 11, room)
    t.truthy(shelf)
    t.truthy(Actors.ConstructService.can_use(shelf))
    t.equal(#World.current().npcs, 1)
    t.equal(#World.current().constructs, 1)
end)
