local t = require "tests.support"
local GameApplication = require "GameApplication"
local GameState = require "models.GameState"
local Player = require "models.Player"
local Dungeon = require "models.dungeon.Dungeon"
local DungeonService = require "services.DungeonService"
local MobService = require "services.MobService"
local PlayerService = require "services.PlayerService"
local MessageService = require "services.MessageService"
local Item = require "models.item.Item"
local Game = require "game.Game"

local function init_with_fixed_seed(seed)
    GameApplication.init(Game.new(seed))
end

t.test("init waits without consuming a tick; one movement input consumes one tick", function ()
    init_with_fixed_seed(101)
    t.equal(GameState.state, "waiting")
    t.equal(GameState.ticks, 0)

    t.with_clean_world(function ()
        t.make_room(10, 10, 7, 7)
        Player.x, Player.y = 13, 13
        PlayerService.init()
        PlayerService.setPosition(13, 13)
        require("services.CommandService").reset()
        PlayerService.invoker.reschedule(GameState.ticks + 1)
        local before_x, before_y = Player.x, Player.y
        local before_ticks = GameState.ticks
        PlayerService.move(1, 0)
        PlayerService.invoker.trigger = function ()
            GameState.state = "waiting"
            PlayerService.invoker.reschedule(GameState.ticks + 1)
        end
        PlayerService.invoker.reschedule(GameState.ticks)
        GameState.state = "running"
        require("services.CommandService").process()
        t.equal(GameState.ticks, before_ticks + 1)
        t.equal(GameState.state, "waiting")
        t.equal(Player.x, before_x + 1)
        t.equal(Player.y, before_y)
    end)
end)

t.test("view-only input does not advance time", function ()
    init_with_fixed_seed(102)
    local before = GameState.ticks
    GameApplication.handle_key_press("i")
    t.equal(GameState.state, "inventory")
    t.equal(GameState.ticks, before)
    GameApplication.handle_key_press("i")
    t.equal(GameState.state, "waiting")
    t.equal(GameState.ticks, before)
end)

t.test("failed inventory actions do not consume a turn", function ()
    init_with_fixed_seed(103)
    Player.inventory = { Item.new("coin") }
    GameApplication.handle_key_press("i")
    GameApplication.handle_key_press("1")
    local before = GameState.ticks
    GameApplication.handle_key_press("e")
    t.equal(GameState.ticks, before)
    t.equal(GameState.state, "inventory")
    GameApplication.handle_key_press("u")
    t.equal(GameState.ticks, before)
    t.equal(GameState.state, "inventory")
end)

t.test("reset clears run state, world entities, messages, and scheduled invokers", function ()
    init_with_fixed_seed(104)
    local room = DungeonService.getSpawnRoom()
    local x, y = room.x_pos + 1, room.y_pos + 1
    if not DungeonService.is_free(x, y) then
        x, y = room.x_pos_end() - 1, room.y_pos_end() - 1
    end
    local mob = MobService.spawn("unknown", x, y, room)
    t.truthy(mob)
    MessageService.add("marker", "info")
    GameApplication.reset()
    t.equal(GameState.ticks, 0)
    t.equal(GameState.state, "waiting")
    t.equal(#Dungeon.rooms, 0)
    t.equal(#Dungeon.mobs, 0)
    t.equal(#MessageService.recent(), 0)
    t.equal(require("services.CommandService").next_tick(), nil)
end)

t.test("death stops the scheduler before a later invoker can act", function ()
    t.with_clean_world(function ()
        local CommandService = require "services.CommandService"
        local PlayerStatsService = require "services.PlayerStatsService"
        local first = CommandService.new_invoker("lethal")
        local second = CommandService.new_invoker("must-not-run")
        local second_ran = false
        first.trigger = function ()
            first.append_command({ execute = function () PlayerStatsService.apply_damage(1, "test") end })
            first.reschedule(GameState.ticks + 1)
        end
        second.trigger = function () second_ran = true end
        first.reschedule(0)
        second.reschedule(0)
        Player.health = 1
        Player.armor = 0
        GameState.state = "running"
        CommandService.process()
        t.equal(GameState.state, "dead")
        t.falsy(second_ran)
    end)
end)
