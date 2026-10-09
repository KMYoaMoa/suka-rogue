
local Biome = {}

local BIOME_TYPES    = { "BiomeA", "BiomeB", "BiomeC", "BiomeD", "BiomeE" }
local MIN_BIOME_SIZE = 1
local MAX_BIOME_SIZE = 3

-- Assign a biome to every reachable room; returns dead rooms for the caller
-- (dungeon.lua) to seal in the tile grid.
function Biome:assign(map)
    local assigned = {}
    local active = map.cell_list

    local function available_neighbours(c)
        local out = {}
        for _, n in ipairs(c.connected) do
            if not assigned[n] then out[#out+1] = n end
        end
        return out
    end

    local biome_idx = 0
    for _, seed in ipairs(active) do
        if not assigned[seed] then
            biome_idx = biome_idx + 1
            local type = BIOME_TYPES[((biome_idx - 1) % #BIOME_TYPES) + 1]

            local cluster = { seed }
            assigned[seed] = true
            seed.biome = type

            -- grow while the cluster is under the rolled size and has candidates
            local size = math.random(MIN_BIOME_SIZE, MAX_BIOME_SIZE)
            while #cluster < size do
                local seen, candidates = {}, {}
                for _, m in ipairs(cluster) do
                    for _, n in ipairs(available_neighbours(m)) do
                        if not seen[n] then seen[n] = true; candidates[#candidates+1] = n end
                    end
                end
                if #candidates == 0 then break end   -- cluster ends smaller than rolled
                local pick = candidates[math.random(#candidates)]
                cluster[#cluster+1] = pick
                assigned[pick] = true
                pick.biome = type
            end
        end
    end
end

return Biome
