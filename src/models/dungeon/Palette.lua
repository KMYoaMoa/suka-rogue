-- Palette: the unified tile-colour system. Each biome owns floor/wall colours;
-- corridors (biome == nil) use DEFAULT. Pure data (no love, no Tile dependency).
local Palette = {}

-- Stable order: Biome:assign cycles through this list, so palettes and biome
-- identity can never drift apart.
local ORDER = { "BiomeA", "BiomeB", "BiomeC", "BiomeD", "BiomeE" }

-- Placeholder palettes; tuned brighter for a more legible environment.
-- Values are {r, g, b} for setColor.
local BIOMES = {
    BiomeA = { floor = {0.60, 0.52, 0.43}, wall = {0.36, 0.31, 0.26} },
    BiomeB = { floor = {0.40, 0.55, 0.46}, wall = {0.25, 0.35, 0.29} },
    BiomeC = { floor = {0.51, 0.43, 0.61}, wall = {0.33, 0.27, 0.40} },
    BiomeD = { floor = {0.61, 0.51, 0.34}, wall = {0.40, 0.33, 0.21} },
    BiomeE = { floor = {0.48, 0.48, 0.53}, wall = {0.30, 0.30, 0.35} },
}

-- Corridors and unknown/absent biomes: biome-independent by design (draft).
local DEFAULT = { floor = {0.65, 0.65, 0.70}, wall = {0.81, 0.81, 0.86} }

Palette.ORDER   = ORDER
Palette.biomes  = BIOMES
Palette.DEFAULT = DEFAULT

Palette.of = function (biome)
    return BIOMES[biome] or DEFAULT
end

-- Floor/wall colours come from the biome palette; other tile types keep
-- their Tile.def colour (callers fall back when this returns nil).
Palette.color_for = function (biome, tile_type)
    local p = Palette.of(biome)
    if tile_type == "floor" then return p.floor end
    if tile_type == "wall"  then return p.wall  end
    return nil
end

-- Returns three components: no table allocation in the render loop.
Palette.dim = function (c, factor)
    return c[1] * factor, c[2] * factor, c[3] * factor
end

return Palette
