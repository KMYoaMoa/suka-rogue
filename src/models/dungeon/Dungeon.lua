local Context = require "game.Context"

-- Per-run dungeon/world storage. The module proxies the active Game's
-- dungeon bundle so current services can keep using Dungeon[x][y] and the
-- collection fields while separate Games keep separate state.
local Dungeon = {}

function Dungeon.new_state()
    return {
        rooms = {},
        paths = {},
        items = {},
        mobs = {},
        npcs = {},
        constructs = {},
    }
end

local default_state = Dungeon.new_state()

local function current_state()
    local context = Context.current
    return (context and context.dungeon) or default_state
end

return setmetatable(Dungeon, {
    __index = function (_, key) return current_state()[key] end,
    __newindex = function (_, key, value) current_state()[key] = value end,
})
