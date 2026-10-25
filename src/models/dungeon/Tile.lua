
-- Tile: one *definition* per type (shared, immutable) and one *instance*
-- per grid cell (created by Tile:new / Tile.new_instance).
local Tile = {}

-- Shared per-type definitions. Keyed by type name.
--   passable: movement / spawn checks
--   opaque:   blocks vision propagation (walls/void)
--   glyph:    what to draw (" " = blank/"nothing visible")
--   color:    {r, g, b} for love.graphics.setColor, or nil for default white
local defs = {
    floor = { name = "floor",  passable = true,  opaque = false, glyph = ".", color = {0.6, 0.0, 0.0} },
    wall  = { name = "wall",   passable = false, opaque = true,  glyph = "#", color = {0.8, 0.0, 0.0} },
    void  = { name = "void",   passable = false, opaque = true,  glyph = "X", color = {0.4, 0, 0} },  -- unreachable pocket
    -- placeholders, unused until the systems that place them exist:
    stairs_down = { name = "stairs_down", passable = true, opaque = false, glyph = ">", color = {0.9, 0.9, 0.2} },
    stairs_up   = { name = "stairs_up",   passable = true, opaque = false, glyph = "<", color = {0.9, 0.9, 0.2} },
    trap        = { name = "trap",        passable = true, opaque = false, glyph = "^", color = {0.9, 0.2, 0.2} },
    door        = { name = "door",        passable = true, opaque = false, glyph = "+", color = {0.7, 0.5, 0.2} },
}

-- Create a tile instance of `type_name`; unknown names fall back to wall so
-- the grid is never nil and out-of-range access stays safe.
Tile.new = function (type_name)
    local def = defs[type_name] or defs.wall
    return {
        type       = def.name,   -- semantic kind
        def        = def,        -- shared render/behaviour data
        biome      = nil,        -- per-cell state: filled for room floors
        darkness   = nil,        -- per-cell vision decay (room/corridor)
        discovered = false,      -- has ever been visible
        visible    = false,      -- currently in the player's FOV
        light      = 0,          -- remaining vision (0 when not visible)
    }
end

Tile.def_of = function (tile) return tile and tile.def or defs.wall end

-- Convenience queries that take a tile instance (nil-safe -> wall).
Tile.passable = function (tile) return Tile.def_of(tile).passable end
Tile.opaque   = function (tile) return Tile.def_of(tile).opaque end
Tile.glyph    = function (tile) return Tile.def_of(tile).glyph end
Tile.color    = function (tile) return Tile.def_of(tile).color end

return Tile
