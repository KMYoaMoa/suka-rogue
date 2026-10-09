# BSP Dungeon Generation — Integration Plan

> Branch: `bsp-integrate` · Status: experiment done, integration TODO (README Implementation Plan)
>
> Goal: bring `experiments/BSP-Dungeon-Generation` into `src/` with the **smallest possible modification** to the main game code.

---

## 1. Where we are now

### The main project (`src/`)

The game represents the dungeon as a **dense 2-D tile grid** — a Lua table of strings:

| File | Role |
|---|---|
| `conf.lua` | `SIZE_X = 10`, `SIZE_Y = 10`, `TILE_SIZE = 32`; `is_pos_valid(x, y)` bounds check |
| `dungeon.lua` | owns the grid `dungeon[x][y]`; tile chars: `"#"` = wall, `"."` = floor; `iterate()`, `setTile()`, `is_passable()`. `init()` currently hard-codes one 6×6 room etched into a 10×10 grid |
| `player.lua` | spawns at hard-coded `(4, 4)`; `move()` = bounds check + `dungeon.is_passable()` |
| `game.lua` | `render()` prints every tile as a text char (with a 2× zoom transform); input → `player.move` |
| `main.lua` | LÖVE callbacks (`love.load` → `game.init`) |

Key property: **the grid is the single source of truth** — rendering iterates it, collision queries it, the player lives in it. Everything downstream assumes `dungeon[x][y]` exists and is a passable/blocked tile.

### The BSP experiment (`experiments/BSP-Dungeon-Generation/`)

An **object-oriented, rectangle-based** model built on a binary tree:

| File | Role |
|---|---|
| `Cell.lua` | tree node: `x_pos/y_pos/x_size/y_size`, `left_c/right_c`, neighbour lists. `divide(min_dimension)` splits the larger axis at a random 30–70% point; `construct_list()` flattens leaves |
| `Map.lua` | container: `root`, `num_rooms`, `min_dimension`, `cell_list` (leaf rooms), `path_list` (corridors) |
| `Path.lua` | corridor rectangle: position + size |
| `MapFactory.lua` | driver. `create(w, h, min_dimension, num_rooms)` runs: `divide → construct_list → find_neighbours → shrink → add_path`. Has a safety cap `MAX_ATTEMPTS_PER_ROOM = 50` (prints a warning if rooms can't all fit) |

Pipeline details that matter for integration:

- **1-based inclusive coordinates**: root starts at `(1, 1)`; `x_pos_end() = x_pos + x_size - 1`. A room covers the inclusive range `[x_pos, x_pos_end] × [y_pos, y_pos_end]`.
- **Shrinking**: each room is shrunk to a random 60–90% of its size, centered; rooms are then separated by gaps of 1–3 tiles.
- **Corridors**: one `Path` per adjacent-leaf pair, computed *after* shrinking, spanning the gap between the shrunk rooms.
- **No LÖVE dependency in the logic** — the only `love.*` calls are the `display()` methods (experiment-only; they draw rects scaled by a global `GRID_SIZE = 16`). Everything else is pure Lua.
- **Coordinates are in tiles/cells, not pixels.** `GRID_SIZE` is purely a display scale for the experiment window; the main project's `TILE_SIZE` plays the same role.

### Sanity check performed on this code (before writing this doc)

Ran the real `MapFactory` 20 times with the proposed parameters `create(40, 22, 3, 8)`, rasterized into a `40×22` grid, and flood-filled from the first room center:

- always exactly 8 leaf rooms, 10–14 corridors, ~400–580 floor tiles;
- **100% of runs fully connected** (flood fill reached every floor tile).

So connectivity holds in practice for these parameters (60–90% centered shrinking guarantees corridor overlap between shrunk adjacent rooms). This is an empirical check, not a proof — a flood-fill assertion is easy to add later if we ever want a guarantee.

---

## 2. What has to be reconciled

1. **Representation mismatch**: experiment outputs *rectangles* (`cell_list` + `path_list`); the game needs a *tile grid*. → Rasterize: everything inside a room or corridor becomes `"."`, everything else stays `"#"`.
2. **Map size**: the game is hard-coded to 10×10, which is too small for BSP. `40×22` fits the 1280×720 window exactly at `TILE_SIZE = 32` (40×32 = 1280, 22×32 = 704 ≤ 720). `conf.SIZE_X/SIZE_Y` should become the map size and be passed straight into `MapFactory.create`.
3. **1-based vs 0-based**: `MapFactory` roots at `(1,1)`, the grid is indexed `0..SIZE_X-1`. The last column/row of rooms can reach index `SIZE_X` — clamp when rasterizing (or rely on `setTile`'s `is_pos_valid` guard), and accept that row/col 0 ends up as a wall border. Harmless.
4. **Player spawn**: hard-coded `(4,4)` would land in a wall on a generated map. → Spawn at a room center.
5. **`require` paths**: the experiment files use `require "Cell"` etc. If copied flat into `src/`, paths resolve unchanged (the game root is on LÖVE's require path). A subdirectory would force renaming requires to e.g. `"bsp.Cell"`.
6. **Experiment leftovers**: `GRID_SIZE` global and the `display()` methods are dead weight in `src/` — harmless to keep, slightly cleaner to delete.
7. **Reproducibility**: `math.random` is unseeded. For a roguelike that's fine (fresh map each run); if you ever want reproducible maps for debugging, seed explicitly.

---

## 3. Options

### Option A — Rasterize BSP output onto the existing dense grid *(recommended)*

Copy `Cell/Map/Path/MapFactory.lua` into `src/` **unchanged**, then add a "generate + rasterize" step in `dungeon.init()`; tweak `conf.lua` sizes and the player spawn.

- **Touched files**: 4 files copied (content untouched), edits in `dungeon.lua`, `conf.lua`, a few lines in `player.lua`. `game.lua` and `player.move()` are **untouched**.
- **Pros**: smallest blast radius; grid stays the single source of truth for rendering, collision and spawn; the rest of the README roadmap (Tile System, Item/Mob Spawn, Biome System) builds naturally on a tile grid; room metadata can be *kept* on the dungeon object (2 lines) for later systems.
- **Cons**: the BSP "rooms as objects" runtime model is not exercised unless we also stash `cell_list` (cheap, see §4 step 3).

### Option B — Keep the OOP map as the runtime dungeon representation

`game.render()` draws rooms/corridors from `cell_list`/`path_list`; collision = point-in-rectangle tests against those lists instead of a grid.

- **Pros**: rooms stay first-class objects (matches the experiment note "assign types to rooms"); rendering is a handful of `love.graphics.rectangle` calls.
- **Cons**: rewrites `dungeon.lua` semantics, `game.lua` rendering **and** player collision; future tile-based systems (tiles, item/mob spawning on grid cells) would have to be re-implemented against a different model; by far the largest diff. High maintenance cost for a feature the rest of the roadmap doesn't assume.

### Option C — Modify the experiment code in place to write the grid directly

(e.g. make `Map`/`Path` fill a grid during generation instead of staying pure data.)

- **Pros**: no adapter layer.
- **Cons**: mutates "done" experiment code; couples pure data classes with grid/tile concerns; not materially less work than A. Least clean.

### Comparison

| | A (rasterize to grid) | B (OOP runtime map) | C (grid inside experiment) |
|---|---|---|---|
| Main-code edits | 3 small files | 3 files, large rewrites | 2 files + experiment files |
| Renderer untouched | ✅ | ❌ | ✅ |
| Player move untouched | ✅ | ❌ | ✅ |
| Rooms stay queryable | ✅ (via `cell_list` stash) | ✅ | ⚠️ (loses tree/rooms) |
| Ready for Tile/Item/Mob systems | ✅ | ❌ | ✅ |
| Total diff size | smallest | largest | medium |

---

## 4. Recommended plan — Option A, step by step

### Step 1 — Copy the BSP modules into `src/` (flat, unchanged)

```bash
cp experiments/BSP-Dungeon-Generation/{Cell,Map,Path,MapFactory}.lua src/
```

Keep them flat so the internal `require "Cell" / "Map" / "Path"` keep resolving.
*Optional cleanup*: delete the three `display()` methods and the global `GRID_SIZE = 16` from the copied files (they are experiment-only cosmetics and reference `love.graphics` / the old scale). Nothing in `src/` will call them either way.

### Step 2 — `conf.lua`: grow the map and keep it the single source of truth

```lua
conf.SIZE_X = 40   -- was 10 (fits 1280x720 at TILE_SIZE=32)
conf.SIZE_Y = 22   -- was 10
```

`is_pos_valid` and `TILE_SIZE` stay as they are. `conf.SIZE_X/Y` now define the generated map size; pass them straight into `MapFactory.create` in Step 3 so they can't drift apart.

### Step 3 — `dungeon.lua`: replace `init()` with generate + rasterize

```lua
local dungeon = require "dungeon"
local conf    = require "conf"
local MapFactory = require "MapFactory"

dungeon.init = function ()
    -- 1) fill the grid with walls
    dungeon.iterate({
        before = function (x) dungeon[x] = {} end,
        during = function (x, y) dungeon.setTile("#", x, y) end
    })

    -- 2) generate a BSP map (parameters validated on 40x22: min_dim 3, 8 rooms)
    local map = MapFactory.create(conf.SIZE_X, conf.SIZE_Y, 3, 8)

    -- 3) carve rooms (inclusive x_pos .. x_pos_end; clamp 1-based -> 0-based)
    for _, c in ipairs(map.cell_list) do
        for x = c.x_pos, math.min(c:x_pos_end(), conf.SIZE_X - 1) do
            for y = c.y_pos, math.min(c:y_pos_end(), conf.SIZE_Y - 1) do
                dungeon.setTile(".", x, y)
            end
        end
    end

    -- 4) carve corridors
    for _, p in ipairs(map.path_list) do
        for x = p.x_pos, math.min(p:x_pos_end(), conf.SIZE_X - 1) do
            for y = p.y_pos, math.min(p:y_pos_end(), conf.SIZE_Y - 1) do
                dungeon.setTile(".", x, y)
            end
        end
    end

    -- 5) keep the room structure around for later systems (biome/item/mob spawn)
    dungeon.rooms = map.cell_list
    dungeon.paths = map.path_list
end
```

Notes:
- `setTile` already discards out-of-range tiles via `is_pos_valid`, so the `math.min` clamps are belt-and-braces — keep them for clarity.
- Result: row 0 / column 0 stay walls (1-based vs 0-based border) — visually an outer wall, no gameplay impact.
- Tuning knobs (all currently hard-coded inside the experiment files, fine to leave for now, or hoist into `conf` later): `MapFactory.create(..., min_dimension, num_rooms)`, `shrink`'s 0.6–0.9 factors.

### Step 4 — `player.lua`: spawn at a room center

```lua
player.init = function ()
    local rooms = dungeon.rooms or {}
    local r = rooms[1]                          -- or rooms[math.random(#rooms)]
    player.setPosition(
        r.x_pos + math.floor(r.x_size / 2),
        r.y_pos + math.floor(r.y_size / 2))
    -- stats unchanged ...
end
```

With `min_dimension = 3` even the smallest room has an interior tile at its center (`floor(3/2) = 1`), so the spawn is always inside the room and passable.

### Step 5 — Test

```bash
love .   # from repo root
```

**Checklist**:
- [ ] `love.load`/`game.init` runs without errors (no module-not-found — confirms flat `require`s resolve).
- [ ] Layout is different on each launch (unseeded `math.random`).
- [ ] Player appears inside a room, never inside a wall.
- [ ] Every room is reachable: walk the whole map (or re-run the flood-fill script used in §1 — it found 100% connectivity over 20 runs).
- [ ] No `MapFactory: created X of Y requested rooms` warning spam (it prints once at most, and only when the requested room count doesn't fit the map — reduce `num_rooms` if you see it).
- [ ] Map fits the window (40×22 at TILE_SIZE=32 fills it exactly).

---

## 5. Afterwards (future roadmap hooks, not part of this integration)

- **Item / Mob Spawn System** — spawn in `dungeon.rooms[*]` centers (optionally farthest from the player's room), away from corridors.
- **Biome System** — attach a `type` field to each entry of `dungeon.rooms` (exactly the "assign types to rooms" extra step mentioned in the experiment's own `BSP-Dungeon-Generation.md`). The room table is already kept on the dungeon object.
- **Tile System** — when the grid stops being strings and becomes tile objects, only the rasterizer in Step 3 and `is_passable`/renderer change; the BSP modules themselves stay pure geometry.
- **Seed support** — wrap map generation with an explicit seed (`love.math.randomseed` / custom RNG) once you need reproducible runs for debugging.

---

## 6. TL;DR

**Recommended: Option A.** Copy the 4 experiment Lua files into `src/` unchanged, rasterize rooms+corridors into the existing `dungeon[x][y]` tile grid inside `dungeon.init`, bump `conf.SIZE_X/Y` to 40×22, and spawn the player at a room center. `game.lua` and `player.move()` don't need to change at all — the diff is one added module set plus ~3 small edits, and the grid stays the single source of truth for everything else on the roadmap.