local conf = require "conf"
local Player = require "models.Player"
local DungeonService = require "services.DungeonService"
local CommandService = require "services.CommandService"
local CameraService = require "services.CameraService"
local InventoryService = require "services.InventoryService"
local InventoryCommands = InventoryService.commands
local GameState = require "models.GameState"

local PlayerService = {}
local PlayerCommands = {}

PlayerService.init = function ()
    local r = DungeonService.getSpawnRoom()
    PlayerService.setPosition(
        r.x_pos + math.floor(r.x_size / 2),
        r.y_pos + math.floor(r.y_size / 2)
    )
    PlayerService.invoker = CommandService.new_invoker("Player")
    PlayerService.invoker.trigger = function ()
        GameState.state = "waiting"
        PlayerService.invoker.reschedule(GameState.ticks + 1)
    end
    PlayerService.invoker.reschedule(1)
   	CameraService.update(Player.x, Player.y)                     -- center on the player (per frame)
end

-- Set position of player directly
--  x, y: absolute position
PlayerService.setPosition = function (x, y)
    Player.x = x
    Player.y = y
end

PlayerService.getPosition = function ()
    return Player.x, Player.y
end

-- Move player by change of position
--  dx, dy: change of position

PlayerService.move = function (dx, dy)
    PlayerService.invoker.append_command(PlayerCommands.move(dx, dy))
end

PlayerCommands.move = function (dx, dy)
    return { execute = function ()
            local new_x = Player.x + dx
           	local new_y = Player.y + dy
            local valid_move = conf.is_pos_valid(new_x, new_y) and DungeonService.is_passable(new_x, new_y)
        	if valid_move then
        		Player.x = new_x
        		Player.y = new_y
        	end
        	CameraService.update(Player.x, Player.y)
        end
    }
end

PlayerService.pickup  = function () PlayerService.invoker.append_command(InventoryCommands.pickup()) end
PlayerService.equip   = function (i) PlayerService.invoker.append_command(InventoryCommands.equip(i)) end
PlayerService.use     = function (i) PlayerService.invoker.append_command(InventoryCommands.use(i)) end
PlayerService.drop    = function (i) PlayerService.invoker.append_command(InventoryCommands.drop(i)) end

-- Return the player object
return PlayerService
