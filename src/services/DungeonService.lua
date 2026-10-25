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

-- An adjacent floor tile, preferring one inside a room (non-nil biome).
-- Used to give walls their room palette/darkness; corridor-only walls fall
-- back to a corridor floor (default palette / corridor darkness).
DungeonService.floor_around = function (x, y)
    local dx_list = {-1, 0, 1, -1, 1, -1, 0, 1}
    local dy_list = {-1, -1, -1, 0, 0, 1, 1, 1}
    local fallback
    for i = 1, 8, 1 do
        local nx = x + dx_list[i]
        local ny = y + dy_list[i]
        if conf.is_pos_valid(nx, ny) then
            local t = Dungeon[nx][ny]
            if t.type == "floor" then
                if t.biome then return t end   -- prefer a room floor
                fallback = fallback or t       -- corridor floor
            end
        end
    end
    return fallback
end

DungeonService.is_passable = function (x, y) return Tile.passable(Dungeon[x][y]) end

-- The room whose bounds contain (x, y), or nil (corridors are not rooms).
DungeonService.room_at = function (x, y)
    for _, room in ipairs(Dungeon.rooms) do
        if x >= room.x_pos and x <= room:x_pos_end()
           and y >= room.y_pos and y <= room:y_pos_end() then
            return room
        end
    end
    return nil
end

-- Entrances are orthogonal: a corridor always meets a room edge head-on.
local NEIGHBOURS4 = {
    {1, 0}, {-1, 0}, {0, 1}, {0, -1},
}

-- True for a passable room tile that touches a passable tile outside its
-- room (a corridor): i.e. an entrance/exit. Immovable blockers must not be
-- placed here or they can seal the opening.
DungeonService.is_entrance = function (x, y)
    if not conf.is_pos_valid(x, y)
       or not DungeonService.is_passable(x, y) then
        return false
    end
    local room = DungeonService.room_at(x, y)
    if not room then return false end
    for _, d in ipairs(NEIGHBOURS4) do
        local nx, ny = x + d[1], y + d[2]
        if conf.is_pos_valid(nx, ny)
           and DungeonService.is_passable(nx, ny)
           and not (nx >= room.x_pos and nx <= room:x_pos_end()
                    and ny >= room.y_pos and ny <= room:y_pos_end()) then
            return true
        end
    end
    return false
end

-- One scan helper; avoids a list-of-lists allocation per call
-- (CameraView calls this per visible tile per frame).
local function scan(list, x, y)
    for _, actor in ipairs(list) do
        if not actor.dead and actor.x == x and actor.y == y then
            return actor
        end
    end
    return nil
end

-- The first live occupant standing on (x, y), or nil.
-- Occupant contract: x, y, name, glyph, color, and optional `dead`.
-- Mobs, NPCs and constructs all block; items do not (they render separately).
DungeonService.occupant_at = function (x, y)
    return scan(Dungeon.mobs, x, y)
        or scan(Dungeon.npcs, x, y)
        or scan(Dungeon.constructs, x, y)
end

-- A tile a creature may enter: in bounds, passable terrain, unoccupied.
DungeonService.is_free = function (x, y)
    return conf.is_pos_valid(x, y)
       and DungeonService.is_passable(x, y)
       and DungeonService.occupant_at(x, y) == nil
end

return DungeonService
