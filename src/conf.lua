
local conf = {}

conf.SIZE_X = 90
conf.SIZE_Y = 45
conf.TILE_SIZE = 32

conf.CAMERA_WIDTH  = 32   -- visible area, in tiles (fills 1280px at 32px tiles)
conf.CAMERA_HEIGHT = 22   -- 704px; the 16px strip below stays free for the HUD

conf.is_pos_valid = function (x, y)
    return (x >= 0 and x < conf.SIZE_X) and (y >= 0 and y < conf.SIZE_Y)
end

return conf
