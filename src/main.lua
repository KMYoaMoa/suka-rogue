local game = require "game"

function love.load()
    love.window.setTitle("Love RL")
    love.window.setMode(1280, 720)
    love.keyboard.setKeyRepeat(true)
    game.init()
end

function love.draw()
    game.render()
end

function love.keypressed(key)
    game.input.handle_move(key)
end
