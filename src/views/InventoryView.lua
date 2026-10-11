local conf = require "conf"
local GameState = require "models.GameState"
local Player = require "models.Player"
local InventoryView = {}

InventoryView.render = function ()
    if GameState.state ~= "inventory" then return end
    for i, entry in ipairs(Player.inventory) do
        local prefix = (GameState.selected_slot == i and ">"
                     or Player.equipped.weapon == entry and "*"
                     or " ")
        love.graphics.print(string.format("%d. %s%s x%d", i, prefix, entry.type, entry.qty),
                            conf.INV_ORIGIN_X, conf.INV_ORIGIN_Y + (i - 1) * conf.MESSAGE_LINE_HEIGHT)
    end
end

return InventoryView
