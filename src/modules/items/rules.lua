-- Item behavior keyed by kind. Behavior receives plain item/player data and
-- does not own player inventory or world placement.
local Item = require "modules.items.Item"

local Rules = {}

local behaviors = {
    melee = {
        equip = function (item, player) player.equipped.melee = item end,
        unequip = function (item, player) player.equipped.melee = nil end,
    },
    ranged = {
        equip = function (item, player) player.equipped.ranged = item end,
        unequip = function (item, player) player.equipped.ranged = nil end,
    },
    armor = {
        equip = function (item, player) player.equipped.armor = item end,
        unequip = function (item, player) player.equipped.armor = nil end,
    },
    base = {
        use = function (item, player)
            local heal = Item.def_of(item).stats.heal
            if heal then
                player.health = math.min(player.health_max, player.health + heal)
            end
        end,
    },
}

function Rules.behavior(item)
    return behaviors[Item.def_of(item).kind] or {}
end

return Rules
