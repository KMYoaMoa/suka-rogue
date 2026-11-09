local Game = require "game.Game"
local TurnController = require "game.TurnController"
local InputHandler = require "ui.input.InputHandler"
local GameState = require "game.GameState"

-- Composition root/application adapter. Input mapping and turn rules live in
-- the controller layer; this module only owns the active Game lifecycle.
local GameApplication = {}

function GameApplication.reset()
    GameApplication.game = GameApplication.game or Game.new()
    GameApplication.game:reset()
end

function GameApplication.init(game)
    GameApplication.game = game or GameApplication.game or Game.new()
    GameApplication.game:init()
end

GameApplication.handle_key_press = function (key)
    if not GameApplication.game then return end
    GameApplication.game:activate()
    if GameState.state == "dead" then return end
    TurnController.handle(GameApplication.game, InputHandler.intent(key))
end

return GameApplication
