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
