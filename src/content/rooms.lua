-- Room-type definitions are data-only. Weighted selection/assignment lives
-- in the dungeon generation module.
local ORDER = { "shop", "storeroom", "ruins" }
local defs = {
    shop = {
        name = "Shop", weight = 1,
        items = 0, item_pool = {},
        mobs  = 0, mob_pool  = {},
        npcs  = 1, npc_pool  = { "shopkeeper" },
        constructs = 1, construct_pool = { "shelf" },
    },
    storeroom = {
        name = "Storeroom", weight = 1,
        items = 2, item_pool = { "medkit", "sword", "plate", "coin", "pistol" },
        mobs  = 0, mob_pool  = {},
        npcs  = 0, npc_pool  = {},
        constructs = 0, construct_pool = {},
    },
    ruins = {
        name = "Ruins", weight = 8,
        items = 0, item_pool = {},
        mobs  = 2, mob_pool  = { "rat", "bat", "scavenger" },
        npcs  = 0, npc_pool  = {},
        constructs = 1, construct_pool = { "chest" },
    },
    empty = {
        name = "Empty", weight = 0,
        items = 0, item_pool = {},
        mobs  = 0, mob_pool  = {},
        npcs  = 0, npc_pool  = {},
        constructs = 0, construct_pool = {},
    },
}
return { ORDER = ORDER, defs = defs }
