-- Compatibility path: player-local actions now live in the player module.
local Context = require "game.Context"
local Controller = require "modules.player.PlayerController"

local PlayerService = {}
for key, value in pairs(Controller) do PlayerService[key] = value end

return setmetatable(PlayerService, {
    __index = function (_, key)
        if key == "invoker" then
            local game = Context.current
            return game and game.player_invoker
        end
        return Controller[key]
    end,
})
