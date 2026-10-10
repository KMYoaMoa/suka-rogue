# Tile System — Suggestions & Integration Notes

> Branch: `tile-system` · Draft spec: `docs/draft/Tile.md` · README plan item: "Tile System"
>
> Status: **not implemented yet** — this document is the plan. Nothing in `src/` changes on top of what `game-camera` left behind.
>
> Translation of the draft:
>
> > A Tile should carry:
> > - what its **type** is:
> >   - various interactable objects
> >   - floor
> >   - stairs
> >   - trap
> >   - wall (impassable area within eight tiles of the reachable region)
> >   - unreachable area
> > - how it should be **rendered**
> >
> > Two technical approaches:
> > - the Tile itself does **not** contain item/mob info; pickable items and mobs live in a separate list or Pool
> >   - seems more reasonable?
> > - the Tile stores what item / what mob is on it
> >
> > Other questions:
> > - unreachable area: keep it as wall, or a dedicated type? What if we want unreachable area to render nothing?
> > - we may need a more complete rendering mechanism and pipeline.
>
> Goal: satisfy the draft, prioritising **correctness and future fit over diff size** (decided: per-cell **Tile objects**, option B in §3.1). The BSP doc's "the dense grid is the single source of truth" rule (`docs/aigc/bsp-dungeon-integration.md` §1) still holds — the grid holds *Tile instances* instead of chars.

---

## 1. Where we are now

### Data model

| File | Role |
|---|---|
| `conf.lua` | `SIZE_X = 90`, `SIZE_Y = 45`, `TILE_SIZE = 32`, `CAMERA_WIDTH = 32`, `CAMERA_HEIGHT = 22`, `is_pos_valid(x, y)` |
| `dungeon.lua` | owns the grid. `dungeon[x][y]` holds a **bare string** today: `"#"` (wall) or `"."` (floor). `iterate`, `setTile`, `is_passable`; after `init()` also `dungeon.rooms` / `dungeon.paths` |
| `player.lua` | `player.move` = `is_pos_valid` + `dungeon.is_passable`; spawns at `dungeon.rooms[1]` center |
| `camera.lua` | `tile_at(sx, sy, grid)` returns `grid[x][y]`, or `"#"` when out of range |
| `game.lua` | screen-space loop; `love.graphics.print(camera.tile_at(...), transform)` prints the raw char; no `setColor` anywhere yet |
| `map/*` | pure geometry — `MapFactory.create` → `cell_list` (rooms, each with a `biome` string) + `path_list` (corridors); `dungeon.lua` rasterizes both into the grid |

### Facts that constrain the design

Everything below was **measured on the current code** (`MapFactory.create(90, 45, 3, 25)`, the parameters `dungeon.lua` actually uses), not assumed:

1. **Every floor tile is reachable.** `keep_largest_component` guarantees the room graph is one component; rasterized rooms+corridors are connected by construction. So "the reachable region" is exactly `{ (x,y) : cell is not wall }` — no flood fill is needed to *find* it.
2. **"Unreachable area" barely exists, but it does exist.** Walls by graph-distance-to-nearest-floor, over 40 seeds:
   - typical max distance is **9–10**, worst observed **13**;
   - in 12 of 40 seeds there are non-zero wall tiles **> 8** away from any floor (1–15 tiles per map, i.e. well under 1 % of the 4050-tile grid).
   - In most maps the draft's "≤ 8 tiles from reachable ⇒ wall" rule classifies **100 %** of walls as wall; the "unreachable area" type is a *rare* deep pocket between rooms.
3. **Biomes are room-only.** `Biome:assign` sets `room.biome` on `cell_list` entries. Corridors (`path_list`) have **no** biome. Some rooms are `BiomeA…BiomeE`; a biome cluster is 1–3 rooms.
4. **Rendering has no per-tile styling hook.** A tile is only ever its char; there is no palette, glyph table, or color state. The HUD prints overlap the map (pre-existing).
5. **`setTile` already guards bounds** via `is_pos_valid`; `is_passable` is a one-line string compare; only `player.lua` calls it.

So the tile system is really three separable problems: **(a) give each cell a typed object carrying its own render data, (b) classify walls vs. unreachable area, (c) let biome influence how floors look.** Everything else (items, mobs) is *out of scope* here — see §6.

---

## 2. Requirements & terminology

- **Tile type** — the semantic kind of a cell. The draft's list maps to types: floor, wall, unreachable/void, stairs (up/down), trap, door, and room for interactable objects later.
- **Tile definition** — the static, *shared* data for a type: name, `passable`, `glyph`, `color`. One table per type; never stored per cell.
- **Tile instance** — the object stored in a grid cell. It holds the type name, a reference to its shared definition, and per-cell state that may vary (e.g. `biome`). This is the object the draft describes.
- **Reachable region** — the set of carved floor tiles (fact 1).
- **`tile.biome`** — the biome a floor tile belongs to, stamped at generation time (rooms get their room's biome; corridors a neutral one).
- **Rendering pipeline** — for a cell: tile instance → its definition → (glyph, color) → draw. One indirection, per-cell data lives on the instance.

Non-goals for this change (explicitly deferred): item/mob storage (both draft options are premature — the Item/Mob Spawn Systems in the README come first and will dictate what an occupancy structure must look like), animations, lighting/FOV, tile textures in an assets mode.

---

## 3. Options

### 3.1 How a tile is represented in the grid

| Option | Idea | Diff size | Verdict |
|---|---|---|---|
| A. Keep the string symbol in `dungeon[x][y]`; add a `Tile` registry module (symbol → definition) | `dungeon[x][y]` stays `"."`; a registry holds type data | 1 new file + a few line edits | Smallest diff, but the grid stores *chars*, so any per-cell variation (biome, trap armed/unarmed, later damage/visibility) needs a second parallel grid or an escape hatch. Type and appearance stay decoupled, but instances cannot grow |
| **B. Replace strings with per-cell Tile objects `{ type, def, ... }` *(chosen)*** | `dungeon[x][y]` is a table; a `Tile` module defines the type table + constructor. Each cell carries its own state | Touches `dungeon.lua`, `camera.lua`, `game.lua`, `player.lua`, the rasterizer | **Chosen.** The draft describes a Tile that *carries* type and render info — an object per cell is the direct reading. Per-cell state (biome on floors, future trap/visibility/occupancy) has a home without a second grid. Costs a handful of extra lines at each consumer, but they are mechanical |
| C. String symbol + parallel metadata rows (`dungeon.meta[x][y]`), then upgrade later | Keep strings, store overlays separately | Medium | Two grids to keep in sync, and a migration later anyway. This is the half-measure B avoids |

Why B over A, despite A's smaller diff: the deciding requirement is that a tile **is** the draft's object ("type + how it is rendered"). With A, "a tile has a biome" / "a tile is a trap that has sprung" can only be expressed outside the grid, which is exactly the parallel-grid complexity we would then have to migrate away from. The consumers of the grid are few and small (fact 5: one movement check, one render loop, one camera accessor, the rasterizer), so the object form is affordable now and pays off at the next system.

### 3.2 Items / mobs on tiles (the draft's two choices)

| Option | Idea | Verdict for now |
|---|---|---|
| **A. Keep tiles content-free; items/mobs live in their own lists/pools *(chosen)*** | The grid never knows about entities | Matches the draft's own lean, and the Tile object stays small. Entity systems (README: Item/Mob Spawn) own placement, lookup and removal. Standard roguelike model |
| B. Tile stores its `item` / `mob` reference | `dungeon[x][y].item = ...` | Now *possible* with option B objects, but still premature: it couples the tile class to two systems that don't exist yet and forces an ownership/removal protocol into the grid |

Decision: **tiles stay content-free.** Option B (objects) makes this a *choice*, not a constraint — if a later system proves that occupancy belongs on the tile, the field can be added then. Tile instances still get a usable seam: an `occupant = nil` field is not added now, deliberately (see §6).

### 3.3 Unreachable area: wall, void, or nothing? (draft question)

Measured, per fact 2: at current parameters "unreachable" is ≤ 15 tiles on some maps, usually 0. Options:

| Option | Idea | Verdict |
|---|---|---|
| **A. A distinct `void` type; rendered as a dark glyph or skipped *(chosen)*** | A `void` type table; `classify()` converts walls > 8 from any floor into `void` instances. The type's `glyph` decides render: `" "` (nothing visible) | Directly answers the draft: type is distinct, appearance is a property of the type, so "render nothing" is one field, not a code path. Costs one type entry + one classification pass |
| B. Keep everything wall | Simplest | Loses the distinction the draft asks for; a future cave/biome renderer cannot tell a wall from an ungenerated pocket |
| C. Delete the tiles (set to `nil`) | "Not rendered" by absence | Breaks the dense-grid invariant (`camera.tile_at` and `iterate` assume every cell exists) — would need nil checks everywhere. Reject |

Note the draft's "≤ 8 tiles from reachable ⇒ wall, else unreachable": the 8 is a design knob, put it in `conf` (`conf.WALL_DEPTH = 8`). With `void` rendering as nothing, the visual result is that the player sees walls hugging the dungeon and black beyond — exactly the usual roguelike look.

### 3.4 Biome → tiles (how biome affects appearance)

`Biome:assign` already runs in `MapFactory.create` and stores `room.biome`. The tile system must turn that into per-tile data.

| Option | Idea | Verdict |
|---|---|---|
| **A. Stamp `tile.biome` on each floor tile at generation *(chosen)*** | While rasterizing, set the biome on every floor instance (room tiles get the room's biome; corridor tiles a neutral/nil biome). Rendering reads `tile.biome` directly | With per-cell objects this is nearly free and O(1) at draw time. The biome becomes tile state, consistent with "a tile carries its type and render info" |
| B. `dungeon.biome_at(x, y)` point-in-rectangle lookup at draw time | Ask the ~25 room rectangles every frame | No per-cell storage, but re-derives what generation already knows, and scatters room geometry into the renderer. With option B objects there is no reason to pay this |
| C. Bake biome into the tile type (`"floor_a"`, `"floor_b"`) | Type encodes biome | Multiplies the type universe by the biome count and conflates "what it is" with "where it is". Reject |

### 3.5 Rendering pipeline (draft's "more complete mechanism")

| Option | Idea | Verdict |
|---|---|---|
| **A. Definition-driven draw: `tile.def.glyph` + `tile.def.color`; `game.render` calls `love.graphics.setColor` before each `print`** | Everything visual comes from the instance's definition (and per-cell fields like biome where relevant) | Small change to the existing loop (a few lines), meets "how it should be rendered", and is the natural seam for a later sprite/assets mode |
| B. Keep printing raw data, no color | Today's code | Doesn't meet the draft; blocks biome look |
| C. A full renderer/atlas abstraction now | Layers, draw queue, assets | Over-engineering for ASCII mode; the README's "Add Assets Mode" is the right time |

The recommendation stays in ASCII but makes appearance **data on the object**, which is what the draft's second bullet asks for.

---

## 4. Recommended plan — Tile objects (option B)

Changes: **1 new file (`src/tile.lua`) + edits in `dungeon.lua`, `camera.lua`, `game.lua`, `player.lua`, `conf.lua`.** `main.lua` and all of `map/` stay untouched (map modules emit geometry/biomes; only the rasterizer in `dungeon.lua` changes).

### Step 1 — new `src/tile.lua` (type definitions + constructor; pure data, no `love`)

```lua
-- Tile: one *definition* per type (shared, immutable) and one *instance*
-- per grid cell (created by Tile:new / Tile.new_instance).
local Tile = {}

-- Shared per-type definitions. Keyed by type name.
--   passable: movement / spawn checks
--   glyph:    what to draw (" " = blank/"nothing visible")
--   color:    {r, g, b} for love.graphics.setColor, or nil for default white
local defs = {
    floor = { name = "floor",  passable = true,  glyph = ".", color = {0.6, 0.6, 0.6} },
    wall  = { name = "wall",   passable = false, glyph = "#", color = {0.4, 0.3, 0.2} },
    void  = { name = "void",   passable = false, glyph = " ", color = {0, 0, 0} },  -- unreachable pocket
    -- placeholders, unused until the systems that place them exist:
    stairs_down = { name = "stairs_down", passable = true, glyph = ">", color = {0.9, 0.9, 0.2} },
    stairs_up   = { name = "stairs_up",   passable = true, glyph = "<", color = {0.9, 0.9, 0.2} },
    trap        = { name = "trap",        passable = true, glyph = "^", color = {0.9, 0.2, 0.2} },
    door        = { name = "door",        passable = true, glyph = "+", color = {0.7, 0.5, 0.2} },
}

-- Create a tile instance of `type_name`; unknown names fall back to wall so
-- the grid is never nil and out-of-range access stays safe.
Tile.new_instance = function (type_name)
    local def = defs[type_name] or defs.wall
    return {
        type = def.name,   -- semantic kind
        def  = def,        -- shared render/behaviour data
        biome = nil,       -- per-cell state: filled for floor tiles (see Step 3)
    }
end

Tile.def_of = function (tile) return tile and tile.def or defs.wall end

-- Convenience queries that take a tile instance (nil-safe -> wall).
Tile.passable = function (tile) return Tile.def_of(tile).passable end
Tile.glyph    = function (tile) return Tile.def_of(tile).glyph end
Tile.color    = function (tile) return Tile.def_of(tile).color end

-- Biome-aware appearance hook (see §3.4). `biome` may be nil (corridors).
-- Today biomes do not change the look; this is where they will.
Tile.floor_for_biome = function (biome) return defs.floor end   -- placeholder

return Tile
```

Notes:
- Definitions are shared; instances are cheap tables pointing at them. Unknown/`nil` tiles fall back to the wall definition, so any gap or out-of-range value is safe.
- `void` renders as a space; flipping it to draw *nothing* is a one-line check in `game.render` on `glyph == " "` (or a `def.hidden` flag) — the type distinction survives either way.
- The instance carries `biome`; adding future per-cell state (trap armed, seen/visible) is a field here, with no second grid.

### Step 2 — `conf.lua`: one knob

```lua
conf.WALL_DEPTH = 8   -- wall tiles further than this from any floor become "void"
```

### Step 3 — `dungeon.lua`: create tile instances, stamp biome, classify

`setTile` grows a "no instance given → make one from the type name" convenience, keeping the rasterizer readable:

```lua
local Tile = require "tile"
local MapFactory = require "map.MapFactory"

-- Set a tile at (x, y). `tile` is a Tile instance, or a type name (string),
-- in which case an instance is created on the fly.
dungeon.setTile = function (tile, x, y)
    if conf.is_pos_valid(x, y) then
        dungeon[x][y] = type(tile) == "string" and Tile.new_instance(tile) or tile
    end
end
```

In `init()`, fill with wall instances, and while carving rooms stamp the biome so floors know where they are:

```lua
dungeon.init = function ()
    dungeon.iterate({
        before = function (x) dungeon[x] = {} end,
        during = function (x, y) dungeon.setTile("wall", x, y) end
    })

    local map = MapFactory.create(conf.SIZE_X, conf.SIZE_Y, 3, 25)

    -- carve rooms; each floor tile remembers its room's biome
    for _, c in ipairs(map.cell_list) do
        for x = c.x_pos, math.min(c:x_pos_end(), conf.SIZE_X - 1) do
            for y = c.y_pos, math.min(c:y_pos_end(), conf.SIZE_Y - 1) do
                local t = Tile.new_instance("floor")
                t.biome = c.biome
                dungeon.setTile(t, x, y)
            end
        end
    end

    -- carve corridors; biome stays nil (neutral)
    for _, p in ipairs(map.path_list) do
        for x = p.x_pos, math.min(p:x_pos_end(), conf.SIZE_X - 1) do
            for y = p.y_pos, math.min(p:y_pos_end(), conf.SIZE_Y - 1) do
                dungeon.setTile("floor", x, y)
            end
        end
    end

    dungeon.rooms = map.cell_list
    dungeon.paths = map.path_list
    dungeon.classify()
end
```

Classification (walls deeper than `WALL_DEPTH` become `void`) becomes a tile-type swap:

```lua
-- Mark wall tiles that are more than conf.WALL_DEPTH from any carved floor
-- as "void" (unreachable area). Multi-source BFS over the 4-neighbourhood.
dungeon.classify = function ()
    local dist, queue = {}, {}
    dungeon.iterate({
        before = function (x) dist[x] = {} end,
        during = function (x, y)
            if dungeon[x][y].type == "floor" then
                dist[x][y] = 0
                queue[#queue + 1] = { x, y }
            end
        end
    })
    local head = 1
    while head <= #queue do
        local cx, cy = queue[head][1], queue[head][2]; head = head + 1
        for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do
            local nx, ny = cx + d[1], cy + d[2]
            if conf.is_pos_valid(nx, ny) and dist[nx][ny] == nil then
                dist[nx][ny] = dist[cx][cy] + 1
                queue[#queue + 1] = { nx, ny }
            end
        end
    end
    dungeon.iterate({
        during = function (x, y)
            local t, d = dungeon[x][y], dist[x][y]
            if t.type == "wall" and d ~= nil and d > conf.WALL_DEPTH then
                dungeon.setTile("void", x, y)
            end
        end
    })
end
```

Passability now reads the instance:

```lua
dungeon.is_passable = function (x, y) return Tile.passable(dungeon[x][y]) end
```

(Note: `dungeon[x][y]` raises on an out-of-bounds x/y — `dungeon[x]` is `nil`. That is **already** true of today's `dungeon[x][y] == "."` (`is_passable(-1,-1)` errors on `master` too), so this change does not regress anything: `player.move` range-checks with `is_pos_valid` first, and `Tile.def_of(nil)` would return the wall def if you did want to make `is_passable` fully nil-safe.)

### Step 4 — `camera.lua` and `game.lua`: hand back and draw tile objects

`camera.tile_at` currently returns the raw grid entry (a char) and the literal `"#"` out of range. With objects, return the **instance**, and a shared fallback wall instance out of range:

```lua
-- camera.lua
local Tile = require "tile"
local OUT_OF_RANGE = Tile.new_instance("wall")   -- created once

camera.tile_at = function (sx, sy, grid)
    local x, y = camera.world_x(sx), camera.world_y(sy)
    if conf.is_pos_valid(x, y) then
        return grid[x][y]
    end
    return OUT_OF_RANGE
end
```

`game.render` draws from the instance's definition, and lets biome override floor appearance:

```lua
-- game.lua
local Tile = require "tile"
...
        else
            local tile = camera.tile_at(sx, sy, dungeon)
            local def = tile.def
            if tile.type == "floor" then def = Tile.floor_for_biome(tile.biome) end
            if def.color then love.graphics.setColor(def.color[1], def.color[2], def.color[3]) end
            love.graphics.print(def.glyph, transform)
            love.graphics.setColor(1, 1, 1)
        end
```

(The `"@"` branch and HUD stay as they are; resetting to white keeps the HUD/player legible. If you prefer not to touch the comparison, `game.render` can keep checking `camera.world_x(sx) == player.x` — unchanged.)

### Step 5 — `player.lua`

No change needed: it already calls `dungeon.is_passable`, which now reads the tile instance. `conf.is_pos_valid` still guards the range. (This is the payoff of keeping `is_passable` as the movement seam — only its internals changed.)

### Step 6 — Test

**Headless** (tile module + classification are pure Lua; run from `src/`):

```lua
-- lua check_tile.lua
package.path = package.path .. ";./?.lua"
math.randomseed(1)
local conf = require "conf"
local dungeon = require "dungeon"
local Tile = require "tile"

dungeon.init()
-- every cell is a tile instance with a known type and a definition
dungeon.iterate({ during = function (x, y)
    local t = dungeon[x][y]
    assert(type(t) == "table" and t.def, "cell is not a tile instance")
    assert(t.type == "floor" or t.type == "wall" or t.type == "void", "unknown type " .. tostring(t.type))
    if t.type == "floor" then assert(Tile.passable(t)) else assert(not Tile.passable(t)) end
end })
-- floor tiles know their biome; corridor tiles are neutral (nil)
dungeon.iterate({ during = function (x, y)
    local t = dungeon[x][y]
    if t.type == "floor" and t.biome ~= nil then
        assert(type(t.biome) == "string")
    end
end })
-- void tiles are strictly further than WALL_DEPTH from any floor
print("tile ok")
```

A useful extra assertion if you want it: for each room rectangle corner, `dungeon[x][y].biome == room.biome` (the rasterizer stamps it) — this replaces the old point-in-rect `biome_at` check.

**In-game** (`love .`, from the repo root):
- [ ] Same *layout* as before this change (nothing in `map/` moved) — only colors differ.
- [ ] Walls, floors and (rare) unreachable pockets are visually distinct; walking is blocked exactly as before (`wall` and `void` both impassable).
- [ ] Player still spawns in `rooms[1]` and cannot enter walls.
- [ ] Camera border (out-of-range) still renders as wall.
- [ ] No crash when the map has zero `void` tiles (the common case).

### Diff summary

| File | Change |
|---|---|
| `src/tile.lua` | **new** — type definitions, `new_instance`, nil-safe queries, `floor_for_biome` hook |
| `src/conf.lua` | +1 line: `WALL_DEPTH` |
| `src/dungeon.lua` | `setTile` accepts instance-or-name; `init()` creates instances + stamps `tile.biome`; `classify()`; `is_passable` reads the instance |
| `src/camera.lua` | `tile_at` returns the instance; shared out-of-range wall instance |
| `src/game.lua` | ~6 lines in the draw loop (definition color/glyph + biome override) |
| `src/player.lua`, `src/main.lua`, `src/map/*` | **untouched** |

---

## 5. Why this shape

- **The grid stays the single source of truth** — it now stores Tile instances instead of chars, but `iterate`, the BSP rasterizer's bounds logic and `player.lua`'s movement seam are unchanged in spirit. `player.lua` needs *zero* edits because `is_passable` remains the one door into passability.
- **Type and per-cell state have separate homes**: `tile.def` (shared, one table per type) vs. fields on the instance (`biome` now; trap/visibility/occupancy later). Adding a type is one entry in `tile.lua`; adding per-cell state is one field, no second grid.
- **The three draft questions are answered structurally**: unreachable area = a distinct `void` type whose *definition* decides appearance (render nothing is a `glyph` value); biome → tiles = `tile.biome` stamped at generation; rendering pipeline = definition lookup inside the existing loop.
- **Items/mobs are deliberately excluded** (draft's first option), and with objects that exclusion is a design choice we can revisit by adding one field — not a limitation baked into a string grid.
- **Cost of option B is contained**: the only consumers of `dungeon[x][y]` are the rasterizer, `is_passable`, `camera.tile_at` and `game.render` (fact 5). Four small call sites, no consumers in `map/`.

The one piece of *new* computation is the distance BFS in `classify()` — O(grid) once per dungeon, ~4050 cells, negligible. It is the only way to tell a wall adjacent to playable space from a sealed pocket, which is what the draft's wall/unreachable split requires.

---

## 6. Afterwards (future roadmap hooks, not part of this change)

- **Stairs / traps / doors** — already reserved types in `tile.lua`; placement belongs to the Room Type / Construct Spawn systems. Trap armed/sprung state is exactly the per-cell field these instances were built for (`tile.armed = true`).
- **Item / Mob Spawn System** — store entities in their own lists (`{ x, y, kind }`); render them in a pass *after* tiles (the `"@"` special-case is already such a pass — it can become the first entry in an entity draw loop). Tiles stay content-free; if occupancy on the tile is ever preferred, add `tile.occupant` without touching the grid.
- **Room Type** — room types can expand the same pattern biomes use (`room.type` → `tile.biome`; later `tile.room_type`), stamped during rasterization.
- **FOV / visibility** — `tile.seen` / `tile.visible` are per-cell fields on the instance; the type definition supplies the "unseen" glyph/color, and `game.render` picks based on the field.
- **Assets mode** (README "Improve Appearance") — replace `def.glyph` / `def.color` with sprite lookups; because rendering already goes through the definition, the loop does not change shape.
- **Biome visuals** — flesh out `Tile.floor_for_biome(tile.biome)` (per-biome glyph/color tables) once biomes have real definitions instead of `BiomeA…BiomeE` placeholders.

---

## 7. TL;DR

Replace the char in `dungeon[x][y]` with a **Tile instance** and add `src/tile.lua` holding shared **type definitions** (`{ name, passable, glyph, color }`) plus `new_instance` and nil-safe queries. Each instance points at its definition and carries per-cell state (`biome` now). Answers to the draft: **type and rendering are separated** (the instance's `def` holds glyph/color; adding a type is one entry); **items/mobs are NOT stored in tiles** (separate lists, as the draft leaned toward — and now a reversible choice, thanks to objects); **unreachable area is a distinct `void` type** whose definition can render nothing — classified by a one-time distance BFS (`conf.WALL_DEPTH = 8`; measured: such pockets are rare, ≤ 15 tiles, but real on ~30 % of maps); **biome → tiles** is `tile.biome` stamped during rasterization, read by `Tile.floor_for_biome` at draw time. Edits: 1 new file + ~1 line in `conf.lua`, ~45 lines in `dungeon.lua`, a few lines in `camera.lua`, ~6 lines in `game.lua`; `player.lua`, `main.lua` and all of `map/` untouched. Choice rationale: with per-cell objects, per-cell state (biome today, traps/visibility/occupancy tomorrow) has a home and no parallel grid is ever needed; the only cost is rewriting the four small grid consumers, all mechanical.
