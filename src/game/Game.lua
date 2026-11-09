local Context           = require "game.Context"
local World             = require "game.World"
local Player            = require "models.Player"
local GameState         = require "models.GameState"
local CommandService    = require "services.CommandService"
local MessageService    = require "services.MessageService"
local CombatService     = require "services.CombatService"
local PlayerService     = require "services.PlayerService"
local DungeonService    = require "services.DungeonService"
local DungeonGenerate   = require "services.DungeonGenerate"
local RoomService       = require "services.RoomService"
local VisionService     = require "services.VisionService"

-- Game owns one run's state bundles. During Phase 3, legacy services still
-- read the active bundle through module proxies; activation is the temporary
-- compatibility boundary that later phases will replace with injection.
local Game = {}
Game.__index = Game

function Game.new()
    local world = World.new()
    return setmetatable({
        world           = world,
        dungeon         = world.dungeon, -- temporary proxy target for legacy services
        player          = Player.new_state(),
        state           = GameState.new_state(),
        scheduler       = CommandService.new_state(),
        messages        = MessageService.new_state(),
        combat          = CombatService.new_state(),
        player_invoker  = nil,
    }, Game)
end

function Game:activate()
    Context.current = self
    CommandService.activate(self.scheduler)
    MessageService.activate(self.messages)
    CombatService.activate(self.combat)
    PlayerService.invoker = self.player_invoker
end

function Game:reset()
    self:activate()
    CommandService.reset()
    DungeonService.clear()
    PlayerService.reset()

    self.state.ticks = 0
    self.state.state = "waiting"
    self.state.selected_slot = nil
    self.player_invoker = nil
    PlayerService.invoker = nil

    MessageService.clear()
end

function Game:init()
    self:reset()
    DungeonGenerate.create(20, 3)
    PlayerService.init()
    self.player_invoker = PlayerService.invoker

    RoomService.populate()
    MessageService.add("Welcome, salvors. You descend into the ruins.", "info")
    VisionService.update()
    CombatService.update_targets()
end

return Game
