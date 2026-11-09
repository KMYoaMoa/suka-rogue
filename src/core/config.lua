-- Stable game-engine constants shared by domain code. No UI or LÖVE imports.
local Config = {}

Config.SIZE_X = 90
Config.SIZE_Y = 45
Config.TILE_SIZE = 32

function Config.is_pos_valid(x, y)
    return (x >= 0 and x < Config.SIZE_X) and (y >= 0 and y < Config.SIZE_Y)
end

Config.VISION_START      = 12   -- starting vision value on the player's tile
Config.DARKNESS_MIN      = 1    -- per-room darkness range; lower = farther vision
Config.DARKNESS_MAX      = 3
Config.CORRIDOR_DARKNESS = 2    -- corridors are not rooms; fixed default

return Config
