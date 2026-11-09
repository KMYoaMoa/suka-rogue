
local InputHandler = {}

InputHandler.handle_move = function (key)
    local dx = 0
	local dy = 0
	if key == "down" or key == "j" then dy = 1
	elseif key == "up" or key == "k" then dy = -1
	elseif key == "left" or key == "h" then dx = -1
	elseif key == "right" or key == "l" then dx = 1
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

-- Structured intent for controllers. Keeps raw-key details out of the turn
-- controller while preserving the compatibility helpers above.
InputHandler.intent = function (key)
    local action = InputHandler.handle_action(key)
    if action then
        if action:match("^select") then
            return { type = "select", slot = tonumber(action:sub(7)) }
        end
        return { type = action }
    end

    local dx, dy = InputHandler.handle_move(key)
    if dx ~= 0 or dy ~= 0 then
        return { type = "move", dx = dx, dy = dy }
    end
    return nil
end

return InputHandler
