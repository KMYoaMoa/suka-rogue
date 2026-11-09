-- Public facade for the dungeon/map feature module. Lazy loading keeps map
-- model consumers from eagerly pulling generation/content dependencies.
local paths = {
    Dungeon = "modules.dungeon.model.Dungeon",
    Tile = "modules.dungeon.model.Tile",
    Cell = "modules.dungeon.model.Cell",
    Map = "modules.dungeon.model.Map",
    Path = "modules.dungeon.model.Path",
    Palette = "modules.dungeon.model.Palette",
    Service = "modules.dungeon.DungeonService",
    Generator = "modules.dungeon.generation.DungeonGenerate",
    Biome = "modules.dungeon.generation.Biome",
    RoomType = "modules.dungeon.generation.RoomType",
}

local facade = {}
setmetatable(facade, {
    __index = function (_, key)
        local path = paths[key]
        if not path then return nil end
        local module = require(path)
        rawset(facade, key, module)
        return module
    end,
})

return facade
