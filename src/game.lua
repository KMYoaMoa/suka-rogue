local Message = require "message"
local dungeon = require "dungeon"
local player = require "player"
local camera = require "camera"
local Command = require "command"
local input = require "input"
local ui = require "ui"

local game = {}

game.init = function ()
    dungeon.init()
    player.init()
   	camera.update(player.x, player.y)                     -- center on the player (per frame)
    Message.clear()
    Message.add("Welcome, salvors. You descend into the ruins.", "info")
    Command.state = "running"
    Command.process()                                   -- runs until "waiting"
end

game.render = function ()
    camera.render(dungeon, player)
    ui.render(player)
end

game.handle_key_press = function(key)
    if Command.state == "waiting" then
        local dx, dy = input.handle_move(key)
        player.move(dx, dy)
        Command.state = "running"
    end
    Command.process()
end

return game
