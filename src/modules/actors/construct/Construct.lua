-- Construct: an immovable, interactive stationary object (defs + instance).
-- No HP and no death in this scope; `requires` is the usability interface.
local Construct = {}

local defs = require "content.constructs"


Construct.new = function (type_name)
    local def = defs[type_name] or defs.unknown
    return {
        type  = type_name,
        def   = def,
        name  = def.name,
        glyph = def.glyph,      -- generic occupant contract (rendering)
        color = def.color,
        x     = 0,
        y     = 0,
        room  = nil,            -- room-scoped conditions compare against this
        -- no `dead`: constructs are never destroyed in this scope;
        -- occupant_at treats nil `dead` as alive.
    }
end

Construct.def_of = function (c) return c and c.def or defs.unknown end
Construct.name   = function (c) return Construct.def_of(c).name end
Construct.glyph  = function (c) return Construct.def_of(c).glyph end
Construct.color  = function (c) return Construct.def_of(c).color end

Construct.has_tag = function (c, tag)
    for _, t in ipairs(Construct.def_of(c).tags) do
        if t == tag then return true end
    end
    return false
end

return Construct
