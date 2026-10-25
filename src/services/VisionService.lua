local conf           = require "conf"
local Player         = require "models.Player"
local DungeonService = require "services.DungeonService"
local Tile           = require "models.dungeon.Tile"

local VisionService = {}

-- Four directions only: vision does not travel diagonally.
local DIRS4 = {
    {1, 0}, {-1, 0}, {0, 1}, {0, -1},
}

local function decay_at(tile)
    -- darkness 0 means "fully lit" (no decay). Negative safety clamp only;
    -- `best` below still prevents infinite traversal when decay is 0.
    return math.max(0, tile.darkness or conf.CORRIDOR_DARKNESS)
end

local function mark_visible(tile, light)
    tile.visible = true
    tile.discovered = true
    if light > (tile.light or 0) then tile.light = light end
end

local function clear_visibility()
    DungeonService.iterate({
        during = function (x, y)
            local t = DungeonService.getTile(x, y)
            t.visible = false
            t.light   = 0
            -- t.discovered persists
        end,
    })
end

-- Recompute the player's FOV and update tile states.
-- Call once per processed turn (and once after game init).
VisionService.update = function ()
    clear_visibility()

    local px, py = Player.x, Player.y
    if not conf.is_pos_valid(px, py) then return end

    local buckets = {}   -- buckets[remaining] = { {x, y}, ... }
    local best    = {}   -- "x:y" -> highest remaining vision seen

    local function push(x, y, remaining)
        if remaining <= 0 then return end            -- draft: <= 0 is invisible
        local key = x .. ":" .. y
        if (best[key] or 0) >= remaining then return end
        best[key] = remaining
        buckets[remaining] = buckets[remaining] or {}
        local b = buckets[remaining]
        b[#b + 1] = { x, y }
    end

    push(px, py, conf.VISION_START)

    for remaining = conf.VISION_START, 1, -1 do
        local bucket = buckets[remaining]
        if bucket then
            -- while-loop, not for: a zero-darkness tile pushes neighbours
            -- into this same bucket, and they must still be processed.
            local i = 1
            while i <= #bucket do
                local x, y = bucket[i][1], bucket[i][2]
                i = i + 1

                if best[x .. ":" .. y] == remaining then
                    local tile = DungeonService.getTile(x, y)
                    mark_visible(tile, remaining)

                    if not Tile.opaque(tile) then
                        for _, d in ipairs(DIRS4) do
                            local nx, ny = x + d[1], y + d[2]
                            if conf.is_pos_valid(nx, ny) then
                                local next_tile = DungeonService.getTile(nx, ny)
                                push(nx, ny, remaining - decay_at(next_tile))
                            end
                        end
                    elseif tile.type == "wall" then
                        -- Special wall handling: allow exactly one propagation
                        -- hop to adjacent walls (no extra decay). Room corners
                        -- are only diagonally adjacent to floor tiles, so
                        -- without this hop they would never be revealed.
                        for _, d in ipairs(DIRS4) do
                            local nx, ny = x + d[1], y + d[2]
                            if conf.is_pos_valid(nx, ny) then
                                local next_tile = DungeonService.getTile(nx, ny)
                                if next_tile.type == "wall" then
                                    mark_visible(next_tile, remaining)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- The draft's three states, derived from the tile's per-cell flags.
VisionService.state_of = function (tile)
    if not tile then return "undiscovered" end
    if tile.visible then return "visible" end
    if tile.discovered then return "discovered" end
    return "undiscovered"
end

return VisionService
