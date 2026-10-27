local Player = require "models.Player"
local Item = require "models.item.Item"
local MessageService = require "services.MessageService"
local DungeonService = require "services.DungeonService"
local CommandService = require "services.CommandService"
local InventoryService = require "services.InventoryService"
local InventoryCommands = InventoryService.commands
local CombatService = require "services.CombatService"
local GameState = require "models.GameState"

local PlayerService = {}
local PlayerCommands = {}

PlayerService.reset = function ()
    Player.armor = Player.armor_max
    Player.health = Player.health_max
    Player.magic = Player.magic_max
    Player.inventory = {}
    Player.equipped = { melee = nil, ranged = nil, armor = nil }
    Player.mode = "unarmed"
end

PlayerService.init = function ()
    PlayerService.reset()
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
    end }
end

-- Inventory actions validate before enqueueing so a failed action does not
-- advance the tick. The commands retain their own guards as a fallback.
PlayerService.pickup = function ()
    PlayerService.invoker.append_command(InventoryCommands.pickup())
end

PlayerService.equip = function (i)
    local item = Player.inventory[i]
    if not item or not Item.is_equippable(item) then
        MessageService.add("You can't equip that.", "warning")
        return false
    end
    PlayerService.invoker.append_command(InventoryCommands.equip(i))
    return true
end

PlayerService.use = function (i)
    local item = Player.inventory[i]
    if not item or not Item.is_usable(item) then
        MessageService.add("You can't use that.", "warning")
        return false
    end
    PlayerService.invoker.append_command(InventoryCommands.use(i))
    return true
end

PlayerService.drop = function (i)
    if not Player.inventory[i] then
        MessageService.add("There is nothing to drop.", "warning")
        return false
    end
    PlayerService.invoker.append_command(InventoryCommands.drop(i))
    return true
end

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
