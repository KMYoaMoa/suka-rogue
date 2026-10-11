local Cell = require "models.dungeon.Cell"
local Map = require "models.dungeon.Map"
local Path = require "models.dungeon.Path"
local Biome = require "models.dungeon.Biome"
local Dungeon = require "models.dungeon.Dungeon"
local DungeonService = require "services.DungeonService"
local Tile = require "models.dungeon.Tile"
local conf = require "conf"

-- MapFactory owns the dungeon generation logic. The Map table itself only
-- holds the generated data and knows how to display it.
local DungeonFactory = {}

-- Safety cap: Cell:divide can report false even when more rooms are still
-- possible (it descends into a random subtree), so a plain `while` could spin
-- forever. Allow a generous number of attempts per requested room and bail out.
local MAX_ATTEMPTS_PER_ROOM = 50

local function divide(map)
    local room_cnt = 1
    local attempts = 0
    local max_attempts = map.num_rooms * MAX_ATTEMPTS_PER_ROOM
    while room_cnt < map.num_rooms and attempts < max_attempts do
        attempts = attempts + 1
        if map.root:divide(map.min_dimension) then
            room_cnt = room_cnt + 1
        end
    end
    if room_cnt < map.num_rooms then
        print(string.format(
            "MapFactory: created %d of %d requested rooms after %d attempts; stopping to avoid an infinite loop.",
            room_cnt, map.num_rooms, attempts
        ))
    end
end

local function construct_list(map)
    map.cell_list = map.root:construct_list()
end

local function find_neighbours(map)
	for _, i in ipairs(map.cell_list) do
		for _, j in ipairs(map.cell_list) do
			if i ~= j then
				if j.x_pos - 1 == i:x_pos_end() then
					if math.max(i.y_pos, j.y_pos) < math.min(i:y_pos_end(), j:y_pos_end()) then
						i.h_neighbours[#i.h_neighbours+1] = j
					end
				end
				if j.y_pos - 1 == i:y_pos_end() then
					if math.max(i.x_pos, j.x_pos) < math.min(i:x_pos_end(), j:x_pos_end()) then
						i.v_neighbours[#i.v_neighbours+1] = j
					end
				end
			end
		end
	end
end

local function shrink(map)
	for _, i in ipairs(map.cell_list) do
	    local x_factor = math.random(6, 9)
		local y_factor = math.random(6, 9)
		local x_size_new = math.max(math.floor(x_factor * i.x_size / 10), map.min_dimension)
        local y_size_new = math.max(math.floor(y_factor * i.y_size / 10), map.min_dimension)
        local x_offset = math.floor((i.x_size - x_size_new) * 0.5)
        local y_offset = math.floor((i.y_size - y_size_new) * 0.5)
        i.x_pos = i.x_pos + x_offset
        i.y_pos = i.y_pos + y_offset
        i.x_size = x_size_new
        i.y_size = y_size_new
	end
end

local function add_path(map)
    for _, i in ipairs(map.cell_list) do
		for _, j in ipairs(i.h_neighbours) do
    		local overlap_start = math.max(i.y_pos, j.y_pos)
            local overlap_end = math.min(i:y_pos_end(), j:y_pos_end())
            if overlap_start <= overlap_end then
                local hall_y_pos = math.random(overlap_start, overlap_end)
                local p = Path:new(i:x_pos_end() + 1, hall_y_pos, j.x_pos - i:x_pos_end() - 1, 1)
                p.a, p.b = i, j
                map.path_list[#map.path_list+1] = p
                i.connected[#i.connected+1] = j
                j.connected[#j.connected+1] = i
            end
		end
		for _, j in ipairs(i.v_neighbours) do
    		local overlap_start = math.max(i.x_pos, j.x_pos)
    		local overlap_end = math.min(i:x_pos_end(), j:x_pos_end())
            if overlap_start <= overlap_end then
                local hall_x_pos = math.random(overlap_start, overlap_end)
                local p = Path:new(hall_x_pos, i:y_pos_end() + 1, 1, j.y_pos - i:y_pos_end() - 1)
                p.a, p.b = i, j
                map.path_list[#map.path_list+1] = p
                i.connected[#i.connected+1] = j
                j.connected[#j.connected+1] = i
            end
		end
	end
end

-- Return the cells of the largest connected component over `cell.connected`.
-- Ties: first-found component wins (`>` = strictly bigger replaces).
local function keep_largest_component(map)
    local seen, best = {}, {}
    for _, root in ipairs(map.cell_list) do
        if not seen[root] then
            local comp, stack = {}, { root }
            seen[root] = true
            while #stack > 0 do
                local c = table.remove(stack)
                comp[#comp + 1] = c
                for _, n in ipairs(c.connected) do
                    if not seen[n] then
                        seen[n] = true
                        stack[#stack + 1] = n
                    end
                end
            end
            if #comp > #best then best = comp end
        end
    end
    map.cell_list = best
end

-- Drop corridors whose rooms were both removed by keep_largest_component,
-- so dungeon.lua never carves floating stubs into solid wall.
local function drop_stub_paths(map)
    local keep = {}
    for _, c in ipairs(map.cell_list) do keep[c] = true end
    local kept_paths = {}
    for _, p in ipairs(map.path_list) do
        if keep[p.a] and keep[p.b] then
            kept_paths[#kept_paths + 1] = p
        end
    end
    map.path_list = kept_paths
end

local function rasterize(map)
    -- carve rooms
    for _, c in ipairs(map.cell_list) do
        for x = c.x_pos, math.min(c:x_pos_end(), conf.SIZE_X - 1) do
            for y = c.y_pos, math.min(c:y_pos_end(), conf.SIZE_Y - 1) do
                local t = Tile.new("floor")
                t.biome = c.biome
                DungeonService.setTile(t, x, y)
            end
        end
    end
end

local function carve(map)
    -- carve corridors
    for _, p in ipairs(map.path_list) do
        for x = p.x_pos, math.min(p:x_pos_end(), conf.SIZE_X - 1) do
            for y = p.y_pos, math.min(p:y_pos_end(), conf.SIZE_Y - 1) do
                local t = Tile.new("floor")
                DungeonService.setTile(t, x, y)
            end
        end
    end

    -- set walls
    DungeonService.iterate({
        during = function (x, y)
            if DungeonService.getTile(x, y).type == "void" then
                if DungeonService.has_floor_around(x, y) then
                    local t = Tile.new("wall")
                    DungeonService.setTile(t, x, y)
                end
            end
        end
    })

    Dungeon.rooms = map.cell_list
    Dungeon.paths = map.path_list
end

-- Generate a dungeon map.
--   map_x_size:      expected map width in cells
--   map_y_size:      expected map height in cells
--   min_dimension:   minimal cell/room dimension
--   num_rooms:       number of rooms/cells to partition into
function DungeonFactory.create(num_rooms, min_dimension)
    local root = Cell:new(1, 1, conf.SIZE_X, conf.SIZE_Y)
    local map = Map:new(root, num_rooms, min_dimension)
    divide(map)
    construct_list(map)
    find_neighbours(map)
    shrink(map)
    add_path(map)
    keep_largest_component(map)
    drop_stub_paths(map)
    Biome:assign(map)
    DungeonService.clear()
    rasterize(map)
    carve(map)
    return map
end

return DungeonFactory
