-- Public facade for the actors feature module. Lazy loading avoids a load
-- cycle between mob spawning and the still-separate AI service.
local paths = {
    Actor = "modules.actors.Actor",
    Mob = "modules.actors.mob.Mob",
    MobService = "modules.actors.mob.MobService",
    Npc = "modules.actors.npc.Npc",
    NpcService = "modules.actors.npc.NpcService",
    Construct = "modules.actors.construct.Construct",
    ConstructService = "modules.actors.construct.ConstructService",
}

local facade = {}
setmetatable(facade, {
    __index = function (_, key)
        local path = paths[key]
        if not path then return nil end
        local module = require(path)
        rawset(facade, key, module)
        return module
    end,
})

return facade
