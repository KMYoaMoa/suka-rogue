local CameraService  = require "services.CameraService"
local PlayerService  = require "services.PlayerService"
local Dungeon        = require "models.dungeon.Dungeon"
local DungeonService = require "services.DungeonService"
local Palette        = require "models.dungeon.Palette"
local VisionService  = require "services.VisionService"
local Item           = require "models.item.Item"
local conf           = require "conf"

local CameraView = {}

local function set_color(c, factor)
    if c then love.graphics.setColor(Palette.dim(c, factor or 1)) end
end

CameraView.render = function ()
    local player_x, player_y = PlayerService.getPosition()
    local camera_w, camera_h = CameraService.getDimensions()

    for sx = 0, camera_w - 1, 1 do
        for sy = 0, camera_h - 1, 1 do
            local transform = love.math.newTransform(sx * conf.TILE_SIZE, sy * conf.TILE_SIZE, 0, 2, 2, 0, 0)
            local wx = CameraService.world_x(sx)
            local wy = CameraService.world_y(sy)
            local tile  = CameraService.tile_at(sx, sy)
            local state = VisionService.state_of(tile)

            if wx == player_x and wy == player_y then
                love.graphics.print("@", transform)          -- always visible
            elseif state ~= "undiscovered" then
                local dim = (state == "discovered") and conf.EXPLORED_DIM or 1

                -- Visible tiles show everything; discovered tiles show only
                -- constructs (draft), dimmed.
                local occupant  = DungeonService.occupant_at(wx, wy)
                local construct = occupant and occupant.def and occupant.def.kind == "construct"
                if occupant and (state == "visible" or construct) then
                    set_color(occupant.color, dim)
                    love.graphics.print(occupant.glyph, transform)
                    love.graphics.setColor(1, 1, 1)
                else
                    -- Items are visible only on currently visible tiles.
                    local item = nil
                    if state == "visible" then
                        for _, g in ipairs(Dungeon.items) do
                            if g.x == wx and g.y == wy then item = g; break end
                        end
                    end
                    if item then
                        set_color(Item.color(item.item), 1)
                        love.graphics.print(Item.glyph(item.item), transform)
                        love.graphics.setColor(1, 1, 1)
                    else
                        local c = Palette.color_for(tile.biome, tile.type) or tile.def.color
                        set_color(c, dim)
                        love.graphics.print(tile.def.glyph, transform)
                        love.graphics.setColor(1, 1, 1)
                    end
                end
            end
            -- undiscovered: draw nothing (the cleared background is black)
        end
    end
end

return CameraView
