local PlayerStatusView = {}
local Presentation = require "game.Presentation"
local conf = require "conf"

PlayerStatusView.render = function ()
    local x = conf.STATUS_ORIGIN_X
    local y = conf.STATUS_ORIGIN_Y
    local step = conf.STATUS_LINE_HEIGHT
    local status = Presentation.status()
    love.graphics.print("ARM:" .. status.armor, x, y)
    love.graphics.print("HP:" .. status.health, x, y + step)
    love.graphics.print("MP:" .. status.magic, x, y + step * 2)
end

return PlayerStatusView
