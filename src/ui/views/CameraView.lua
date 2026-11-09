local CameraService  = require "ui.camera.CameraService"
local Presentation   = require "game.Presentation"
local DungeonModule  = require "modules.dungeon"
local Palette        = DungeonModule.Palette
local conf           = require "conf"

local CameraView = {}

local function set_color(c, factor)
    if c then love.graphics.setColor(Palette.dim(c, factor or 1)) end
end

CameraView.render = function ()
    local player_x, player_y = Presentation.player_position()
    CameraService.update(player_x, player_y)
    local camera_w, camera_h = CameraService.getDimensions()
    local next_tick = Presentation.next_tick()

    for sx = 0, camera_w - 1, 1 do
        for sy = 0, camera_h - 1, 1 do
            local transform = love.math.newTransform(sx * conf.TILE_SIZE, sy * conf.TILE_SIZE, 0, 2, 2, 0, 0)
            local wx = CameraService.world_x(sx)
            local wy = CameraService.world_y(sy)
            local tile  = CameraService.tile_at(sx, sy)
            local state = Presentation.tile_state(tile)

            -- Attack targets: a dark-gray background under the tile glyph.
            if state == "visible" and Presentation.is_target(wx, wy) then
                love.graphics.setColor(conf.TARGET_HIGHLIGHT[1],
                                       conf.TARGET_HIGHLIGHT[2],
                                       conf.TARGET_HIGHLIGHT[3])
                love.graphics.rectangle("fill",
                    sx * conf.TILE_SIZE, sy * conf.TILE_SIZE,
                    conf.TILE_SIZE, conf.TILE_SIZE)
                love.graphics.setColor(1, 1, 1)
            end

            if wx == player_x and wy == player_y then
                love.graphics.print("@", transform)          -- always visible
            elseif state ~= "undiscovered" then
                local dim = (state == "discovered") and conf.EXPLORED_DIM or 1

                -- Visible tiles show everything; discovered tiles show only
                -- constructs (draft), dimmed.
                local occupant  = Presentation.occupant_at(wx, wy)
                local construct = Presentation.occupant_kind(occupant) == "construct"
                if occupant and (state == "visible" or construct) then
                    local due_next = Presentation.is_next_actor(occupant, next_tick)
                    local color = due_next and conf.NEXT_ACTOR_COLOR or occupant.color
                    set_color(color, dim)
                    love.graphics.print(occupant.glyph, transform)
                    love.graphics.setColor(1, 1, 1)
                else
                    -- Items are visible only on currently visible tiles.
                    local item = nil
                    if state == "visible" then item = Presentation.item_at(wx, wy) end
                    if item then
                        set_color(Presentation.item_color(item), 1)
                        love.graphics.print(Presentation.item_glyph(item), transform)
                        love.graphics.setColor(1, 1, 1)
                    else
                        local c = Presentation.tile_color(tile)
                        set_color(c, dim)
                        love.graphics.print(Presentation.tile_glyph(tile), transform)
                        love.graphics.setColor(1, 1, 1)
                    end
                end
            end
            -- undiscovered: draw nothing (the cleared background is black)
        end
    end
end

return CameraView
