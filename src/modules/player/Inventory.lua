local Items  = require "modules.items"
local Player = require "modules.player.Player"

local Item = Items.Item
local Rules = Items.Rules

-- Player-owned inventory/equipment rules. Ground-item placement and pickup
-- commands remain in the legacy InventoryService until the items/world split.
local Inventory = {}

function Inventory.add_item(item)
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

function Inventory.remove_item(index)
    local item = Player.inventory[index]
    if not item then return nil end
    table.remove(Player.inventory, index)
    return item
end

function Inventory.equip(index)
    local item = Player.inventory[index]
    if not item or not Item.is_equippable(item) then return false end
    local slot = Item.def_of(item).kind
    local old = Player.equipped[slot]
    Player.equipped[slot] = item
    table.remove(Player.inventory, index)
    if old then Inventory.add_item(old) end
    return true, item
end

function Inventory.use(index)
    local item = Player.inventory[index]
    if not item or not Item.is_usable(item) then return false end
    local behavior = Rules.behavior(item)
    if behavior.use then behavior.use(item, Player) end
    item.qty = item.qty - 1
    if item.qty <= 0 then table.remove(Player.inventory, index) end
    return true, item
end

return Inventory
