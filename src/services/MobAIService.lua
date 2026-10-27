local conf               = require "conf"
local Player             = require "models.Player"
local Mob                = require "models.mob.Mob"
local Dungeon            = require "models.dungeon.Dungeon"
local DungeonService     = require "services.DungeonService"
local VisionService      = require "services.VisionService"
local NpcService         = require "services.NpcService"
local PlayerStatsService = require "services.PlayerStatsService"
local MessageService     = require "services.MessageService"

local MobAIService = {}
local MobCommands  = {}

local DIRS4 = { {1,0}, {-1,0}, {0,1}, {0,-1} }

local function key(x, y) return x .. ":" .. y end

local function manhattan(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

local function passable(x, y)
    return conf.is_pos_valid(x, y) and DungeonService.is_passable(x, y)
end

local function in_room(room, x, y)
    if not room then return true end            -- no territory => no restriction
    return x >= room.x_pos and x <= room:x_pos_end()
       and y >= room.y_pos and y <= room:y_pos_end()
end

-- Terrain BFS distances (walls block; occupants ignored). Used only to pick
-- the nearest visible NPC; movement pathing below respects occupancy.
local function terrain_distances(mob)
    local dist = { [key(mob.x, mob.y)] = 0 }
    local queue = { {mob.x, mob.y} }
    local head = 1
    while head <= #queue do
        local x, y = queue[head][1], queue[head][2]; head = head + 1
        local d = dist[key(x, y)]
        for _, dir in ipairs(DIRS4) do
            local nx, ny = x + dir[1], y + dir[2]
            local k = key(nx, ny)
            if passable(nx, ny) and dist[k] == nil then
                dist[k] = d + 1
                queue[#queue + 1] = { nx, ny }
            end
        end
    end
    return dist
end

local function select_target(mob, visible)
    if visible[key(Player.x, Player.y)] then return Player end

    local candidates = {}
    for _, npc in ipairs(Dungeon.npcs) do
        if not npc.dead and visible[key(npc.x, npc.y)] then
            candidates[#candidates + 1] = npc
        end
    end
    if #candidates == 0 then return nil end

    local dist = terrain_distances(mob)
    local best, best_d
    for _, npc in ipairs(candidates) do
        local d = dist[key(npc.x, npc.y)]
        if d and (best_d == nil or d < best_d) then   -- strict: list order wins ties
            best, best_d = npc, d
        end
    end
    return best
end

-- Returns dx, dy for the first step toward (gx, gy), or nil.
-- Intermediate tiles must be passable and unoccupied. The goal may be
-- occupied only when allow_goal_occupied is true (pursuing a player/NPC).
local function path_step(mob, gx, gy, allow_goal_occupied)
    local start_k = key(mob.x, mob.y)
    local goal_k  = key(gx, gy)
    if start_k == goal_k then return nil end

    local parent = { [start_k] = false }
    local queue  = { {mob.x, mob.y} }
    local head   = 1

    while head <= #queue do
        local x, y = queue[head][1], queue[head][2]; head = head + 1
        local k = key(x, y)

        if k == goal_k then
            local cur = k
            while parent[cur] and parent[cur] ~= start_k do
                cur = parent[cur]
            end
            if parent[cur] ~= start_k then return nil end
            local cx, cy = cur:match("^(%d+):(%d+)$")
            return tonumber(cx) - mob.x, tonumber(cy) - mob.y
        end

        for _, d in ipairs(DIRS4) do
            local nx, ny = x + d[1], y + d[2]
            local nk = key(nx, ny)
            if parent[nk] == nil and passable(nx, ny) then
                local is_goal = (nk == goal_k)
                local blocked = DungeonService.occupant_at(nx, ny) ~= nil
                if not blocked or (is_goal and allow_goal_occupied) then
                    parent[nk] = k
                    queue[#queue + 1] = { nx, ny }
                end
            end
        end
    end
    return nil
end

-- First step toward any free tile inside `room`, or nil.
local function path_step_to_room(mob, room)
    if not room then return nil end
    local start_k = key(mob.x, mob.y)
    local parent = { [start_k] = false }
    local queue  = { {mob.x, mob.y} }
    local head   = 1

    while head <= #queue do
        local x, y = queue[head][1], queue[head][2]; head = head + 1
        local k = key(x, y)

        if k ~= start_k and in_room(room, x, y) and DungeonService.is_free(x, y) then
            local cur = k
            while parent[cur] and parent[cur] ~= start_k do
                cur = parent[cur]
            end
            if parent[cur] ~= start_k then return nil end
            local cx, cy = cur:match("^(%d+):(%d+)$")
            return tonumber(cx) - mob.x, tonumber(cy) - mob.y
        end

        for _, d in ipairs(DIRS4) do
            local nx, ny = x + d[1], y + d[2]
            local nk = key(nx, ny)
            if parent[nk] == nil and passable(nx, ny)
               and DungeonService.occupant_at(nx, ny) == nil then
                parent[nk] = k
                queue[#queue + 1] = { nx, ny }
            end
        end
    end
    return nil
end

local function start_wander(mob)
    local ai = mob.ai
    ai.state = "wander"
    ai.wait = 2
    ai.steps_left = 0
    ai.dir = nil
    ai.target = nil
    ai.last_seen = nil
end

local function start_patrol(mob)
    local ai = mob.ai
    ai.state = "patrol"
    ai.wait = 2
    ai.steps_left = 0
    ai.dir = nil
    ai.patrol_loops = 2
    ai.target = nil
    ai.last_seen = nil
end

local function start_return(mob)
    local ai = mob.ai
    ai.state = "return"
    ai.wait = 0
    ai.steps_left = 0
    ai.dir = nil
end

-- One wander/patrol action. Returns "wait", "move", or "loop".
-- "loop" means the current loop ended (3 steps or interruption); wait is
-- already reset to 2 for the next loop.
local function wander_act(mob, territory_only)
    local ai = mob.ai
    if ai.wait > 0 then
        ai.wait = ai.wait - 1
        return "wait"
    end

    if ai.steps_left <= 0 then
        ai.dir = DIRS4[math.random(#DIRS4)]
        ai.steps_left = 3
    end

    local nx, ny = mob.x + ai.dir[1], mob.y + ai.dir[2]
    local outside = territory_only and not in_room(ai.territory, nx, ny)
    if not DungeonService.is_free(nx, ny) or outside then
        ai.dir, ai.steps_left, ai.wait = nil, 0, 2
        return "loop"                                  -- interrupted
    end

    mob.invoker.append_command(MobCommands.move(mob, ai.dir[1], ai.dir[2]))
    ai.steps_left = ai.steps_left - 1
    if ai.steps_left <= 0 then
        ai.dir, ai.wait = nil, 2
        return "loop"                                  -- completed
    end
    return "move"
end

local function patrol_act(mob)
    local event = wander_act(mob, false)               -- territory lifted
    if event == "loop" then
        mob.ai.patrol_loops = mob.ai.patrol_loops - 1
        if mob.ai.patrol_loops <= 0 then start_return(mob) end
    end
end

local function return_act(mob)
    local ai = mob.ai
    if in_room(ai.territory, mob.x, mob.y) then
        start_wander(mob)                              -- aggro ends
        return
    end
    local dx, dy = path_step_to_room(mob, ai.territory)
    if dx then mob.invoker.append_command(MobCommands.move(mob, dx, dy)) end
end

-- --- commands (one per mob turn) ---

MobCommands.move = function (mob, dx, dy)
    return { execute = function ()
        local nx, ny = mob.x + dx, mob.y + dy
        if DungeonService.is_free(nx, ny) then
            mob.x, mob.y = nx, ny
        end
    end }
end

MobCommands.attack = function (mob, target)
    return { execute = function ()
        if target == Player then
            PlayerStatsService.apply_damage(Mob.attack_of(mob), Mob.name(mob))
        else
            if target.dead then return end
            local damage = Mob.attack_of(mob)
            target.health = math.max(0, target.health - damage)
            MessageService.add(string.format(
                "The %s hits the %s for %d (HP %d/%d).",
                Mob.name(mob), target.name, damage,
                target.health, target.def.stats.health), "combat")
            if target.health <= 0 then
                NpcService.kill(target)
                start_patrol(mob)                      -- draft: kill NPC -> patrol
            end
        end
    end }
end

function MobAIService.act(mob)
    if mob.dead then return end
    local ai = mob.ai
    local visible = VisionService.compute_visible(mob.x, mob.y, conf.VISION_START)
    local target = select_target(mob, visible)

    if target then
        ai.state = "pursue"
        ai.target = target
        ai.last_seen = { x = target.x, y = target.y }
        ai.patrol_loops = 0
        if manhattan(mob, target) == 1 then
            mob.invoker.append_command(MobCommands.attack(mob, target))
        else
            local dx, dy = path_step(mob, target.x, target.y, true)
            if dx then
                mob.invoker.append_command(MobCommands.move(mob, dx, dy))
            end
        end
        return
    end

    -- No visible target: finish pursuit of the last-seen position.
    if ai.target and ai.target.dead then
        ai.target = nil
        start_patrol(mob)
        return
    end

    if ai.state == "pursue" then
        if not ai.last_seen then start_patrol(mob); return end
        local lx, ly = ai.last_seen.x, ai.last_seen.y
        if (mob.x == lx and mob.y == ly) or manhattan(mob, ai.last_seen) <= 1 then
            start_patrol(mob)
            return
        end
        local dx, dy = path_step(mob, lx, ly, false)
        if dx then
            mob.invoker.append_command(MobCommands.move(mob, dx, dy))
        else
            start_patrol(mob)                          -- last seen unreachable
        end
        return
    end

    if ai.state == "patrol" then
        patrol_act(mob)
    elseif ai.state == "return" then
        return_act(mob)
    else
        wander_act(mob, true)                          -- normal wander
    end
end

return MobAIService
