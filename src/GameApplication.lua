local MessageService = require "services.MessageService"
local PlayerService = require "services.PlayerService"
local CommandService = require "services.CommandService"
local InputHandler = require "controllers.InputHander"
local DungeonGenerate = require "services.DungeonGenerate"
local GameState       = require "models.GameState"

local GameApplication = {}

GameApplication.init = function ()
    DungeonGenerate.create(20, 3)
    PlayerService.init()
    MessageService.clear()
    MessageService.add("Welcome, salvors. You descend into the ruins.", "info")
    GameState.state = "running"
    CommandService.process()                                   -- runs until "waiting"
end

GameApplication.handle_key_press = function(key)
    if GameState.state == "waiting" then
        local dx, dy = InputHandler.handle_move(key)
        PlayerService.move(dx, dy)
        GameState.state = "running"
    end
    CommandService.process()
end

return GameApplication
