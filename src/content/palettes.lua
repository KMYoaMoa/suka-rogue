-- Visual biome palettes are data-only.
local biomes = {
    BiomeA = { floor = {0.60, 0.52, 0.43}, wall = {0.36, 0.31, 0.26} },
    BiomeB = { floor = {0.40, 0.55, 0.46}, wall = {0.25, 0.35, 0.29} },
    BiomeC = { floor = {0.51, 0.43, 0.61}, wall = {0.33, 0.27, 0.40} },
    BiomeD = { floor = {0.61, 0.51, 0.34}, wall = {0.40, 0.33, 0.21} },
    BiomeE = { floor = {0.48, 0.48, 0.53}, wall = {0.30, 0.30, 0.35} },
}
local default = { floor = {0.65, 0.65, 0.70}, wall = {0.81, 0.81, 0.86} }
return { biomes = biomes, default = default }
