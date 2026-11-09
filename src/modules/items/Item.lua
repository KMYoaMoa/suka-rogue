-- Runtime item instance and registry queries. Definitions are content data.
local defs = require "content.items"

local Item = {}

function Item.new(type_name)
    local def = defs[type_name] or defs.coin
    return { type = def.name, def = def, qty = 1 }
end

Item.def_of = function (item) return item and item.def or defs.coin end

Item.has_tag = function (item, tag)
    for _, candidate in ipairs(Item.def_of(item).tags) do
        if candidate == tag then return true end
    end
    return false
end

Item.is_equippable = function (item) return Item.has_tag(item, "equippable") end
Item.is_usable     = function (item) return Item.has_tag(item, "usable") end
Item.is_stackable  = function (item) return Item.has_tag(item, "stackable") end
Item.glyph        = function (item) return Item.def_of(item).glyph end
Item.color        = function (item) return Item.def_of(item).color end

return Item
