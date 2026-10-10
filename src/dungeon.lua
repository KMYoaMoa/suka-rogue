local Tile = require "tile"
local MapFactory = require "map.MapFactory"

-- Dungeon object
local dungeon = {}

-- Get global config from main
local conf = require "conf"

dungeon.iterate = function (actions)
    for x = 0, conf.SIZE_X - 1, 1 do
        if actions.before then actions.before(x) end
		for y = 0, conf.SIZE_Y - 1, 1 do
    		if actions.during then actions.during(x, y) end
		end
		if actions.after then actions.after(x) end
	end
end

dungeon.has_floor_around = function(x, y)
    local dx_list = {-1, 0, 1, -1, 1, -1, 0, 1}
    local dy_list = {-1, -1, -1, 0, 0, 1, 1, 1}
    for i = 1, 8, 1 do
        local nx = x + dx_list[i]
        local ny = y + dy_list[i]
        if conf.is_pos_valid(nx, ny) and dungeon[nx][ny].type == "floor" then
            local t = Tile.new("wall")
            return true
        end
    end
    return false
end

-- Initialize dungeon object
dungeon.init = function ()
    dungeon.iterate({
        before = function (x) dungeon[x] = {} end,
        during = function (x, y) dungeon.setTile("void", x, y) end
    })

    -- generate a BSP map
    local map = MapFactory.create(conf.SIZE_X, conf.SIZE_Y, 3, 25)

    -- carve rooms
    for _, c in ipairs(map.cell_list) do
        for x = c.x_pos, math.min(c:x_pos_end(), conf.SIZE_X - 1) do
            for y = c.y_pos, math.min(c:y_pos_end(), conf.SIZE_Y - 1) do
                local t = Tile.new("floor")
                t.biome = c.biome
                dungeon.setTile(t, x, y)
            end
        end
    end

    -- carve corridors
    for _, p in ipairs(map.path_list) do
        for x = p.x_pos, math.min(p:x_pos_end(), conf.SIZE_X - 1) do
            for y = p.y_pos, math.min(p:y_pos_end(), conf.SIZE_Y - 1) do
                local t = Tile.new("floor")
                dungeon.setTile(t, x, y)
            end
        end
    end

    -- set walls
    dungeon.iterate({
        during = function (x, y)
            if dungeon[x][y].type == "void" then
                if dungeon.has_floor_around(x, y) then
                    local t = Tile.new("wall")
                    dungeon.setTile(t, x, y)
                end
            end
        end
    })

    dungeon.rooms = map.cell_list
    dungeon.paths = map.path_list
end

-- Set tile for specific position
--  tile: tile object to be set
--  x, y: absolute coordinate
dungeon.setTile = function (tile, x, y)
    if conf.is_pos_valid(x, y) then
        dungeon[x][y] = type(tile) == "string" and Tile.new(tile) or tile
    end
end

dungeon.is_passable = function (x, y) return Tile.passable(dungeon[x][y]) end

-- Return dungeon object
return dungeon
