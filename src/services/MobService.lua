local Mob              = require "models.mob.Mob"
local Item             = require "models.item.Item"
local Dungeon          = require "models.dungeon.Dungeon"
local DungeonService   = require "services.DungeonService"
local CommandService   = require "services.CommandService"
local MobAIService     = require "services.MobAIService"
local InventoryService = require "services.InventoryService"
local MessageService   = require "services.MessageService"
local GameState        = require "models.GameState"

local MobService = {}

-- A spawn is valid iff the tile is in bounds, passable, and free of another
-- occupant (including the player). Items may share the tile (drops do).
MobService.can_spawn_at = function (x, y)
    return DungeonService.is_free(x, y)
end

-- Public spawn interface.
--   type_name: a key of Mob.defs (unknown -> generic fallback)
--   x, y:      absolute tile position
--   room:      optional born room; stored as the mob's AI territory
-- Returns the mob instance, or nil if the position is invalid.
MobService.spawn = function (type_name, x, y, room)
    if not MobService.can_spawn_at(x, y) then return nil end

    local mob = Mob.new(type_name)
    mob.x, mob.y = x, y
    mob.ai.territory = room or DungeonService.room_at(x, y)

    -- Composition: the mob HAS equipment, built from the same Item registry.
    for slot, item_type in pairs(Mob.def_of(mob).equipment) do
        mob.equipped[slot] = Item.new(item_type)
    end

    -- Register with the tick scheduler. The trigger stays stable; the AI body
    -- is MobService.act.
    mob.invoker = CommandService.new_invoker("Mob:" .. Mob.name(mob))
    mob.invoker.trigger = function () MobService.act(mob) end
    mob.invoker.reschedule(GameState.ticks + Mob.def_of(mob).stats.speed)

    Dungeon.mobs[#Dungeon.mobs + 1] = mob
    return mob
end

-- Mob AI runs here. One action per scheduled mob turn; then reschedule.
MobService.act = function (mob)
    if mob.dead then return end
    MobAIService.act(mob)
    mob.invoker.reschedule(GameState.ticks + Mob.def_of(mob).stats.speed)
end

MobService.remove = function (mob)
    for i, m in ipairs(Dungeon.mobs) do
        if m == mob then table.remove(Dungeon.mobs, i); return end
    end
end

-- Kill interface: places drops on the mob's tile, marks it dead (so its
-- scheduled invoker becomes a no-op), and removes it from the map.
MobService.kill = function (mob)
    if mob.dead then return end
    mob.dead = true
    MessageService.add(string.format("The %s dies.", Mob.name(mob)), "good")
    for _, drop in ipairs(Mob.def_of(mob).drops) do
        local item = Item.new(drop.type)
        item.qty = drop.qty or 1
        InventoryService.place_item(item, mob.x, mob.y)
    end
    MobService.remove(mob)
end

return MobService