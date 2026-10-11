local Tile = require "models.dungeon.Tile"
local conf = require "conf"

-- Camera: size of the visible area (in tiles) and the world tile shown
-- at the top-left of the screen. The player is always centered on screen,
-- so the dungeon scrolls underneath the camera.
local camera = {}

camera.width  = conf.CAMERA_WIDTH
camera.height = conf.CAMERA_HEIGHT

camera.x = 0   -- world tile at screen (0, 0); recomputed on every render
camera.y = 0


-- World coordinates of a screen tile
camera.world_x = function (sx) return camera.x + sx end
camera.world_y = function (sy) return camera.y + sy end

-- Tile to draw at screen position (sx, sy); out-of-dungeon area is wall.
--   grid: the dungeon tile grid (passed in to keep camera decoupled)



return camera
