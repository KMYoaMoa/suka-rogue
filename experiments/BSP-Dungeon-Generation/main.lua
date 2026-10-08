local MapFactory = require "MapFactory"

local map = nil

function love.load()
    love.window.setMode(1280, 720)
    map = MapFactory.create(60, 30, 3, 15)
end

function love.draw()
    map:display()
end
