local conf = require "conf"
local GameState = require "models.GameState"
local Player = require "models.Player"
local InventoryView = {}

local function is_equipped(entry)
    for _, item in pairs(Player.equipped) do
        if item == entry then return true end
    end
    return false
end

InventoryView.render = function ()
    if GameState.state ~= "inventory" then return end
    for i, entry in ipairs(Player.inventory) do
        local prefix = (GameState.selected_slot == i and ">"
                     or is_equipped(entry) and "*"
                     or " ")
        love.graphics.print(string.format("%d. %s%s x%d", i, prefix, entry.type, entry.qty),
                            conf.INV_ORIGIN_X, conf.INV_ORIGIN_Y + (i - 1) * conf.MESSAGE_LINE_HEIGHT)
    end
end

return InventoryView
