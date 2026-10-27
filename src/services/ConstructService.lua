local Construct        = require "models.construct.Construct"
local Dungeon          = require "models.dungeon.Dungeon"
local DungeonService   = require "services.DungeonService"
local NpcService       = require "services.NpcService"

local ConstructService = {}

ConstructService.can_spawn_at = function (x, y)
    return DungeonService.is_free(x, y)
       and not DungeonService.is_entrance(x, y)
end

ConstructService.spawn = function (type_name, x, y, room)
    if not ConstructService.can_spawn_at(x, y) then return nil end
    local construct = Construct.new(type_name)
    construct.x, construct.y, construct.room = x, y, room
    Dungeon.constructs[#Dungeon.constructs + 1] = construct
    return construct
end

-- Condition registry: requirement NAME -> checker(construct) -> boolean.
-- The draft requires only the interface; these two checks are trivial and
-- named explicitly. Skill/item checks are out of scope and are added here
-- when their systems exist.
ConstructService.conditions = {
    npc_alive_in_room = function (construct)
        return NpcService.alive_in_room(construct.room)
    end,
    npc_dead_in_room = function (construct)
        return NpcService.dead_in_room(construct.room)
    end,
    -- has_skill = ...  (out of scope)
    -- holds_item = ... (out of scope)
}

-- The usability query. Unknown requirements fail closed, so adding a name to
-- a def before implementing its checker can never accidentally allow use.
ConstructService.can_use = function (construct)
    local requirements = Construct.def_of(construct).requires or {}
    for _, requirement in ipairs(requirements) do
        local check = ConstructService.conditions[requirement]
        if not check or not check(construct) then return false end
    end
    return true
end

return ConstructService
