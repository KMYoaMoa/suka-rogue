GRID_SIZE = 16

-- cell class
local Cell = {}

function Cell:new(xpos, ypos, xsize, ysize)
    local new_obj = {}
    setmetatable(new_obj, self)
    self.__index = self
    new_obj.x_pos = xpos
    new_obj.y_pos = ypos
    new_obj.x_size = xsize
    new_obj.y_size = ysize
    new_obj.left_c = nil
    new_obj.right_c = nil
    new_obj.h_neighbours = {}
    new_obj.v_neighbours = {}
    return new_obj
end

function Cell:x_pos_end()
    return self.x_pos + self.x_size - 1
end

function Cell:y_pos_end()
    return self.y_pos + self.y_size - 1
end

function Cell:is_leaf()
	return self.left_c == nil
end

function Cell:divide(min_dimension)
    if self.x_size < min_dimension or self.y_size < min_dimension then
        return false
    end
    if not self:is_leaf() then
        if math.random(0, 100) < 50 then
            return self.left_c:divide(min_dimension)
        else
            return self.right_c:divide(min_dimension)
        end
    end
    if self.x_size > self.y_size then
        local lb = math.floor(self.x_size * 0.3)
        local hb = math.floor(self.x_size * 0.7)
        local mid = math.random(lb, hb)
        self.left_c = Cell:new(self.x_pos, self.y_pos, mid, self.y_size)
        self.right_c = Cell:new(self.x_pos + mid, self.y_pos, self.x_size - mid, self.y_size)
    else
        local lb = math.floor(self.y_size * 0.3)
        local hb = math.floor(self.y_size * 0.7)
        local mid = math.random(lb, hb)
        self.left_c = Cell:new(self.x_pos, self.y_pos, self.x_size, mid)
        self.right_c = Cell:new(self.x_pos, self.y_pos + mid, self.x_size, self.y_size - mid)
    end
    return true
end

function Cell:construct_list()
	local lst = {}
	if self:is_leaf() then
		lst[1] = self
		return lst
	end
	local lclst = self.left_c:construct_list()
	local rclst = self.right_c:construct_list()
	local cnt = 1
	for _, i in ipairs(lclst) do
		lst[cnt] = i
		cnt = cnt + 1
	end
	for _, i in ipairs(rclst) do
		lst[cnt] = i
		cnt = cnt + 1
	end
	return lst
end

function Cell:display()
    if self:is_leaf() then
        love.graphics.rectangle(
            "fill",
            self.x_pos * GRID_SIZE, self.y_pos * GRID_SIZE,
            self.x_size * GRID_SIZE, self.y_size * GRID_SIZE
        )
    else
        self.left_c:display()
        self.right_c:display()
    end
end

return Cell
