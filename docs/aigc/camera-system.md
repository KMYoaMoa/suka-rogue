# Camera System — Suggestion & Integration Plan

> Branch: `game-camera` · README plan item: "Camera and larger dungeon → [ ] Camera Implementation"
>
> Goal: bring the camera back as a **complete module** — visible area sized by attributes, player always centered on screen (the dungeon scrolls underneath), and out-of-dungeon areas rendered as `"#"`.

---

## 1. Where we are now

| File | Role |
|---|---|
| `conf.lua` | `SIZE_X = 30`, `SIZE_Y = 15`, `TILE_SIZE = 32`, `is_pos_valid(x, y)` |
| `game.lua` | `render()` iterates the **whole 30×15 world** and prints each tile char; the old `game.camera = {x=0, y=0}` block was already removed as dead code |
| `main.lua` | window 1280×720 |
| `player.lua` | pos in world tiles; moves via `player.move` (turn-based, no continuous motion) |

Key numbers for the design:

- Each tile is drawn 32 px on screen (`TILE_SIZE = 32`; the `2` in the transform up-scales the 16 px default font), so the window fits **40 columns × 22 rows** of tiles (1280/32 = 40, 720/32 = 22.5 → 704 px, leaving a 16 px strip at the bottom).
- The map (30×15) is **smaller than the viewport** (40×22). That is not a problem — it is exactly the required use case: the camera will always peek outside the dungeon, and those parts must be `"#"`.

Rendering today:

```lua
for x = 0, conf.SIZE_X - 1, 1 do
    for y = 0, conf.SIZE_Y - 1, 1 do
        local t = love.math.newTransform(x * conf.TILE_SIZE, y * conf.TILE_SIZE, 0, 2, 2, 0, 0)
        if x == player.x and y == player.y then love.graphics.print("@", t)
        else love.graphics.print(dungeon[x][y], t) end
    end
end
```

The transform position is the **world** tile × TILE_SIZE. With a camera, positions must become **screen** tile × TILE_SIZE instead.

---

## 2. Terminology and requirements

- **World space**: dungeon grid `dungeon[x][y]`, x ∈ [0, 30), y ∈ [0, 15).
- **Camera space (screen)**: what you see, `sx ∈ [0, camera.width)`, `sy ∈ [0, camera.height)`.
- **Viewport origin**: world tile `(camera.x, camera.y)` shown at screen `(0, 0)`.
- **Centering rule**: the player's world tile is always displayed at screen `(floor(width/2), floor(height/2))`, hence:
  ```
  camera.x = player.x - floor(camera.width / 2)
  camera.y = player.y - floor(camera.height / 2)
  screen (sx, sy)  →  world (camera.x + sx, camera.y + sy)
  ```
- **Out-of-range rule**: if the world tile `(camera.x + sx, camera.y + sy)` is not a valid dungeon position, draw `"#"`.
- "width / length" naming: use `camera.width` / `camera.height` (height = the "length"). Both in **tiles** — the unit everything else works in.

Because the game is turn-based (positions change on input, nothing moves between frames), the camera offset can be recomputed at the start of `render()` from the current `player.x/y` — no `love.update` loop, no lerp needed.

---

## 3. Options

### 3.1 Rendering strategy

| Option | Idea | Verdict |
|---|---|---|
| **A. Screen-space loop + camera module (recommended)** | `render()` iterates `0..camera.width-1 × 0..camera.height-1`; for each screen tile compute the world tile via camera helpers; position the transform with `sx * TILE_SIZE`, not world coords. Out-of-range → `"#"` | Smallest change to the existing style: the loop body is nearly identical, only the iteration bounds and the position change. The camera owns the viewport math, and `game.lua` stays dumb |
| B. World-space loop + `love.graphics.translate` | Wrap the existing world loop in a translation by `-camera.x * TILE_SIZE` | Keeps world coords inside the loop, but then out-of-range `"#"` regions are not tiles at all (they'd fall outside the translated drawing area), so the `"#"` fill requires extra strip-drawing logic. More machinery, same result |
| C. World-space loop + manual subtract | Keep iterating 30×15 world tiles, draw at `(x - camera.x) * TILE_SIZE`, then fill the missing border strips with `"#"` | Four extra strip loops (L/R/U/D); more code than A for the identical picture |
| D. Pixel-centered camera | Center on the player's *pixel* center (±16 px sub-tile offset) | Unnecessary for a grid roguelike; adds fractions and rounding. Skip |

### 3.2 Camera size source

| Option | Idea | Notes |
|---|---|---|
| **A. Explicit config (recommended)** | `conf.CAMERA_WIDTH = 40`, `conf.CAMERA_HEIGHT = 22` (fills the window at 32 px tiles) | Matches the existing style (`SIZE_X/Y` live in `conf`); camera module reads them at load |
| B. Derived from window/tile | `floor(1280 / TILE_SIZE)`, `floor(720 / TILE_SIZE)` | Redundant while window size lives in `main.lua`; fine later if you centralize display config |

### 3.3 Where the out-of-range check lives

| Option | Idea | Notes |
|---|---|---|
| **A. `camera.tile_at(sx, sy, grid)` (recommended)** | Camera returns the tile char, `"#"` when OOB; bounds-checked *before* indexing (`grid[-1]` is nil — indexing first would crash) | One method, camera stays decoupled from `dungeon` (receives the grid as a parameter); `game.lua` just prints the result |
| B. Inline in `game.lua` | `if conf.is_pos_valid(x, y) then print(dungeon[x][y]) else print("#") end` in the loop | Even fewer lines, but the camera module no longer owns its own viewport semantics |

### 3.4 Interaction with map size (README: "and larger dungeon")

The camera module does not care about `SIZE_X/Y` at all — it only needs `is_pos_valid`. Two cases:

- **Map ≤ viewport (today, 30×15 vs 40×22)**: the viewport always contains OOB strips; the dungeon appears as a band that slides inside a wall frame as the player walks — exactly the requested "player fixed, dungeon moves" feel.
- **Map > viewport (future "larger dungeon")**: scrolling actually reveals new dungeon. **No camera change needed** — only `SIZE_X/Y`, and the map modules handle bigger grids already (BSP takes any size).

---

## 4. Recommended minimal plan

Total: **1 new file + 2 small edits** (`conf.lua`, `game.lua`). `player.lua`, `dungeon.lua`, `main.lua` untouched.

### Step 1 — `src/conf.lua` (2 lines)

```lua
conf.CAMERA_WIDTH  = 40   -- visible area, in tiles (fills 1280px at 32px tiles)
conf.CAMERA_HEIGHT = 22   -- 704px; the 16px strip below stays free for the HUD
```

### Step 2 — new `src/camera.lua` (pure logic, no love → testable headless)

```lua
local conf = require "conf"

-- Camera: size of the visible area (in tiles) and the world tile shown
-- at the top-left of the screen. The player is always centered on screen,
-- so the dungeon scrolls underneath the camera.
local camera = {}

camera.width  = conf.CAMERA_WIDTH
camera.height = conf.CAMERA_HEIGHT

camera.x = 0   -- world tile at screen (0, 0); recomputed on every render
camera.y = 0

-- Re-center the viewport on the player (turn-based: call once per render)
camera.update = function (player)
    camera.x = player.x - math.floor(camera.width / 2)
    camera.y = player.y - math.floor(camera.height / 2)
end

-- World coordinates of a screen tile
camera.world_x = function (sx) return camera.x + sx end
camera.world_y = function (sy) return camera.y + sy end

-- Tile to draw at screen position (sx, sy); out-of-dungeon area is wall.
--   grid: the dungeon tile grid (passed in to keep camera decoupled)
camera.tile_at = function (sx, sy, grid)
    local x, y = camera.world_x(sx), camera.world_y(sy)
    if conf.is_pos_valid(x, y) then
        return grid[x][y]
    end
    return "#"
end

return camera
```

Notes:
- Bounds checks happen **before** `grid[x]` indexing — important, because `grid[x]` is `nil` for `x < 0` and `grid[x][y]` would crash.
- The module requires only `conf`; `dungeon` is passed in as a parameter, so camera and dungeon stay independent (and the math can be unit-tested without LÖVE).

### Step 3 — `src/game.lua`: screen-space rendering (rewrite `render()`)

```lua
local camera = require "camera"

game.render = function ()
    camera.update(player)                     -- center on the player (per frame)
    for sx = 0, camera.width - 1, 1 do
        for sy = 0, camera.height - 1, 1 do
            local transform = love.math.newTransform(sx * conf.TILE_SIZE, sy * conf.TILE_SIZE, 0, 2, 2, 0, 0)
            if camera.world_x(sx) == player.x and camera.world_y(sy) == player.y then
                love.graphics.print("@", transform)
            else
                love.graphics.print(camera.tile_at(sx, sy, dungeon), transform)
            end
        end
    end
    -- HUD unchanged
    love.graphics.print("ARM:" .. player.armor, 0, 340)
    love.graphics.print("HP:" .. player.health, 0, 360)
    love.graphics.print("MP:" .. player.magic, 0, 380)
end
```

The only structural changes vs the old loop: bounds become `camera.width/height`, the transform position uses **screen** coords `sx/sy`, and the `"@"` check compares world-coordinate lookups (`camera.world_x(sx) == player.x`) — equivalent to "screen tile is the center", but keeps the old comparison style.

---

## 5. Verification

### Headless (camera math is pure, no love needed)

```lua
-- run from src/ with: lua check_camera.lua
local conf = require "conf"          -- pure table + is_pos_valid
local camera = require "camera"

local function count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

-- fake player + grid
local player = { x = 5, y = 5 }
local grid = {}
for x = 0, conf.SIZE_X - 1 do grid[x] = {} for y = 0, conf.SIZE_Y - 1 do grid[x][y] = "." end end
grid[5][5] = "@"

camera.update(player)
assert(camera.x == 5 - math.floor(camera.width / 2))      -- -15
assert(camera.y == 5 - math.floor(camera.height / 2))     -- -6
-- player lands exactly at the screen center
assert(camera.world_x(math.floor(camera.width / 2)) == player.x)
assert(camera.world_y(math.floor(camera.height / 2)) == player.y)
-- out-of-range corners are walls; in-range tiles are the grid
assert(camera.tile_at(0, 0, grid) == "#")                 -- world (-15, -6)
assert(camera.tile_at(camera.width - 1, camera.height - 1, grid) == "#")
assert(camera.tile_at(math.floor(camera.width / 2), math.floor(camera.height / 2), grid) == "@")
-- player at the map corner still works (offsets go negative)
player.x, player.y = 0, 0; camera.update(player)
assert(camera.x == -20 and camera.y == -11)
assert(camera.tile_at(20, 11, grid) == "@")
player.x, player.y = conf.SIZE_X - 1, conf.SIZE_Y - 1; camera.update(player)
assert(camera.tile_at(20, 11, grid) == "@")                 -- world 29,14 → screen 29-9, 14-3
print("camera ok")
```

### In-game (`love .`)

- [ ] The `"@"` stays at a **fixed screen position** while walking; the dungeon visibly slides underneath (walls on one side, rooms entering from the other).
- [ ] At map borders, the exposed area is filled with `"#"` everywhere (no black gaps, no crashes at negative x/y).
- [ ] HUD still prints (`ARM/HP/MP`); note it currently overlaps the map's bottom-left (pre-existing layout issue, README has "Improve UI Layout" planned — optionally move it into the 16 px bottom strip later).

---

## 6. Edge cases & notes

- **Even width asymmetry**: `40` tiles → player sits at screen column 20, i.e. 20 tiles left / 19 right. Standard for roguelikes; use odd sizes if you want perfect symmetry (but 41×32 = 1312 > 1280 won't fit — 39 works). Same for height (22 → 11 up / 10 down).
- **Negative world coordinates**: `camera.x/y` are frequently negative; never index `grid[x]` before an `is_pos_valid` check (nil-index crash).
- **No smooth scrolling**: turn-based ⇒ recompute in `render()`. If polish wants smooth scrolling later, add a lerp between `camera.x` and `player.x - half` — the module structure keeps that an easy addition.
- **Larger dungeon (README)**: bumping `SIZE_X/Y` (e.g. 60×40) needs no camera changes; the BSP generator already handles any size. This is the moment the camera actually *scrolls* instead of sliding a band inside a wall frame.
- **HUD overlap**: `print(..., 0, 340)` sits inside the 704 px map area; the 16 px strip at the bottom (720 − 704) is the natural future HUD spot.

---

## 7. TL;DR

A dedicated `src/camera.lua` — attributes `width`/`height` (tiles), viewport origin `camera.x/y`, `update(player)` centering (player at `floor(w/2), floor(h/2)`), `world_x/world_y` mapping, and `tile_at(sx, sy, grid)` returning `"#"` for out-of-dungeon positions (bounds-checked before indexing). `render()` becomes a 40×22 screen-space loop whose transform positions use `sx*sy * TILE_SIZE`, keeping the HUD and player-rendering patterns as-is. Diff = 1 new file (~40 lines) + ~8 lines in `game.lua` + 2 lines in `conf.lua`; the camera module is pure logic and headless-testable, and it is already correct for the future larger dungeon.