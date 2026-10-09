
local conf = {}

conf.SIZE_X = 30
conf.SIZE_Y = 15
conf.TILE_SIZE = 32

conf.is_pos_valid = function (x, y)
    return (x >= 0 and x < conf.SIZE_X) and (y >= 0 and y < conf.SIZE_Y)
end

return conf
