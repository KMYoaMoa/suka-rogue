-- Dungeon object
local dungeon = {}

-- Get global config from main
local conf = require "conf"

dungeon.iterate = function (actions)
    for x = 0, conf.SIZE_X - 1, 1 do
        if actions.before then actions.before(x) end
		for y = 0, conf.SIZE_Y - 1, 1 do
    		if actions.during then actions.during(x, y) end
		end
		if actions.after then actions.after(x) end
	end
end

-- Initialize dungeon object
dungeon.init = function ()
    dungeon.iterate({
        before = function (x) dungeon[x] = {} end,
        during = function (x, y) dungeon.setTile("#", x, y) end
    })
    dungeon.iterate({ during = function (x, y)
        if x > 2 and x < 8 and y > 2 and y < 8 then
            dungeon[x][y] = "."
        end
    end })
end

-- Set tile for specific position
--  tile: tile object to be set
--  x, y: absolute coordinate
dungeon.setTile = function (tile, x, y)
    if conf.is_pos_valid(x, y) then
        dungeon[x][y] = tile
    end
end

dungeon.is_passable = function (x, y) return dungeon[x][y] == "." end

-- Return dungeon object
return dungeon
