package.path = "./src/?.lua;./src/?/init.lua;" .. package.path

local support = {}

function support.equal(actual, expected, message)
    assert(actual == expected, (message or "values differ") ..
        string.format(" (expected %s, got %s)", tostring(expected), tostring(actual)))
end

function support.truthy(value, message)
    assert(value, message or "expected a truthy value")
end

function support.falsy(value, message)
    assert(not value, message or "expected a falsy value")
end

function support.test(name, fn)
    io.write("[TEST] " .. name .. " ... ")
    local ok, err = xpcall(fn, debug.traceback)
    if not ok then
        io.write("FAIL\n")
        error(err, 0)
    end
    io.write("ok\n")
end

-- Set up a fresh active Game with a deterministic generated map and an
-- initialized player. Tests that need a custom room can override the world
-- afterwards; this mirrors the pre-refactor shared test setup while giving
-- each test its own Game state bundle.
function support.with_clean_world(fn)
    local Game = require "game.Game"
    local DungeonGenerate = require "services.DungeonGenerate"
    local PlayerService = require "services.PlayerService"

    local game = Game.new(93017)
    game:activate()
    game:reset()
    DungeonGenerate.create(20, 3, game.rng)
    PlayerService.init()

    local ok, err = xpcall(fn, debug.traceback)
    if not ok then error(err, 0) end
end

function support.make_room(x, y, width, height)
    local Cell = require "models.dungeon.Cell"
    local Tile = require "models.dungeon.Tile"
    local Dungeon = require "models.dungeon.Dungeon"
    local DungeonService = require "services.DungeonService"

    local room = Cell:new(x, y, width, height)
    Dungeon.rooms = { room }
    for tx = x, x + width - 1 do
        for ty = y, y + height - 1 do
            local tile = Tile.new("floor")
            tile.biome = "BiomeA"
            tile.darkness = 1
            DungeonService.setTile(tile, tx, ty)
        end
    end
    return room
end

return support
