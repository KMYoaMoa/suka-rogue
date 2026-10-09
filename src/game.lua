local conf = require "conf"
local dungeon = require "dungeon"
local player = require "player"
local camera = require "camera"

local game = {}

game.init = function ()
    dungeon.init()
    player.init()
   	camera.update(player.x, player.y)                     -- center on the player (per frame)
end

game.render = function ()
    for sx = 0, camera.width - 1, 1 do
        for sy = 0, camera.height - 1, 1 do
            local transform = love.math.newTransform(sx * conf.TILE_SIZE, sy * conf.TILE_SIZE, 0, 2, 2, 0, 0)
            if camera.world_x(sx) == player.x and camera.world_y(sy) == player.y then
                love.graphics.print("@", transform)
            else
                love.graphics.print(camera.tile_at(sx, sy, dungeon), transform)
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
	if dx ~= 0 or dy ~= 0 then
    	player.move(dx, dy)
    	camera.update(player.x, player.y)                     -- center on the player (per frame)
	end
end

return game
