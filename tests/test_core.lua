local t = require "tests.support"
local Scheduler = require "core.scheduler"
local RNG = require "core.rng"
local Config = require "core.config"

t.test("core scheduler processes a slot and advances the clock without GameState", function ()
    local clock = {
        tick = 0,
        stopped = false,
        dead = false,
    }
    function clock:get_tick() return self.tick end
    function clock:set_tick(value) self.tick = value end
    function clock:is_stopped() return self.stopped end
    function clock:is_dead() return self.dead end

    local scheduler = Scheduler.new(clock)
    local invoker = scheduler:new_invoker("test")
    local calls = 0
    invoker.trigger = function ()
        calls = calls + 1
        clock.stopped = true
        invoker.reschedule(clock.tick + 1)
    end
    invoker.reschedule(0)

    scheduler:process()
    t.equal(calls, 1)
    t.equal(clock.tick, 1)
    t.equal(scheduler:next_tick(), 1)
    t.truthy(scheduler:is_scheduled(invoker, 1))

    scheduler:clear()
    t.equal(scheduler:next_tick(), nil)
end)

t.test("core scheduler stops on death without advancing the clock", function ()
    local clock = { tick = 0, stopped = false, dead = false }
    function clock:get_tick() return self.tick end
    function clock:set_tick(value) self.tick = value end
    function clock:is_stopped() return self.stopped end
    function clock:is_dead() return self.dead end

    local scheduler = Scheduler.new(clock)
    local invoker = scheduler:new_invoker("deadly")
    invoker.trigger = function ()
        clock.stopped = true
        clock.dead = true
    end
    invoker.reschedule(0)

    scheduler:process()
    t.equal(clock.tick, 0)
end)

t.test("core RNG is deterministic and supports the math.random shapes", function ()
    local a = RNG.new(1234)
    local b = RNG.new(1234)
    for _ = 1, 20 do
        t.equal(a:random(), b:random())
    end
    t.equal(RNG.new(1):random(1, 1), 1)
    local n = RNG.new(99):random(5)
    t.truthy(n >= 1 and n <= 5)
    local r = RNG.new(99):random()
    t.truthy(r >= 0 and r < 1)
end)

t.test("core config loads without a Game and validates bounds", function ()
    t.equal(Config.is_pos_valid(0, 0), true)
    t.equal(Config.is_pos_valid(Config.SIZE_X, 0), false)
    t.equal(Config.is_pos_valid(0, Config.SIZE_Y), false)
end)
