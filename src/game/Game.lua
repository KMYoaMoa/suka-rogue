local Context           = require "game.Context"
local World             = require "game.World"
local Scheduler         = require "core.scheduler"
local RNG               = require "core.rng"
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

function Game.new(seed)
    local world = World.new()
    local state = GameState.new_state()
    local clock = {
        get_tick = function () return state.ticks end,
        set_tick = function (_, tick) state.ticks = tick end,
        is_stopped = function ()
            return state.state == "waiting" or state.state == "dead"
        end,
        is_dead = function () return state.state == "dead" end,
    }
    local run_seed = seed or os.time()
    return setmetatable({
        seed            = run_seed,
        rng             = RNG.new(run_seed),
        world           = world,
        dungeon         = world.dungeon, -- temporary proxy target for legacy services
        player          = Player.new_state(),
        state           = state,
        scheduler       = Scheduler.new(clock),
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
    self.scheduler:clear()
    self.rng = RNG.new(self.seed)
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
    DungeonGenerate.create(20, 3, self.rng)
    PlayerService.init()
    self.player_invoker = PlayerService.invoker

    RoomService.populate()
    MessageService.add("Welcome, salvors. You descend into the ruins.", "info")
    VisionService.update()
    CombatService.update_targets()
end

return Game
