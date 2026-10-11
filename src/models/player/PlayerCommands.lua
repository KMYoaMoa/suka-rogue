PlayerCommands.move = function (dx, dy)
    return { execute = function ()
            local new_x = player.x + dx
           	local new_y = player.y + dy
            local valid_move = conf.is_pos_valid(new_x, new_y) and dungeon.is_passable(new_x, new_y)
        	if valid_move then
        		player.x = new_x
        		player.y = new_y
        	end
        	camera.update(player.x, player.y)
        end
    }
end

return PlayerCommands
