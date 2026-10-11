local GameState = require "models.GameState"
-- Invoker: turns input into commands. The player holds an instance of this
-- table (composition: the player HAS an invoker). An invoker carries a
-- reference to the thing it moves (target = the player table).
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
        local cmd = table.remove(queue, 1)
        cmd.execute()
    end
end

CommandService.process = function ()
    while GameState.state ~= "waiting" do
        drain_queue()                                -- commands from the last
        local slot = schedule[GameState.ticks] or {}
        schedule[GameState.ticks] = nil
        for i, invoker in ipairs(slot) do
            invoker.trigger()
            drain_queue()                            -- (future mobs: their own
        end                                          --  command instead)
        GameState.ticks = GameState.ticks + 1                            -- next integer tick
    end
end

return CommandService
