local game = require "game"
local command = require "command"

function love.load()
    math.randomseed(os.time())
    love.window.setTitle("Love RL")
    love.window.setMode(1280, 720)
    love.keyboard.setKeyRepeat(true)
    game.init()
end

function love.draw()
    game.render()
end

function love.keypressed(key)
    if command.state == "waiting" then
        game.input.handle_move(key)
        command.state = "running"
    end
    command.process()
end
