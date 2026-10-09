# Keeping the Largest Connected Component — Correct Algorithm

> Follow-up to `docs/aigc/biome-system.md` · Branch: `biome-system`
>
> Problem: after `add_path`, the room graph (nodes = `map.cell_list`, edges = `cell.connected`, i.e. rooms actually joined by a corridor) can be split into several connected components — a geometric neighbour pair sometimes loses its corridor after shrinking (measured **4.40 %** of pairs, see `biome-system.md` §2). Before assigning biomes we want to **keep only the largest component** and drop every other room.
>
> Status: `src/map/MapFactory.lua` already has `prune_unreachable(map)` running right before `Biome:assign(map)` inside `create()`, and `dungeon.lua` / `player.lua` are untouched. What remains is to make the *keep-larger* logic correct.

---

## 1. Why the current logic is wrong

Current code:

```lua
local root = map.cell_list[1]
-- BFS from root, filling `reachable`
local out1, out2 = {}, {}            -- out1 = reached from root, out2 = the rest
...
if #out1 > #out2 then map.cell_list = out1
else map.cell_list = out2
end
```

This keeps the larger of **two** sets: the root's component vs. *the union of every other component*. That is only correct when the graph has **≤ 2 components**. Demonstrated with artificial component-size patterns (same BFS/`connected` semantics):

| Case (root in first component) | Current keeps | Correct largest | Kept set connected? |
|---|---|---|---|
| 2 components `{2, 5}` | 5 | 5 | ✅ |
| 2 components `{5, 2}` | 5 | 5 | ✅ |
| 3 components `{3, 4, 2}` | **6** (3+2 union) | 4 | ❌ **no** |
| 3 components `{4, 1, 4}` | **5** (1+4 union) | 4 | ❌ **no** |
| tie `{4, 4}` | 4 (arbitrary side) | 4 | ✅ but arbitrary |

Two distinct bugs:

1. **≥ 3 components**: the `else` branch keeps `out2`, which is a *union of several unrelated components* — the result is a `cell_list` that is itself **disconnected**, and it isn't the largest anything.
2. **Tie**: `#out1 > #out2` is false on a tie, so the root's own component is discarded for no reason.

(With exactly 2 components the code happens to be correct — which is probably why it's hard to catch. At current parameters, 30×15 / min_dim 3 / 8 rooms, the graph is effectively always a single component anyway (300-run observation in `biome-system.md` §2), so this is a **robustness fix**: it will matter once parameters change, e.g. more rooms, bigger `min_dimension`, or the "Cellular Automata After BSP" experiment in the README.)

---

## 2. The correct algorithm: find ALL components, keep the largest

No root is needed. BFS from every not-yet-seen cell to enumerate every component; keep the largest. Tie-break: **first-found wins** (`>` comparison) — deterministic, and ties are vanishingly rare anyway.

```lua
-- Return the cells of the largest connected component over `cell.connected`.
-- Ties: first-found component wins (`>` = strictly bigger replaces).
local function keep_largest_component(map)
    local seen, best = {}, {}
    for _, root in ipairs(map.cell_list) do
        if not seen[root] then
            local comp, stack = {}, { root }
            seen[root] = true
            while #stack > 0 do
                local c = table.remove(stack)
                comp[#comp + 1] = c
                for _, n in ipairs(c.connected) do
                    if not seen[n] then
                        seen[n] = true
                        stack[#stack + 1] = n
                    end
                end
            end
            if #comp > #best then best = comp end
        end
    end
    return best
end
```

Watch out for the classic off-by-time mistake: `comp` must collect **every visited node** (as above) — it is not the stack and not just the BFS "frontier". Complexity O(V + E), trivial for ~8 rooms.

---

## 3. Do these 3 things together — otherwise keep-largest leaves the map inconsistent

Replacing the prune body alone (keeping `map.cell_list = best`) is **not enough**. Three coordinated changes:

1. **`cell_list`** — keep only `best`, preserving the original relative order of surviving cells.

2. **`connected`** — rebuild every kept cell's `connected` list to contain **only kept cells**:
   ```lua
   local keep, best = {}, keep_largest_component(map)
   for _, c in ipairs(best) do keep[c] = true end
   for _, c in ipairs(map.cell_list) do
       if keep[c] then
           local conn = {}
           for _, n in ipairs(c.connected) do
               if keep[n] then conn[#conn + 1] = n end
           end
           c.connected = conn
       end
   end
   ```
   **Why this matters**: `Biome:assign` runs immediately after prune in `create()`. Its `available_neighbours(c)` only checks `if not assigned[n]` — a pruned room is *never* in `assigned` (it's not in `cell_list`), so with stale edges a biome cluster can grow into a **discarded room** and set `biome` on a room that no longer exists in the map. (Biomes must span only the kept graph.)

3. **`path_list`** — drop corridors whose endpoints are **not both kept**, otherwise `dungeon.lua` carves floating corridor stubs into solid wall. Corridors are anonymous rectangles today, so you need endpoint identity:
   - Recommended: tag endpoints at creation — in both branches of `add_path`, `Path:new(x, y, w, h)` becomes `Path:new(x, y, w, h, i, j)`; in `Path.lua`'s `new` store `new_obj.a = i; new_obj.b = j`. Then filter: `if keep[p.a] and keep[p.b]`.
   - Alternative without touching `add_path`: after pruning, keep a corridor iff its rect touches only kept rooms (rectangle checks against `cell_list`) — more code, no creation change. Not recommended.

Leave `h_neighbours` / `v_neighbours` alone — they are geometry metadata for future use (edge décor, doors); biomes and pruning use `connected` only.

---

## 4. Final order inside `MapFactory.create`

```
divide → construct_list → find_neighbours → shrink → add_path   (records `connected`)
      → keep_largest_component + cleanup (cell_list, connected, path_list)
      → Biome:assign(map)
```

Your current order is already correct — only the prune body and the three cleanup steps change. Consider renaming `prune_unreachable` → `keep_largest_component` (the semantics are no longer "unreachable from a root").

---

## 5. Spawn safety

`dungeon.lua` sets `dungeon.rooms = map.cell_list` (post-create), and `player.lua` spawns at `dungeon.rooms[1]`'s center. After keep-largest, `cell_list` is the surviving component **in original order**, so `rooms[1]` is always *some kept room* and the spawn stays valid — you never need to re-verify this. Just don't assume `rooms[1]` is still the original leftmost BSP leaf when it got pruned.

---

## 6. Headless verification script (the missing piece)

The room-graph code is pure Lua — test it without LÖVE. **Seed per iteration**, which makes every run both reproducible *and* varied, and removes any "same seed every run" ambiguity:

```lua
-- run from src/ with: lua check_map.lua
local MapFactory = require "map.MapFactory"

local failures, checks = {}, 0
for seed = 1, 1000 do
    math.randomseed(seed)                                  -- explicit, per-iteration seed
    local map = MapFactory.create(30, 15, 3, 8)

    -- A. post-prune cell_list is ONE connected component over `connected`
    -- B. every kept room has a biome string, and biome cluster sizes are 1..3
    -- C. biome clusters are contiguous: within one biome, the subgraph over
    --    `connected` restricted to same-biome rooms is connected
    -- D. every path in map.path_list is anchored to two KEPT rooms (no stubs)
    -- E. spawn tile = rooms[1] center is inside a kept room
end
print(("ok %d/%d"):format(checks - failures, checks))
```

Deterministic but varied: seed 42 always reproduces exactly map #42; different seeds explore the space. If you want the pruning path to *actually fire* during development, temporarily raise `num_rooms` or `min_dimension` (maps get denser/fragmented) and assert the kept size equals the largest component.

Expectation at current parameters: A–E pass with **zero** rooms ever removed (300-run observation: graph always single-component). If that ever changes, the largest-component code is what keeps `dungeon.rooms` honest.

---

## 7. TL;DR

Your pairwise `if #out1 > #out2` only works for ≤ 2 components; with ≥ 3 it keeps a disconnected union, and ties arbitrarily discard the root's component. Replace it with **enumerate all components by BFS (no root), keep the strictly-largest** — and in the same change also (1) filter `cell_list`, (2) rebuild `connected` on kept cells so `Biome:assign` can't reach dead rooms, (3) filter `path_list` corridors whose endpoints aren't both kept. Everything else in your `create()` order and in `dungeon.lua`/`player.lua` stays as-is; then write the seeded headless test above.