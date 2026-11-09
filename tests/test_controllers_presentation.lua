local t = require "tests.support"
local Game = require "game.Game"
local GameApplication = require "GameApplication"
local InputHandler = require "ui.input.InputHandler"
local TurnController = require "game.TurnController"
local Presentation = require "game.Presentation"
local World = require "game.World"
local Items = require "modules.items"
local Player = require "modules.player.Player"
local GameState = require "game.GameState"

t.test("input handler emits structured intents", function ()
    local move = InputHandler.intent("l")
    t.equal(move.type, "move")
    t.equal(move.dx, 1)
    t.equal(move.dy, 0)

    local use = InputHandler.intent("u")
    t.equal(use.type, "use")

    local select = InputHandler.intent("3")
    t.equal(select.type, "select")
    t.equal(select.slot, 3)
end)

t.test("TurnController handles inventory selection without advancing time", function ()
    local game = Game.new(1501)
    game:init()
    local before = GameState.ticks
    TurnController.handle(game, InputHandler.intent("i"))
    t.equal(GameState.state, "inventory")
    TurnController.handle(game, InputHandler.intent("2"))
    t.equal(GameState.selected_slot, 2)
    t.equal(GameState.ticks, before)
end)

t.test("Presentation is a read-only view facade", function ()
    local game = Game.new(1502)
    game:init()
    World.clear()
    local room = t.make_room(10, 10, 7, 7)
    Player.x, Player.y = 13, 13
    local item = Items.Item.new("coin")
    World.place_item(item, 14, 13)
    local status = Presentation.status()
    t.equal(status.health, Player.health)
    t.equal(Presentation.player_position(), 13)
    t.equal(Presentation.tile(13, 13).type, "floor")
    t.equal(Presentation.occupant_at(13, 13), Player)
    t.equal(Presentation.item_at(14, 13), item)
    t.truthy(Presentation.messages(10))
    t.equal(Presentation.state(), "waiting")
end)
