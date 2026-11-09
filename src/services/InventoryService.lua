
local Item = require "models.item.Item"
local Player = require "models.Player"
local World = require "game.World"
local MessageService = require "services.MessageService"
local PlayerInventory = require "modules.player.Inventory"

local InventoryService = {}
local InventoryCommands = {}

-- Player-owned inventory operations now live in the player module. These
-- remain as compatibility delegation for existing callers.
InventoryService.add_item = function (item)
    return PlayerInventory.add_item(item)
end

InventoryService.remove_item = function (index)
    return PlayerInventory.remove_item(index)
end

-- Ground items are owned by World.
-- Accepts a type name (creates a fresh instance) or a ready item instance
-- (e.g. the dropped one) so the same entry keeps its identity and qty.
InventoryService.place_item = function (type_name_or_item, x, y)
    local item = type(type_name_or_item) == "string"
        and Item.new(type_name_or_item)
        or type_name_or_item
    local items = World.current().items
    items[#items + 1] = { x = x, y = y, item = item }
end

InventoryService.items_at = function (x, y)
    local out = {}
    for _, g in ipairs(World.current().items) do
        if g.x == x and g.y == y then out[#out + 1] = g end
    end
    return out
end

-- --- commands (appended to the player invoker; one tick each) ---
InventoryCommands.pickup = function ()
    return { execute = function ()
        local grounded = InventoryService.items_at(Player.x, Player.y)
        if #grounded == 0 then
            MessageService.add("There is nothing here.", "info")
            return
        end
        local keep = {}
        for _, g in ipairs(World.current().items) do
            if g.x ~= Player.x or g.y ~= Player.y then
                keep[#keep + 1] = g
            end
        end
        World.current().items = keep
        for _, g in ipairs(grounded) do
            InventoryService.add_item(g.item)
            MessageService.add(string.format("You pick up %d %s.", g.item.qty, g.item.type),
"good")
        end
    end }
end

InventoryCommands.equip = function (slot_index)
    return { execute = function ()
        local ok, item = PlayerInventory.equip(slot_index)
        if not ok then
            MessageService.add("You can't equip that.", "warning")
            return
        end
        MessageService.add(string.format("You equip the %s.", item.type), "good")
    end }
end

InventoryCommands.use = function (slot_index)             -- base items
    return { execute = function ()
        local ok, item = PlayerInventory.use(slot_index)
        if not ok then
            MessageService.add("You can't use that.", "warning")
            return
        end
        MessageService.add(string.format("You use the %s.", item.type), "info")
    end }
end

InventoryCommands.drop = function (slot_index)
    return { execute = function ()
        local item = InventoryService.remove_item(slot_index)
        if not item then
            MessageService.add("There is nothing to drop.", "warning")
            return
        end
        InventoryService.place_item(item, Player.x, Player.y)
        MessageService.add(string.format("You drop the %s.", item.type), "info")
    end }
end

InventoryService.commands = InventoryCommands
return InventoryService
