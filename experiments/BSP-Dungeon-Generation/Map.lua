local Path = require "Path"
-- map class
local Map = {}

function Map:display()
    for _, i in ipairs(self.cell_list) do
        i:display()
    end
    for _, i in ipairs(self.path_list) do
        i:display()
    end
end

function Map:divide()
    local room_cnt = 1
    while room_cnt < self.num_rooms do
        if self.root:divide(self.min_dimension) then
            room_cnt = room_cnt + 1
        end
    end
end

function Map:construct_list()
    self.cell_list = self.root:construct_list()
end

function Map:shrink()
	for _, i in ipairs(self.cell_list) do
	    local x_factor = math.random(6, 9)
		local y_factor = math.random(6, 9)
		local x_size_new = math.max(math.floor(x_factor * i.x_size / 10), self.min_dimension)
        local y_size_new = math.max(math.floor(y_factor * i.y_size / 10), self.min_dimension)
        local x_offset = math.floor((i.x_size - x_size_new) * 0.5)
        local y_offset = math.floor((i.y_size - y_size_new) * 0.5)
        i.x_pos = i.x_pos + x_offset
        i.y_pos = i.y_pos + y_offset
        i.x_size = x_size_new
        i.y_size = y_size_new
	end
end

function Map:find_neighbours()
	for _, i in ipairs(self.cell_list) do
		for _, j in ipairs(self.cell_list) do
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

function Map:add_path()
    for _, i in ipairs(self.cell_list) do
		for _, j in ipairs(i.h_neighbours) do
    		local overlap_start = math.max(i.y_pos, j.y_pos)
            local overlap_end = math.min(i:y_pos_end(), j:y_pos_end())
            if overlap_start <= overlap_end then
                local hall_y_pos = math.random(overlap_start, overlap_end)
                self.path_list[#self.path_list+1] = Path:new(i:x_pos_end() + 1, hall_y_pos, j.x_pos - i:x_pos_end() - 1, 1)
            end
		end
		for _, j in ipairs(i.v_neighbours) do
    		local overlap_start = math.max(i.x_pos, j.x_pos)
    		local overlap_end = math.min(i:x_pos_end(), j:x_pos_end())
            if overlap_start <= overlap_end then
                local hall_x_pos = math.random(overlap_start, overlap_end)
                self.path_list[#self.path_list+1] = Path:new(hall_x_pos, i:y_pos_end() + 1, 1, j.y_pos - i:y_pos_end() - 1)
            end
		end
	end
end

function Map:new(rootcell, numrooms, mindimension)
    local new_obj = {}
    setmetatable(new_obj, self)
    self.__index = self
    new_obj.root = rootcell
    new_obj.num_rooms = numrooms
	new_obj.min_dimension = mindimension
	new_obj.cell_list = {}
	new_obj.path_list = {}
    return new_obj
end

return Map
