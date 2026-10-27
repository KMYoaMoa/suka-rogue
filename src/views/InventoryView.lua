local conf = require "conf"
local GameState = require "models.GameState"
local Player = require "models.Player"
local InventoryView = {}

local SLOTS = {
    { key = "melee",  label = "melee"  },
    { key = "ranged", label = "ranged" },
    { key = "armor",  label = "armor"  },
}

-- Pure helper so the equipment block can be tested without Love.
InventoryView.equipment_lines = function (player)
    local lines = { "EQUIPMENT" }
    for _, slot in ipairs(SLOTS) do
        local item = player.equipped[slot.key]
        lines[#lines + 1] = string.format("%-7s %s",
            slot.label .. ":", item and item.type or "empty")
    end
    return lines
end

InventoryView.render = function ()
    if GameState.state ~= "inventory" then return end

    local x = conf.INV_ORIGIN_X
    local y = conf.INV_ORIGIN_Y
    local step = conf.INV_LINE_HEIGHT

    for _, line in ipairs(InventoryView.equipment_lines(Player)) do
        love.graphics.print(line, x, y)
        y = y + step
    end

    y = y + step                         -- gap between equipment and backpack
    love.graphics.print("BACKPACK", x, y)
    y = y + step

    if #Player.inventory == 0 then
        love.graphics.print("empty", x, y)
        return
    end

    for i, entry in ipairs(Player.inventory) do
        local prefix = (GameState.selected_slot == i and ">" or " ")
        love.graphics.print(string.format("%d. %s%s x%d", i, prefix, entry.type, entry.qty),
                            x, y)
        y = y + step
    end
end

return InventoryView
