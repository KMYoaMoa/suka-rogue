local Tile = require "tile"
local conf = require "conf"

-- Camera: size of the visible area (in tiles) and the world tile shown
-- at the top-left of the screen. The player is always centered on screen,
-- so the dungeon scrolls underneath the camera.
local camera = {}

camera.width  = conf.CAMERA_WIDTH
camera.height = conf.CAMERA_HEIGHT

camera.x = 0   -- world tile at screen (0, 0); recomputed on every render
camera.y = 0

-- Re-center the viewport on the player (turn-based: call once per render)
camera.update = function (player_x, player_y)
    camera.x = player_x - math.floor(camera.width / 2)
    camera.y = player_y - math.floor(camera.height / 2)
end

-- World coordinates of a screen tile
camera.world_x = function (sx) return camera.x + sx end
camera.world_y = function (sy) return camera.y + sy end

-- Tile to draw at screen position (sx, sy); out-of-dungeon area is wall.
--   grid: the dungeon tile grid (passed in to keep camera decoupled)

camera.tile_at = function (sx, sy, grid)
    local x, y = camera.world_x(sx), camera.world_y(sy)
    if conf.is_pos_valid(x, y) then
        return grid[x][y]
    end
    if grid.has_floor_around(x, y) then
        return Tile.new("wall")
    else
        return Tile.new("void")
    end
end

return camera
