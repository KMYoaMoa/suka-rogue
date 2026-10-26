local conf           = require "conf"
local Player         = require "models.Player"
local Dungeon        = require "models.dungeon.Dungeon"
local DungeonService = require "services.DungeonService"
local MobService     = require "services.MobService"
local NpcService     = require "services.NpcService"
local MessageService = require "services.MessageService"

local CombatService = {}
local CombatCommands = {}

local DIRS4 = {
    {1, 0}, {-1, 0}, {0, 1}, {0, -1},
}

CombatService.targets    = {}   -- entities q would hit; also the view's highlight
CombatService.target_set = {}   -- "x:y" -> true

local function passable(x, y)
    return conf.is_pos_valid(x, y) and DungeonService.is_passable(x, y)
end

local function visible_targets()
    local out = {}
    local function add(list)
        for _, e in ipairs(list) do
            if not e.dead and DungeonService.getTile(e.x, e.y).visible then
                out[#out + 1] = e
            end
        end
    end
    add(Dungeon.mobs)
    add(Dungeon.npcs)
    return out
end

-- 4-direction, wall-blocked distances from the player. Creatures do not
-- block the BFS; only terrain does.
local function distances_from_player()
    local dist = {}
    local queue = { { Player.x, Player.y } }
    dist[Player.x .. ":" .. Player.y] = 0
    local head = 1
    while head <= #queue do
        local x, y = queue[head][1], queue[head][2]
        head = head + 1
        local d = dist[x .. ":" .. y]
        for _, dir in ipairs(DIRS4) do
            local nx, ny = x + dir[1], y + dir[2]
            local key = nx .. ":" .. ny
            if passable(nx, ny) and dist[key] == nil then
                dist[key] = d + 1
                queue[#queue + 1] = { nx, ny }
            end
        end
    end
    return dist
end

local function nearest_target(candidates, distances)
    local best, best_d
    for _, e in ipairs(candidates) do
        local d = distances[e.x .. ":" .. e.y]
        if d and (best_d == nil or d < best_d) then   -- strict: first wins ties
            best, best_d = e, d
        end
    end
    return best
end

local function melee_range()
    if Player.mode == "melee" then
        local weapon = Player.equipped.melee
        return (weapon and weapon.def.stats.range) or 1
    end
    return Player.unarmed_range or 1
end

-- Auto-fallback required by the clarified mode/equipment rules.
function CombatService.ensure_mode()
    if Player.mode == "melee" and not Player.equipped.melee then
        Player.mode = "unarmed"
        MessageService.add("You fall back to unarmed.", "info")
    elseif Player.mode == "ranged" and not Player.equipped.ranged then
        Player.mode = "unarmed"
        MessageService.add("You fall back to unarmed.", "info")
    end
end

-- Rebuild the cached list used by both q and CameraView.
function CombatService.update_targets()
    CombatService.ensure_mode()

    local candidates = visible_targets()
    local distances  = distances_from_player()
    local chosen     = {}

    if Player.mode == "ranged" then
        local target = nearest_target(candidates, distances)
        if target then chosen[1] = target end
    else
        local range = melee_range()
        for _, e in ipairs(candidates) do
            local d = distances[e.x .. ":" .. e.y]
            if d and d <= range then chosen[#chosen + 1] = e end
        end
    end

    CombatService.targets = chosen
    CombatService.target_set = {}
    for _, e in ipairs(chosen) do
        CombatService.target_set[e.x .. ":" .. e.y] = true
    end
end

function CombatService.is_target(x, y)
    return CombatService.target_set[x .. ":" .. y] == true
end

function CombatService.attack_power()
    local power = Player.attack or 0
    if Player.mode == "melee" then
        local weapon = Player.equipped.melee
        return power + ((weapon and weapon.def.stats.damage) or 0)
    elseif Player.mode == "ranged" then
        local weapon = Player.equipped.ranged
        return power + ((weapon and weapon.def.stats.damage) or 0)
    end
    return power
end

function CombatService.defense_of(target)
    if target.def.kind == "enemy" then
        return MobService.get_defense(target)
    end
    return 0                                        -- NPCs have no defense stat
end

function CombatService.hit(target, damage)
    target.health = target.health - damage
    local max_hp = target.def.stats.health
    local hp     = math.max(0, target.health)
    MessageService.add(string.format(
        "You hit the %s for %d damage (HP %d/%d).",
        target.name, damage, hp, max_hp), "combat")

    if target.health <= 0 then
        if target.def.kind == "enemy" then
            MobService.kill(target)                  -- drops + remove
        else
            NpcService.kill(target)                  -- dead record kept
        end
    end
end

-- --- commands (appended to the player invoker; each consumes one tick) ---

CombatCommands.switch_mode = function (mode)
    return { execute = function ()
        Player.mode = mode
    end }
end

CombatCommands.attack = function ()
    return { execute = function ()
        local targets = CombatService.targets
        if #targets == 0 then return end              -- guarded before enqueue

        if Player.mode == "ranged" then
            local target = targets[1]
            local weapon = Player.equipped.ranged
            local accuracy = (weapon and weapon.def.stats.accuracy) or 1
            accuracy = math.max(0, math.min(1, accuracy))
            if math.random() < accuracy then
                local damage = math.max(1, CombatService.attack_power()
                                         - CombatService.defense_of(target))
                CombatService.hit(target, damage)
            else
                MessageService.add(string.format("You miss the %s.", target.name), "combat")
            end
        else
            local power = CombatService.attack_power()
            for _, target in ipairs(targets) do     -- all targets, full damage each
                local damage = math.max(1, power - CombatService.defense_of(target))
                CombatService.hit(target, damage)
            end
        end
    end }
end

CombatService.commands = CombatCommands

return CombatService
