local Context          = require "game.Context"
local Player           = require "modules.player.Player"
local Item             = require "models.item.Item"
local MessageService   = require "services.MessageService"
local DungeonService   = require "services.DungeonService"
local World            = require "game.World"
local CommandService   = require "services.CommandService"
local InventoryService = require "services.InventoryService"
local InventoryCommands = InventoryService.commands
local CombatService    = require "services.CombatService"
local GameState        = require "models.GameState"

local Controller = {}
local PlayerCommands = {}

local function invoker()
    local game = Context.current
    assert(game and game.player_invoker, "no active player invoker")
    return game.player_invoker
end

function Controller.reset()
    Player.armor = Player.armor_max
    Player.health = Player.health_max
    Player.magic = Player.magic_max
    Player.inventory = {}
    Player.equipped = { melee = nil, ranged = nil, armor = nil }
    Player.mode = "unarmed"
end

function Controller.init()
    Controller.reset()
    local r = DungeonService.getSpawnRoom()
    Controller.setPosition(
        r.x_pos + math.floor(r.x_size / 2),
        r.y_pos + math.floor(r.y_size / 2)
    )

    local player_invoker = CommandService.new_invoker("Player")
    player_invoker.trigger = function ()
        GameState.state = "waiting"
        player_invoker.reschedule(GameState.ticks + 1)
    end
    player_invoker.reschedule(1)
    Context.current.player_invoker = player_invoker
end

function Controller.get_invoker()
    local game = Context.current
    return game and game.player_invoker
end

function Controller.setPosition(x, y)
    Player.x = x
    Player.y = y
end

function Controller.getPosition()
    return Player.x, Player.y
end

function Controller.move(dx, dy)
    invoker().append_command(PlayerCommands.move(dx, dy))
end

PlayerCommands.move = function (dx, dy)
    return { execute = function ()
        local new_x = Player.x + dx
        local new_y = Player.y + dy
        if World.is_free(new_x, new_y) then
            Player.x, Player.y = new_x, new_y
        else
            local occupant = World.occupant_at(new_x, new_y)
            if occupant then
                MessageService.add(
                    string.format("The %s blocks your way.", occupant.name),
                    "warning")
            end
        end
    end }
end

function Controller.pickup()
    invoker().append_command(InventoryCommands.pickup())
end

function Controller.equip(i)
    local item = Player.inventory[i]
    if not item or not Item.is_equippable(item) then
        MessageService.add("You can't equip that.", "warning")
        return false
    end
    invoker().append_command(InventoryCommands.equip(i))
    return true
end

function Controller.use(i)
    local item = Player.inventory[i]
    if not item or not Item.is_usable(item) then
        MessageService.add("You can't use that.", "warning")
        return false
    end
    invoker().append_command(InventoryCommands.use(i))
    return true
end

function Controller.drop(i)
    if not Player.inventory[i] then
        MessageService.add("There is nothing to drop.", "warning")
        return false
    end
    invoker().append_command(InventoryCommands.drop(i))
    return true
end

function Controller.switch_mode(mode)
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
        Player.mode = "unarmed"
        CombatService.update_targets()
        return false
    end

    invoker().append_command(CombatService.commands.switch_mode(mode))
    return true
end

function Controller.attack()
    CombatService.update_targets()
    if #CombatService.targets == 0 then
        local text = (Player.mode == "ranged")
            and "There is no target in sight."
            or "There is no target in range."
        MessageService.add(text, "info")
        return false
    end
    invoker().append_command(CombatService.commands.attack())
    return true
end

return Controller
