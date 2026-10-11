local Camera = require "models.Camera"
local DungeonService = require "services.DungeonService"
local Tile = require "models.dungeon.Tile"
local conf = require "conf"

local CameraService = {}

-- Re-center the viewport on the player (turn-based: call once per render)
CameraService.update = function (player_x, player_y)
    Camera.x = player_x - math.floor(Camera.width / 2)
    Camera.y = player_y - math.floor(Camera.height / 2)
end

CameraService.tile_at = function (sx, sy)
    local x, y = CameraService.world_x(sx), CameraService.world_y(sy)
    if conf.is_pos_valid(x, y) then
        return DungeonService.getTile(x, y)
    end
    if DungeonService.has_floor_around(x, y) then
        return Tile.new("wall")
    end
    return Tile.new("void")
end

CameraService.getDimensions = function ()
	return Camera.width, Camera.height
end

-- World coordinates of a screen tile
CameraService.world_x = function (sx) return Camera.x + sx end
CameraService.world_y = function (sy) return Camera.y + sy end

return CameraService
