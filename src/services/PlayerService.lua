local conf = require "conf"
local Player = require "models.Player"
local MessageService = require "services.MessageService"
local DungeonService = require "services.DungeonService"
local CommandService = require "services.CommandService"
local CameraService = require "services.CameraService"
local InventoryService = require "services.InventoryService"
local InventoryCommands = InventoryService.commands
local CombatService = require "services.CombatService"
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
        if DungeonService.is_free(new_x, new_y) then
            Player.x, Player.y = new_x, new_y
        else
            local occupant = DungeonService.occupant_at(new_x, new_y)
            if occupant then
                MessageService.add(
                    string.format("The %s blocks your way.", occupant.name),
                    "warning")
            end
        end
        CameraService.update(Player.x, Player.y)
    end }
end

PlayerService.pickup  = function () PlayerService.invoker.append_command(InventoryCommands.pickup()) end
PlayerService.equip   = function (i) PlayerService.invoker.append_command(InventoryCommands.equip(i)) end
PlayerService.use     = function (i) PlayerService.invoker.append_command(InventoryCommands.use(i)) end
PlayerService.drop    = function (i) PlayerService.invoker.append_command(InventoryCommands.drop(i)) end

-- Switch combat mode. Returns true if a tick-consuming command was enqueued.
PlayerService.switch_mode = function (mode)
    if mode ~= "unarmed" then
        local slot = (mode == "melee") and "melee"
                  or (mode == "ranged") and "ranged"
        if not (slot and Player.equipped[slot]) then
            MessageService.add(string.format("You have no %s weapon.", mode), "warning")
            return false
        end
    end
    if Player.mode == mode then return false end

    if mode == "unarmed" then
        Player.mode = "unarmed"                       -- no tick
        CombatService.update_targets()                -- refresh highlight immediately
        return false
    end

    PlayerService.invoker.append_command(CombatService.commands.switch_mode(mode))
    return true
end

-- Attack with the current mode. Returns true if a tick-consuming attack was enqueued.
PlayerService.attack = function ()
    CombatService.update_targets()                    -- ensure freshness
    if #CombatService.targets == 0 then
        local text = (Player.mode == "ranged")
            and "There is no target in sight."
            or "There is no target in range."
        MessageService.add(text, "info")
        return false                                  -- no tick
    end
    PlayerService.invoker.append_command(CombatService.commands.attack())
    return true
end

-- Return the player object
return PlayerService
