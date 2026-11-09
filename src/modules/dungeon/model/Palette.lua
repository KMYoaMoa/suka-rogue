-- Palette: colour queries over content/palettes. Pure data/query; no love.
local biomeData = require "content.biomes"
local palettes = require "content.palettes"

local Palette = {}
Palette.ORDER = biomeData.ORDER

function Palette.of(biome)
    return palettes.biomes[biome] or palettes.default
end

function Palette.color_for(biome, tile_type)
    local p = Palette.of(biome)
    if tile_type == "floor" then return p.floor end
    if tile_type == "wall"  then return p.wall  end
    return nil
end

function Palette.dim(c, factor)
    return c[1] * factor, c[2] * factor, c[3] * factor
end

return Palette
