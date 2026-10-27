local PlayerStatusView = {}
local Player = require "models.Player"
local conf = require "conf"

PlayerStatusView.render = function ()
    local x = conf.STATUS_ORIGIN_X
    local y = conf.STATUS_ORIGIN_Y
    local step = conf.STATUS_LINE_HEIGHT
    love.graphics.print("ARM:" .. Player.armor, x, y)
    love.graphics.print("HP:" .. Player.health, x, y + step)
    love.graphics.print("MP:" .. Player.magic, x, y + step * 2)
end

return PlayerStatusView
