local conf = require "conf"
local dungeon = require "dungeon"
local player = require "player"

local game = {}

game.init = function ()
    dungeon.init()
    player.init()
end

game.camera = {}
game.camera.x = 0
game.camera.y = 0

game.render = function ()
    for x = 0, conf.SIZE_X - 1, 1 do
		for y = 0, conf.SIZE_Y - 1, 1 do
		    local transform = love.math.newTransform(x * conf.TILE_SIZE, y * conf.TILE_SIZE, 0, 2, 2, 0, 0)
            if x == player.x and y == player.y then
                love.graphics.print("@", transform)
            else
                love.graphics.print(dungeon[x][y], transform)
            end
		end
	end
	love.graphics.print("ARM:" .. player.armor, 0, 340)
	love.graphics.print("HP:" .. player.health, 0, 360)
	love.graphics.print("MP:" .. player.magic, 0, 380)
end

game.input = {}
game.input.handle_move = function (key)
    local dx = 0
	local dy = 0
	if key == "down" or key == "j" then dy = 1
	elseif key == "up" or key == "k" then dy = -1
	elseif key == "left" or key == "h" then dx = -1
	elseif key == "right" or key == "l" then dx = 1
	elseif key == "y" then dx = -1; dy = -1
	elseif key == "u" then dx = 1; dy = -1
	elseif key == "b" then dx = -1; dy = 1
	elseif key == "n" then dx = 1; dy = 1
	end
	player.move(dx, dy)
end

return game
