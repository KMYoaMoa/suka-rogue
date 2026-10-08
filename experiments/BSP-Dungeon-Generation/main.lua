local Cell = require "Cell"
local Map = require "Map"

local map = nil

function love.load()
    love.window.setMode(1280, 720)
    map = Map:new(Cell:new(1, 1, 60, 30), 15, 3)
    map:divide()
    map:construct_list()
    map:find_neighbours()
    map:shrink()
    map:add_path()
end

function love.draw()
    map:display()
end
