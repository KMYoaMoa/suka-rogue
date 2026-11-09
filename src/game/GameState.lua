local Context = require "game.Context"

-- Per-run game state. The module proxies the active Game's state bundle for
-- the Phase 3 compatibility layer.
local GameState = {}

function GameState.new_state()
    return {
        ticks = 0,
        state = "waiting",   -- "waiting" | "running" | "inventory" | "dead"
        selected_slot = nil,
    }
end

local default_state = GameState.new_state()

local function current_state()
    local context = Context.current
    return (context and context.state) or default_state
end

return setmetatable(GameState, {
    __index = function (_, key) return current_state()[key] end,
    __newindex = function (_, key, value) current_state()[key] = value end,
})
