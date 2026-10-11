local CameraModel = require "models.Camera"
local CameraService = require "services.CameraService"
local Tile = require "models.dungeon.Tile"
local Player = require "models.player.Player"
local conf = require "conf"

local CameraView = {}

CameraView.render = function ()
    for sx = 0, CameraModel.width - 1, 1 do
        for sy = 0, CameraModel.height - 1, 1 do
            local transform = love.math.newTransform(sx * conf.TILE_SIZE, sy * conf.TILE_SIZE, 0, 2, 2, 0, 0)
            if CameraModel.world_x(sx) == Player.x and CameraModel.world_y(sy) == Player.y then
                love.graphics.print("@", transform)
            else
                local tile = CameraService.tile_at(sx, sy)
                local def = tile.def
                if tile.type == "floor" then def = Tile.floor_for_biome(tile.biome) end
                if def.color then love.graphics.setColor(def.color[1], def.color[2], def.color[3]) end
                love.graphics.print(def.glyph, transform)
                love.graphics.setColor(1, 1, 1)
            end
        end
    end
end

return CameraView
