local PlayerService = require "services.PlayerService"
local CommandService = require "services.CommandService"
local InputHandler = require "controllers.InputHandler"
local VisionService = require "services.VisionService"
local CombatService = require "services.CombatService"
local GameState       = require "models.GameState"
local Game            = require "game.Game"

local GameApplication = {}

-- Settle one turn, then refresh what the player can see and target.
local function run_turn()
    GameState.state = "running"
    CommandService.process()                                   -- runs until "waiting"
    if GameState.state ~= "dead" then
        VisionService.update()
        CombatService.update_targets()
    end
end

function GameApplication.reset()
    GameApplication.game = GameApplication.game or Game.new()
    GameApplication.game:reset()
end

function GameApplication.init(game)
    GameApplication.game = game or GameApplication.game or Game.new()
    GameApplication.game:init()
end

GameApplication.handle_key_press = function (key)
    if not GameApplication.game then return end
    GameApplication.game:activate()
    if GameState.state == "dead" then return end
    local action = InputHandler.handle_action(key)

    if GameState.state == "waiting" then
        -- open the list (view-only: no tick spent)
        if action == "inventory_toggle" then
            GameState.state = "inventory"
            GameState.selected_slot = nil
            return
        end

        -- combat mode switching / attack
        if action == "melee_mode" then
            if PlayerService.switch_mode("melee") then run_turn() end
            return
        elseif action == "ranged_mode" then
            if PlayerService.switch_mode("ranged") then run_turn() end
            return
        elseif action == "unarmed_mode" then
            PlayerService.switch_mode("unarmed")            -- no tick
            return
        elseif action == "attack" then
            if PlayerService.attack() then run_turn() end    -- no target -> no tick
            return
        end

        -- inventory closed: pickup, else movement
        if action == "pickup" then
            PlayerService.pickup()
        else
            local dx, dy = InputHandler.handle_move(key)
            if dx == 0 and dy == 0 then return end
            PlayerService.move(dx, dy)
        end
        run_turn()
        return
    end

    if GameState.state == "inventory" then
        -- view-only: close the list / select a slot (no tick spent)
        if action == "inventory_toggle" then
            GameState.state = "waiting"
            GameState.selected_slot = nil
            return
        elseif action and action:match("^select") then
            GameState.selected_slot = tonumber(action:sub(7))
            return
        end

        -- e/u/d act on the selected slot; other keys ignored
        local acted = false
        if action == "equip" and GameState.selected_slot then
            acted = PlayerService.equip(GameState.selected_slot)
        elseif action == "use" and GameState.selected_slot then
            acted = PlayerService.use(GameState.selected_slot)
        elseif action == "drop" and GameState.selected_slot then
            acted = PlayerService.drop(GameState.selected_slot)
        else
            return     -- movement etc. does nothing while the list is open
        end
        if acted then run_turn() end
        return
    end
end

return GameApplication
