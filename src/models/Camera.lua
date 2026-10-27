local conf = require "conf"

-- Camera: size of the visible area (in tiles) and the world tile shown
-- at the top-left of the screen. The player is always centered on screen,
-- so the dungeon scrolls underneath the camera.
local camera = {}

camera.width  = conf.CAMERA_WIDTH
camera.height = conf.CAMERA_HEIGHT

camera.x = 0   -- world tile at screen (0, 0); recomputed on every render
camera.y = 0

return camera
