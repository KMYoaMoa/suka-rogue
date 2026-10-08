local Cell = require "Cell"
local Map = require "Map"
local Path = require "Path"

-- MapFactory owns the dungeon generation logic. The Map table itself only
-- holds the generated data and knows how to display it.
local MapFactory = {}

local function divide(map)
    local room_cnt = 1
    while room_cnt < map.num_rooms do
        if map.root:divide(map.min_dimension) then
            room_cnt = room_cnt + 1
        end
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
                map.path_list[#map.path_list+1] = Path:new(i:x_pos_end() + 1, hall_y_pos, j.x_pos - i:x_pos_end() - 1, 1)
            end
		end
		for _, j in ipairs(i.v_neighbours) do
    		local overlap_start = math.max(i.x_pos, j.x_pos)
    		local overlap_end = math.min(i:x_pos_end(), j:x_pos_end())
            if overlap_start <= overlap_end then
                local hall_x_pos = math.random(overlap_start, overlap_end)
                map.path_list[#map.path_list+1] = Path:new(hall_x_pos, i:y_pos_end() + 1, 1, j.y_pos - i:y_pos_end() - 1)
            end
		end
	end
end

-- Generate a dungeon map.
--   map_x_size:      expected map width in cells
--   map_y_size:      expected map height in cells
--   min_dimension:   minimal cell/room dimension
--   num_rooms:       number of rooms/cells to partition into
function MapFactory.create(map_x_size, map_y_size, min_dimension, num_rooms)
    local root = Cell:new(1, 1, map_x_size, map_y_size)
    local map = Map:new(root, num_rooms, min_dimension)
    divide(map)
    construct_list(map)
    find_neighbours(map)
    shrink(map)
    add_path(map)
    return map
end

return MapFactory
