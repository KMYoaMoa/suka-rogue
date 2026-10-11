local Dungeon = require "models.dungeon.Dungeon"
local conf = require "conf"
local Tile = require "models.dungeon.Tile"

local DungeonService = {}

function DungeonService.iterate(obj)
    for x = 0, conf.SIZE_X - 1, 1 do
        if obj.before then obj.before(x) end
    	for y = 0, conf.SIZE_Y - 1, 1 do
            if obj.during then obj.during(x, y) end
    	end
        if obj.after then obj.after(x) end
    end
end

-- Initialize dungeon object
DungeonService.clear = function ()
    DungeonService.iterate({
        before = function (x) Dungeon[x] = {} end,
        during = function (x, y) DungeonService.setTile("void", x, y) end
    })
end

-- Set tile for specific position
--  tile: tile object to be set
--  x, y: absolute coordinate
DungeonService.setTile = function (tile, x, y)
    if conf.is_pos_valid(x, y) then
        Dungeon[x][y] = type(tile) == "string" and Tile.new(tile) or tile
    end
end

DungeonService.getTile = function (x, y)
    if conf.is_pos_valid(x, y) then return Dungeon[x][y] end
    return Tile.new("void")
end

DungeonService.getSpawnRoom = function ()
	return Dungeon.rooms[1]
end

DungeonService.has_floor_around = function(x, y)
    local dx_list = {-1, 0, 1, -1, 1, -1, 0, 1}
    local dy_list = {-1, -1, -1, 0, 0, 1, 1, 1}
    for i = 1, 8, 1 do
        local nx = x + dx_list[i]
        local ny = y + dy_list[i]
        if conf.is_pos_valid(nx, ny) and Dungeon[nx][ny].type == "floor" then
            return true
        end
    end
    return false
end

DungeonService.is_passable = function (x, y) return Tile.passable(Dungeon[x][y]) end

return DungeonService
