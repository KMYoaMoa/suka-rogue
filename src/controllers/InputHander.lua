
local InputHandler = {}

InputHandler.handle_move = function (key)
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

InputHandler.handle_action = function (key)
    if key == "g" then return "pickup"
    elseif key == "d" then return "drop"
    elseif key == "i" then return "inventory_toggle"
    elseif key == "e" then return "equip"
    elseif key == "u" then return "use"
    elseif key == "z" then return "melee_mode"
    elseif key == "x" then return "ranged_mode"
    elseif key == "c" then return "unarmed_mode"
    elseif key == "q" then return "attack"
    elseif key >= "1" and key <= "9" then return "select" .. key   -- slot 1..9
    end
    return nil
end

return InputHandler
