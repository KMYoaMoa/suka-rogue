local Path = {}

function Path:new(xpos, ypos, xsize, ysize)
    local new_obj = {}
    setmetatable(new_obj, self)
    self.__index = self
    new_obj.x_pos = xpos
    new_obj.y_pos = ypos
    new_obj.x_size = xsize
    new_obj.y_size = ysize
    return new_obj
end

function Path:x_pos_end()
    return self.x_pos + self.x_size - 1
end

function Path:y_pos_end()
    return self.y_pos + self.y_size - 1
end

function Path:display()
    love.graphics.rectangle(
        "line",
        self.x_pos * GRID_SIZE, self.y_pos * GRID_SIZE,
        self.x_size * GRID_SIZE, self.y_size * GRID_SIZE
    )
end

return Path
