local PlayerStatusView = {}
local Player = require "models.Player"

PlayerStatusView.render = function ()
    love.graphics.print("ARM:" .. Player.armor, 0, 340)
	love.graphics.print("HP:" .. Player.health, 0, 360)
    love.graphics.print("MP:" .. Player.magic, 0, 380)
end

return PlayerStatusView
