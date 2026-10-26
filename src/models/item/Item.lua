
-- Item: one *definition* per type (shared, immutable; the tile.lua pattern)
-- and one *instance* per concrete item (`{ type, def, qty }`).
local Item = {}

-- Shared per-type definitions. Keyed by type name.
--   kind:  "melee" | "ranged" | "base" | "armor" (determines behavior table + slot)
--   tags:  capability flags for queries ("equippable", "weapon", "usable", "stackable", ...)
--   stats: gameplay numbers; slot-specific (damage/range/accuracy/defense/heal/value)
--   glyph, color: drawn on the ground / in the list
local defs = {
    sword   = { name = "Rusty Sword",  kind = "melee",
                glyph = "/", color = {0.85, 0.85, 0.85},
                tags = { "equippable", "weapon" },
                stats = { damage = 12, range = 1 } },
    pistol  = { name = "Pistol",       kind = "ranged",
                glyph = ")", color = {0.80, 0.80, 0.88},
                tags = { "equippable", "weapon" },
                stats = { damage = 6, accuracy = 0.75 } },
    plate   = { name = "Iron Plate",   kind = "armor",
                glyph = "]", color = {0.55, 0.60, 0.70},
                tags = { "equippable" },
                stats = { defense = 8 } },
    medkit  = { name = "Medkit",       kind = "base",
                glyph = "+", color = {0.30, 0.90, 0.30},
                tags = { "usable", "consumable", "stackable" },
                stats = { heal = 30 } },
    coin    = { name = "Coin",         kind = "base",
                glyph = "o", color = {0.95, 0.85, 0.25},
                tags = { "stackable" },
                stats = { value = 1 } },
}

-- Create an item instance of `type_name`; unknown names fall back to a
-- generic base item so nothing is ever nil.
Item.new = function (type_name)
    local def = defs[type_name] or defs.coin
    return { type = def.name, def = def, qty = 1 }
end

Item.def_of = function (item) return item and item.def or defs.coin end

-- Tag queries (nil-safe) — the composition-friendly replacement for
-- "is-a" checks. Future lore rules read the same tags (see §6).
Item.has_tag  = function (item, tag)
    local tags = Item.def_of(item).tags
    for _, t in ipairs(tags) do if t == tag then return true end end
    return false
end
Item.is_equippable = function (item) return Item.has_tag(item, "equippable") end
Item.is_usable     = function (item) return Item.has_tag(item, "usable") end
Item.is_stackable  = function (item) return Item.has_tag(item, "stackable") end
Item.glyph  = function (item) return Item.def_of(item).glyph end
Item.color  = function (item) return Item.def_of(item).color end

-- Behavior lookup keyed by kind: what *this kind* does when used/equipped.
-- Functions receive (item, player): plain data in, no `self`, no hierarchy.
-- Adding a fourth kind later = one new key here (composition, not a subclass).
local behaviors = {
    melee = {
        equip   = function (item, player) player.equipped.melee = item end,
        unequip = function (item, player) player.equipped.melee = nil end,
    },
    ranged = {
        equip   = function (item, player) player.equipped.ranged = item end,
        unequip = function (item, player) player.equipped.ranged = nil end,
    },
    armor = {
        equip   = function (item, player) player.equipped.armor = item end,
        unequip = function (item, player) player.equipped.armor = nil end,
    },
    base = {
        use = function (item, player)
            if Item.def_of(item).stats.heal then
                player.health = math.min(player.health_max,
                                         player.health + Item.def_of(item).stats.heal)
            end
        end,
    },
}
Item.behavior = function (item) return behaviors[Item.def_of(item).kind] or {} end

return Item