
local conf = {}

conf.SIZE_X = 90
conf.SIZE_Y = 45
conf.TILE_SIZE = 32
conf.is_pos_valid = function (x, y)
    return (x >= 0 and x < conf.SIZE_X) and (y >= 0 and y < conf.SIZE_Y)
end

conf.CAMERA_WIDTH  = 32   -- visible area, in tiles (fills 1280px at 32px tiles)
conf.CAMERA_HEIGHT = 22   -- 704px; the 16px strip below stays free for the HUD

conf.MESSAGE_LINES       = 6    -- how many of the latest entries are shown (the "N")
conf.MESSAGE_LINE_HEIGHT = 20   -- px between lines (same step the HUD already uses)
conf.MESSAGE_ORIGIN_X    = 0    -- screen px of the first (oldest visible) line
conf.MESSAGE_ORIGIN_Y    = 400  -- below the HUD block (y 340/360/380)
-- conf.MESSAGE_HISTORY_MAX = 500  -- optional cap; omit for unbounded history

conf.INV_ORIGIN_X = 0        -- inventory list origin (screen px)
conf.INV_ORIGIN_Y = 440      -- below the message block (y 400–500)

conf.VISION_START      = 12   -- starting vision value on the player's tile
conf.DARKNESS_MIN      = 1    -- per-room darkness range; lower = farther vision
conf.DARKNESS_MAX      = 3
conf.CORRIDOR_DARKNESS = 2    -- corridors are not rooms; fixed default
conf.EXPLORED_DIM      = 0.30 -- brightness multiplier for discovered tiles

conf.TARGET_HIGHLIGHT  = {0.15, 0.15, 0.15}  -- target-tile background (slightly above black)

return conf
