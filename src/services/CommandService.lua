local GameState = require "models.GameState"
-- Invoker: a trigger plus a reschedule helper. Invokers are owned by the
-- service that drives an actor (PlayerService, MobService), not by the actor
-- model itself.
local CommandService = {}

local schedule = {}   -- schedule[ticks] = list of invokers due at that tick
local queue    = {}   -- the global command queue

function CommandService.new_invoker(name)
    local invoker = {name = name}
    invoker.trigger = nil -- constraint: instance should implement
    invoker.append_command = function (obj)
        queue[#queue + 1] = obj
    end
    invoker.reschedule = function (at)
        schedule[at] = schedule[at] or {}
        schedule[at][#schedule[at] + 1] = invoker
    end
    return invoker
end

local function drain_queue()
    while #queue > 0 do
        if GameState.state == "dead" then
            queue = {}                               -- discard pending commands
            return
        end
        local cmd = table.remove(queue, 1)
        cmd.execute()
    end
end

CommandService.process = function ()
    while GameState.state ~= "waiting" and GameState.state ~= "dead" do
        drain_queue()                                -- commands from the last
        local slot = schedule[GameState.ticks] or {}
        schedule[GameState.ticks] = nil
        for _, invoker in ipairs(slot) do
            if GameState.state == "dead" then return end
            invoker.trigger()
            drain_queue()
        end
        if GameState.state == "dead" then return end
        GameState.ticks = GameState.ticks + 1                            -- next integer tick
    end
end

CommandService.reset = function ()
    schedule = {}
    queue = {}
end

-- First tick at or after the current clock that has any invoker. In normal
-- play this is the player's next turn (the player is scheduled every tick);
-- after init it is 1, even though GameState.ticks is still 0.
CommandService.next_tick = function ()
    local limit = GameState.ticks + 1000
    for t = GameState.ticks, limit do
        local slot = schedule[t]
        if slot and #slot > 0 then return t end
    end
    return nil
end

CommandService.is_scheduled = function (invoker, tick)
    if not tick then return false end
    for _, scheduled in ipairs(schedule[tick] or {}) do
        if scheduled == invoker then return true end
    end
    return false
end

return CommandService
