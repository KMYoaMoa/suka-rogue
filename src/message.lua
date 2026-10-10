-- Message: a small append-only log with typed, coloured entries.
-- Pure logic (no love.*): the caller draws `Message.recent(n)`.
local Message = {}

-- type name -> definition. Mirrors tile.lua's `defs` table.
--   color: {r, g, b} for love.graphics.setColor
local types = {
    info    = { color = {0.80, 0.80, 0.80} },   -- default / narration
    good    = { color = {0.30, 0.90, 0.30} },   -- healing, pickups
    combat  = { color = {0.95, 0.75, 0.20} },   -- hits, damage
    warning = { color = {0.95, 0.45, 0.10} },   -- danger, low HP
    bad     = { color = {0.90, 0.20, 0.20} },   -- death, critical failure
}
local DEFAULT_TYPE = "info"

local history = {}   -- ordered, oldest first

-- Append one message.
--   text: the line to show (build it with string.format at the call site)
--   type: a key of `types`; unknown/nil falls back to "info"
--   color: optional {r,g,b} overriding the type colour for this entry
Message.add = function (text, type, color)
    local t = types[type] and type or DEFAULT_TYPE
    history[#history + 1] = { text = text, type = t, color = color }
end

-- The last `n` entries, oldest first (n defaults to all of history).
Message.recent = function (n)
    if n == nil or n >= #history then return history end
    local out = {}
    local first = #history - n + 1
    for i = first, #history do out[#out + 1] = history[i] end
    return out
end

Message.count = function () return #history end

Message.clear = function () history = {} end

-- Colour an entry should be drawn in: explicit override, else its type's.
Message.color_of = function (entry)
    return entry.color or (types[entry.type] or types[DEFAULT_TYPE]).color
end

Message.types = types   -- exposed so future systems can add/recolour types

return Message