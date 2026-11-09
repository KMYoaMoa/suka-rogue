-- Generic tick scheduler. It knows invokers, commands, and a clock interface;
-- it must not import Game, Player, Dungeon, Mob, combat, or UI modules.
--
-- Clock interface:
--   clock:get_tick()   -> current integer tick
--   clock:set_tick(n)  -> advance/set the tick
--   clock:is_stopped() -> waiting/dead; stop processing
--   clock:is_dead()    -> terminal; discard pending commands and do not advance
local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(clock)
    return setmetatable({
        schedule = {},
        queue = {},
        clock = clock,
    }, Scheduler)
end

function Scheduler:new_invoker(name)
    local invoker = { name = name }
    local invoker_schedule = self.schedule
    local invoker_queue = self.queue
    invoker.trigger = nil -- the owner must implement
    invoker.append_command = function (obj)
        invoker_queue[#invoker_queue + 1] = obj
    end
    invoker.reschedule = function (at)
        invoker_schedule[at] = invoker_schedule[at] or {}
        invoker_schedule[at][#invoker_schedule[at] + 1] = invoker
    end
    return invoker
end

function Scheduler:drain_queue()
    while #self.queue > 0 do
        if self.clock:is_dead() then
            for i = #self.queue, 1, -1 do self.queue[i] = nil end
            return
        end
        local cmd = table.remove(self.queue, 1)
        cmd.execute()
    end
end

function Scheduler:process()
    while not self.clock:is_stopped() do
        self:drain_queue()
        local tick = self.clock:get_tick()
        local slot = self.schedule[tick] or {}
        self.schedule[tick] = nil

        for _, invoker in ipairs(slot) do
            if self.clock:is_dead() then return end
            invoker.trigger()
            self:drain_queue()
        end

        if self.clock:is_dead() then return end
        self.clock:set_tick(tick + 1)
    end
end

function Scheduler:clear()
    for key in pairs(self.schedule) do self.schedule[key] = nil end
    for i = #self.queue, 1, -1 do self.queue[i] = nil end
end

function Scheduler:next_tick()
    local start = self.clock:get_tick()
    local limit = start + 1000
    for tick = start, limit do
        local slot = self.schedule[tick]
        if slot and #slot > 0 then return tick end
    end
    return nil
end

function Scheduler:is_scheduled(invoker, tick)
    if not tick then return false end
    for _, scheduled in ipairs(self.schedule[tick] or {}) do
        if scheduled == invoker then return true end
    end
    return false
end

return Scheduler
