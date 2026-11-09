local PlayerController = require "modules.player.PlayerController"
local CommandService   = require "services.CommandService"
local VisionService    = require "modules.vision"
local CombatService    = require "modules.combat"
local GameState        = require "models.GameState"

-- Coordinates one accepted intent into a turn, then refreshes read state.
local TurnController = {}

local function run_turn()
    GameState.state = "running"
    CommandService.process()
    if GameState.state ~= "dead" then
        VisionService.update()
        CombatService.update_targets()
    end
end

local function handle_waiting(intent)
    if intent.type == "inventory_toggle" then
        GameState.state = "inventory"
        GameState.selected_slot = nil
        return
    end

    if intent.type == "melee_mode" then
        if PlayerController.switch_mode("melee") then run_turn() end
        return
    elseif intent.type == "ranged_mode" then
        if PlayerController.switch_mode("ranged") then run_turn() end
        return
    elseif intent.type == "unarmed_mode" then
        PlayerController.switch_mode("unarmed")
        return
    elseif intent.type == "attack" then
        if PlayerController.attack() then run_turn() end
        return
    end

    if intent.type == "pickup" then
        PlayerController.pickup()
    elseif intent.type == "move" then
        PlayerController.move(intent.dx, intent.dy)
    else
        return
    end
    run_turn()
end

local function handle_inventory(intent)
    if intent.type == "inventory_toggle" then
        GameState.state = "waiting"
        GameState.selected_slot = nil
        return
    elseif intent.type == "select" then
        GameState.selected_slot = intent.slot
        return
    end

    local acted = false
    if intent.type == "equip" and GameState.selected_slot then
        acted = PlayerController.equip(GameState.selected_slot)
    elseif intent.type == "use" and GameState.selected_slot then
        acted = PlayerController.use(GameState.selected_slot)
    elseif intent.type == "drop" and GameState.selected_slot then
        acted = PlayerController.drop(GameState.selected_slot)
    else
        return
    end
    if acted then run_turn() end
end

function TurnController.handle(game, intent)
    if not game or not intent then return end
    game:activate()
    if GameState.state == "dead" then return end

    if GameState.state == "waiting" then
        handle_waiting(intent)
    elseif GameState.state == "inventory" then
        handle_inventory(intent)
    end
end

return TurnController
