local Dungeon = require "models.dungeon.Dungeon"

-- World owns spatial/run state. During Phase 3 it still wraps the legacy
-- combined Dungeon state (map + actor/item collections); Phase 6 will split
-- those collections out of Dungeon into the world.
local World = {}
World.__index = World

function World.new()
    return setmetatable({
        dungeon = Dungeon.new_state(),
    }, World)
end

return World
