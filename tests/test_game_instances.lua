local t = require "tests.support"
local World = require "game.World"
local Game = require "game.Game"
local Player = require "modules.player.Player"
local Dungeon = require "modules.dungeon.model.Dungeon"
local GameState = require "game.GameState"
local MessageService = require "services.MessageService"
local PlayerController = require "modules.player.PlayerController"
local DungeonService = require "modules.dungeon.DungeonService"
local conf = require "conf"

t.test("two Game instances keep player, world, tick, scheduler, and message state separate", function ()
    local a = Game.new()
    a:activate()
    a:init()
    local a_invoker = PlayerController.get_invoker()
    Player.health = 37
    GameState.ticks = 7
    World.current().mobs[#World.current().mobs + 1] = { name = "A-SENTINEL", dead = false, x = -1, y = -1 }
    MessageService.add("A only", "info")

    local b = Game.new()
    b:activate()
    b:init()
    local b_invoker = PlayerController.get_invoker()
    t.falsy(a.world == b.world)
    t.falsy(a.world.dungeon == b.world.dungeon)
    t.equal(Player.health, 100)
    t.equal(GameState.ticks, 0)
    t.equal(#MessageService.recent(), 1) -- welcome only
    t.falsy(PlayerController.get_invoker() == a_invoker)
    t.truthy(PlayerController.get_invoker() == b_invoker)
    for _, mob in ipairs(World.current().mobs) do
        t.falsy(mob.name == "A-SENTINEL")
    end

    Player.health = 88
    GameState.ticks = 3
    MessageService.add("B only", "info")

    a:activate()
    t.equal(Player.health, 37)
    t.equal(GameState.ticks, 7)
    t.truthy(PlayerController.get_invoker() == a_invoker)
    local has_a = false
    for _, entry in ipairs(MessageService.recent()) do
        if entry.text == "A only" then has_a = true end
        t.falsy(entry.text == "B only")
    end
    t.truthy(has_a)
    local has_sentinel = false
    for _, mob in ipairs(World.current().mobs) do
        if mob.name == "A-SENTINEL" then has_sentinel = true end
    end
    t.truthy(has_sentinel)

    b:activate()
    t.equal(Player.health, 88)
    t.equal(GameState.ticks, 3)
    t.truthy(PlayerController.get_invoker() == b_invoker)
end)

t.test("re-initializing one Game clears its previous run without touching another Game", function ()
    local a = Game.new()
    a:activate()
    a:init()
    Player.health = 12
    World.current().mobs[#World.current().mobs + 1] = { name = "OLD-A", dead = false, x = -1, y = -1 }
    MessageService.add("old A", "info")

    local b = Game.new()
    b:activate()
    b:init()
    Player.health = 73
    MessageService.add("B survives", "info")

    a:init() -- activates A and resets only A
    t.equal(Player.health, 100)
    t.equal(GameState.ticks, 0)
    for _, mob in ipairs(World.current().mobs) do
        t.falsy(mob.name == "OLD-A")
    end
    t.falsy(#MessageService.recent() > 1)

    b:activate()
    t.equal(Player.health, 73)
    local has_b = false
    for _, entry in ipairs(MessageService.recent()) do
        if entry.text == "B survives" then has_b = true end
        t.falsy(entry.text == "old A")
    end
    t.truthy(has_b)
end)

t.test("scheduler queries follow the active Game", function ()
    local a = Game.new()
    a:activate()
    a:init()
    local a_next = a.scheduler:next_tick()
    t.equal(a_next, 1)

    local b = Game.new()
    b:activate()
    b:init()
    t.equal(b.scheduler:next_tick(), 1)

    a:activate()
    t.equal(a.scheduler:next_tick(), 1)
end)

t.test("the same Game seed produces the same generated world", function ()
    local function snapshot(seed)
        local game = Game.new(seed)
        game:init()
        local floors = 0
        for x = 0, conf.SIZE_X - 1 do
            for y = 0, conf.SIZE_Y - 1 do
                if DungeonService.getTile(x, y).type == "floor" then floors = floors + 1 end
            end
        end
        return #game.world.dungeon.rooms, #game.world.dungeon.paths, floors
    end
    local ar, ap, af = snapshot(777)
    local br, bp, bf = snapshot(777)
    t.equal(ar, br)
    t.equal(ap, bp)
    t.equal(af, bf)
end)

t.test("Dungeon stores only map data; World owns actors and ground items", function ()
    local game = Game.new(310)
    game:init()
    t.equal(Dungeon.mobs, nil)
    t.equal(Dungeon.items, nil)
    t.equal(Dungeon.npcs, nil)
    t.equal(Dungeon.constructs, nil)
    t.truthy(game.world.mobs)
    t.truthy(game.world.items)
    t.truthy(game.world.dungeon.rooms)
end)
