local conf = require "conf"
local Message = require "message"

local ui = {}

local function render_status (player)
    love.graphics.print("ARM:" .. player.armor, 0, 340)
	love.graphics.print("HP:" .. player.health, 0, 360)
    love.graphics.print("MP:" .. player.magic, 0, 380)
end

-- Draw the latest conf.MESSAGE_LINES messages, oldest at the top; newest at
-- the bottom so the most recent line always sits in a stable position.
local function render_messages()
    local lines = Message.recent(conf.MESSAGE_LINES)
    for i, entry in ipairs(lines) do
        local y = conf.MESSAGE_ORIGIN_Y + (i - 1) * conf.MESSAGE_LINE_HEIGHT
        local c = Message.color_of(entry)
        if c then love.graphics.setColor(c[1], c[2], c[3]) end
        love.graphics.print(entry.text, conf.MESSAGE_ORIGIN_X, y)
    end
    love.graphics.setColor(1, 1, 1)   -- leave white for the next drawer
end

ui.render = function (player)
    render_status(player)
    render_messages()
end


return ui
