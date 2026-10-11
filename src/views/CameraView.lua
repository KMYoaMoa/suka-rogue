local CameraService = require "services.CameraService"
local PlayerService = require "services.PlayerService"
local Dungeon = require "models.dungeon.Dungeon"
local Item = require "models.item.Item"
local Tile = require "models.dungeon.Tile"
local conf = require "conf"

local CameraView = {}

CameraView.render = function ()
    local player_x, player_y = PlayerService.getPosition()
    local camera_w, camera_h = CameraService.getDimensions()
    for sx = 0, camera_w - 1, 1 do
        for sy = 0, camera_h - 1, 1 do
            local transform = love.math.newTransform(sx * conf.TILE_SIZE, sy * conf.TILE_SIZE, 0, 2, 2, 0, 0)
            local wx = CameraService.world_x(sx)
            local wy = CameraService.world_y(sy)
            if wx == player_x and wy == player_y then
                love.graphics.print("@", transform)
            else
                local flag = false
                for _, g in ipairs(Dungeon.items) do
                    if g.x == wx and g.y == wy then
                        local c = Item.color(g.item)
                        if c then love.graphics.setColor(c[1], c[2], c[3]) end
                        love.graphics.print(Item.glyph(g.item), transform)
                        love.graphics.setColor(1, 1, 1)   -- never leak item colour into later draws
                        flag = true
                        break
                    end
                end
                if not flag then
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
end

return CameraView
