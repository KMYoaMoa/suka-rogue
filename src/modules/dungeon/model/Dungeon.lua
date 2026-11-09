local Context = require "game.Context"

-- Per-run map data. Actor/item collections and occupancy belong to World,
-- not to the Dungeon map model.
local Dungeon = {}

function Dungeon.new_state()
    return {
        rooms = {},
        paths = {},
    }
end

local default_state = Dungeon.new_state()

local function current_state()
    local context = Context.current
    return (context and context.world and context.world.dungeon) or default_state
end

return setmetatable(Dungeon, {
    __index = function (_, key) return current_state()[key] end,
    __newindex = function (_, key, value) current_state()[key] = value end,
})
