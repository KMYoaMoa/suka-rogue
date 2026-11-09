-- Compatibility adapter for the Phase 3 active-Game services. The actual
-- scheduler lives in core/scheduler and has no game-domain dependencies.
local Scheduler = require "core.scheduler"

local default_clock = {
    get_tick = function () return 0 end,
    set_tick = function () end,
    is_stopped = function () return true end,
    is_dead = function () return false end,
}

local active = Scheduler.new(default_clock)

local CommandService = {}

function CommandService.new_state(clock)
    return Scheduler.new(clock)
end

function CommandService.activate(scheduler)
    active = scheduler
end

function CommandService.new_invoker(name)
    return active:new_invoker(name)
end

function CommandService.process()
    active:process()
end

function CommandService.reset()
    active:clear()
end

function CommandService.next_tick()
    return active:next_tick()
end

function CommandService.is_scheduled(invoker, tick)
    return active:is_scheduled(invoker, tick)
end

return CommandService
