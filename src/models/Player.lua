local Context = require "game.Context"

-- Per-run player state. The module is a proxy to the active Game's player
-- during Phase 3, so existing services keep their current API while each Game
-- owns an independent copy of the aggregate.
local Player = {}

function Player.new_state()
    return {
        armor = 100,
        armor_max = 100,
        health = 100,
        health_max = 100,
        magic = 100,
        magic_max = 100,

        -- Combat
        attack = 3,              -- base attack used by every mode
        unarmed_range = 1,       -- body range (4-direction BFS steps)
        mode = "unarmed",        -- "unarmed" | "melee" | "ranged"

        inventory = {},
        equipped = { melee = nil, ranged = nil, armor = nil },
    }
end

local default_state = Player.new_state()

local function current_state()
    local context = Context.current
    return (context and context.player) or default_state
end

return setmetatable(Player, {
    __index = function (_, key) return current_state()[key] end,
    __newindex = function (_, key, value) current_state()[key] = value end,
})
