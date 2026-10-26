
local Item = require "models.item.Item"
local Player = require "models.Player"
local Dungeon = require "models.dungeon.Dungeon"
local MessageService = require "services.MessageService"

local InventoryService = {}
local InventoryCommands = {}

-- Add an instance to the inventory; stackable same-type entries merge.
InventoryService.add_item = function (item)
    if Item.is_stackable(item) then
        for _, entry in ipairs(Player.inventory) do
            if entry.type == item.type then
                entry.qty = entry.qty + item.qty
                return
            end
        end
    end
    Player.inventory[#Player.inventory + 1] = item
end

InventoryService.remove_item = function (index)
    local item = Player.inventory[index]
    if not item then return nil end
    table.remove(Player.inventory, index)
    return item
end

-- Ground items: the separate list (draft §3.5). Dungeon.items = { {x, y, item}, ... }
-- Accepts a type name (creates a fresh instance) or a ready item instance
-- (e.g. the dropped one) so the same entry keeps its identity and qty.
InventoryService.place_item = function (type_name_or_item, x, y)
    local item = type(type_name_or_item) == "string"
        and Item.new(type_name_or_item)
        or type_name_or_item
    Dungeon.items[#Dungeon.items + 1] = { x = x, y = y, item = item }
end

InventoryService.items_at = function (x, y)
    local out = {}
    for _, g in ipairs(Dungeon.items) do
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
        for _, g in ipairs(Dungeon.items) do
            if g.x ~= Player.x or g.y ~= Player.y then
                keep[#keep + 1] = g
            end
        end
        Dungeon.items = keep
        for _, g in ipairs(grounded) do
            InventoryService.add_item(g.item)
            MessageService.add(string.format("You pick up %d %s.", g.item.qty, g.item.type),
"good")
        end
    end }
end

InventoryCommands.equip = function (slot_index)
    return { execute = function ()
        local item = Player.inventory[slot_index]
        if not item or not Item.is_equippable(item) then
            MessageService.add("You can't equip that.", "warning")
            return
        end
        local slot = Item.def_of(item).kind               -- "melee" | "ranged" | "armor"
        local old = Player.equipped[slot]
        Player.equipped[slot] = item                      -- swap out
        table.remove(Player.inventory, slot_index)
        if old then InventoryService.add_item(old) end
        MessageService.add(string.format("You equip the %s.", item.type), "good")
    end }
end

InventoryCommands.use = function (slot_index)             -- base items
    return { execute = function ()
        local item = Player.inventory[slot_index]
        if not item or not Item.is_usable(item) then
            MessageService.add("You can't use that.", "warning")
            return
        end
        local behavior = Item.behavior(item)
        if behavior.use then behavior.use(item, Player) end
        item.qty = item.qty - 1
        if item.qty <= 0 then table.remove(Player.inventory, slot_index) end
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
