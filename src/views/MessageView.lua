local conf = require "conf"
local msg = require "services.MessageService"

local MessageView = {}

-- Draw the latest conf.MESSAGE_LINES messages, oldest at the top; newest at
-- the bottom so the most recent line always sits in a stable position.
MessageView.render = function ()
    local lines = msg.recent(conf.MESSAGE_LINES)
    for i, entry in ipairs(lines) do
        local y = conf.MESSAGE_ORIGIN_Y + (i - 1) * conf.MESSAGE_LINE_HEIGHT
        local c = msg.color_of(entry)
        if c then love.graphics.setColor(c[1], c[2], c[3]) end
        love.graphics.print(entry.text, conf.MESSAGE_ORIGIN_X, y)
    end
    love.graphics.setColor(1, 1, 1)   -- leave white for the next drawer
end

return MessageView
