-- Compatibility configuration facade. Stable engine constants live in
-- core/config; presentation layout stays here until the UI migration.
local CoreConfig = require "core.config"

local conf = {}
for key, value in pairs(CoreConfig) do conf[key] = value end

conf.SCREEN_WIDTH  = 1280
conf.SCREEN_HEIGHT = 720

conf.CAMERA_WIDTH  = 32   -- camera pane width, in tiles (1024px at 32px)
conf.CAMERA_HEIGHT = 22   -- 704px; the 16px strip below stays free for the HUD

-- Right-side HUD panel. The camera occupies the left 1024px; the remaining
-- 256px is a dedicated sidebar. All HUD origins are screen pixels.
conf.HUD_X          = conf.CAMERA_WIDTH * conf.TILE_SIZE
conf.HUD_WIDTH      = conf.SCREEN_WIDTH - conf.HUD_X
conf.HUD_PADDING    = 8
conf.HUD_TEXT_WIDTH = conf.HUD_WIDTH - 2 * conf.HUD_PADDING

conf.STATUS_ORIGIN_X = conf.HUD_X + conf.HUD_PADDING
conf.STATUS_ORIGIN_Y = 12
conf.STATUS_LINE_HEIGHT = 20

conf.MESSAGE_ORIGIN_X = conf.HUD_X + conf.HUD_PADDING
conf.MESSAGE_ORIGIN_Y = 88
conf.MESSAGE_LINES       = 6    -- how many of the latest entries are shown
conf.MESSAGE_LINE_HEIGHT = 20   -- px between wrapped message lines
conf.MESSAGE_AREA_HEIGHT = 160  -- newest entries are bottom-aligned in this area

conf.INV_ORIGIN_X = conf.HUD_X + conf.HUD_PADDING
conf.INV_ORIGIN_Y = 280      -- equipment block; backpack follows below
conf.INV_LINE_HEIGHT = 20

conf.EXPLORED_DIM      = 0.30 -- brightness multiplier for discovered tiles
conf.TARGET_HIGHLIGHT  = {0.15, 0.15, 0.15}  -- target-tile background (slightly above black)
conf.NEXT_ACTOR_COLOR  = {1.0, 0.15, 0.15}   -- mobs acting on the next player tick

return conf
