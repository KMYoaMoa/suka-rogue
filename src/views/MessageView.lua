local conf = require "conf"
local msg = require "services.MessageService"

local MessageView = {}

-- Draw the latest messages in the right HUD panel. Entries are wrapped to the
-- panel width; the newest entries are bottom-aligned inside a fixed area so
-- they never spill into the inventory block below.
MessageView.render = function ()
    local entries = msg.recent(conf.MESSAGE_LINES)
    local font = love.graphics.getFont()
    local width = conf.HUD_TEXT_WIDTH
    local line_h = conf.MESSAGE_LINE_HEIGHT
    local area_h = conf.MESSAGE_AREA_HEIGHT

    local draw = {}
    local used = 0
    for i = #entries, 1, -1 do
        local entry = entries[i]
        local _, lines = font:getWrap(entry.text, width)
        lines = lines or { entry.text }
        local h = math.max(1, #lines) * line_h
        if used + h > area_h then break end
        table.insert(draw, 1, { entry = entry, lines = lines, height = h })
        used = used + h
    end

    local x = conf.MESSAGE_ORIGIN_X
    local y = conf.MESSAGE_ORIGIN_Y + (area_h - used)
    for _, item in ipairs(draw) do
        local c = msg.color_of(item.entry)
        if c then love.graphics.setColor(c[1], c[2], c[3]) end
        for _, line in ipairs(item.lines) do
            love.graphics.print(line, x, y)
            y = y + line_h
        end
    end
    love.graphics.setColor(1, 1, 1)   -- leave white for the next drawer
end

return MessageView
