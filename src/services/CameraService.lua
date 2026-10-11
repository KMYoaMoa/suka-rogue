local CameraService = {}
local Camera = require "models.Camera"
local Dungeon = require "models.dungeon.Dungeon"
local DungeonService = require "services.DungeonService"
local Tile = require "models.dungeon.Tile"
local conf = require "conf"

-- Re-center the viewport on the player (turn-based: call once per render)
CameraService.update = function (player_x, player_y)
    Camera.x = player_x - math.floor(Camera.width / 2)
    Camera.y = player_y - math.floor(Camera.height / 2)
end

CameraService.tile_at = function (sx, sy)
    local x, y = Camera.world_x(sx), Camera.world_y(sy)
    if conf.is_pos_valid(x, y) then
        return Dungeon[x][y]
    end
    if DungeonService.has_floor_around(x, y) then
        return Tile.new("wall")
    else
        return Tile.new("void")
    end
end

return CameraService
