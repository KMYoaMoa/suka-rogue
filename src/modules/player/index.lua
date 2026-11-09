-- Public facade for the player feature module. Module entries are loaded
-- lazily so importing the facade does not pull the controller/combat cycle
-- into every player-model consumer.
local paths = {
    Player = "modules.player.Player",
    Inventory = "modules.player.Inventory",
    Stats = "modules.player.Stats",
    Controller = "modules.player.PlayerController",
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
