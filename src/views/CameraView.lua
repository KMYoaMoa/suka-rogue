local CameraService = require "services.CameraService"
local PlayerService = require "services.PlayerService"
local Tile = require "models.dungeon.Tile"
local conf = require "conf"

local CameraView = {}

CameraView.render = function ()
    local player_x, player_y = PlayerService.getPosition()
    local camera_w, camera_h = CameraService.getDimensions()
    for sx = 0, camera_w - 1, 1 do
        for sy = 0, camera_h - 1, 1 do
            local transform = love.math.newTransform(sx * conf.TILE_SIZE, sy * conf.TILE_SIZE, 0, 2, 2, 0, 0)
            if CameraService.world_x(sx) == player_x and CameraService.world_y(sy) == player_y then
                love.graphics.print("@", transform)
            else
                local tile = CameraService.tile_at(sx, sy)
                local def = tile.def
                if tile.type == "floor" then def = Tile.floor() end
                if def.color then love.graphics.setColor(def.color[1], def.color[2], def.color[3]) end
                love.graphics.print(def.glyph, transform)
                love.graphics.setColor(1, 1, 1)
            end
        end
    end
end

return CameraView
