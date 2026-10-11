local dungeon = require "dungeon"
local Command = require "command"
local camera = require "camera"

-- Player object
local player = {}

-- Get global config from main
local conf = require "conf"

-- Initialize player object
--  config: global configuration project
player.init = function ()
    local r = dungeon.rooms[1]
    player.setPosition(
        r.x_pos + math.floor(r.x_size / 2),
        r.y_pos + math.floor(r.y_size / 2)
    )
    player.armor = 100
    player.armor_max = 100
    player.health = 100
    player.health_max = 100
    player.magic = 100
    player.magic_max = 100
    player.invoker = Command.new_invoker("Player")
    player.invoker.trigger = function ()
        Command.state = "waiting"
        player.invoker.reschedule(Command.ticks + 1)
    end
    player.invoker.reschedule(1)
end

-- Set position of player directly
--  x, y: absolute position
player.setPosition = function (x, y)
    player.x = x
    player.y = y
end

-- Move player by change of position
--  dx, dy: change of position
player.move = function (dx, dy)
    player.invoker.append_command({
        execute = function ()
            local new_x = player.x + dx
           	local new_y = player.y + dy
            local valid_move = conf.is_pos_valid(new_x, new_y) and dungeon.is_passable(new_x, new_y)
        	if valid_move then
        		player.x = new_x
        		player.y = new_y
        	end
        	camera.update(player.x, player.y)
        end
    })
end

-- Return the player object
return player
