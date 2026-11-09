-- Small deterministic RNG provider, independent of LÖVE and game modules.
-- Park-Miller (Lehmer) generator: 16807 * state mod 2147483647.
local RNG = {}
RNG.__index = RNG

local MODULUS = 2147483647
local MULTIPLIER = 16807

function RNG.new(seed)
    seed = tonumber(seed) or os.time()
    seed = math.floor(seed) % MODULUS
    if seed <= 0 then seed = seed + MODULUS - 1 end
    return setmetatable({ state = seed }, RNG)
end

function RNG:next()
    self.state = (self.state * MULTIPLIER) % MODULUS
    return self.state
end

-- Mirrors math.random:
--   rng:random()       -> [0, 1)
--   rng:random(n)      -> integer [1, n]
--   rng:random(m, n)   -> integer [m, n]
function RNG:random(a, b)
    local value = self:next() / MODULUS
    if a == nil then return value end
    if b == nil then return math.floor(value * a) + 1 end
    return math.floor(value * (b - a + 1)) + a
end

function RNG:randomseed(seed)
    local fresh = RNG.new(seed)
    self.state = fresh.state
end

return RNG
