
local input = {}

input.handle_move = function (key)
    local dx = 0
	local dy = 0
	if key == "down" or key == "j" then dy = 1
	elseif key == "up" or key == "k" then dy = -1
	elseif key == "left" or key == "h" then dx = -1
	elseif key == "right" or key == "l" then dx = 1
	elseif key == "y" then dx = -1; dy = -1
	elseif key == "u" then dx = 1; dy = -1
	elseif key == "b" then dx = -1; dy = 1
	elseif key == "n" then dx = 1; dy = 1
	end
	return dx, dy
end

return input
