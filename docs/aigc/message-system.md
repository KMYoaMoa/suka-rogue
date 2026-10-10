# Message System — Suggestions & Integration Notes

> Branch: `message-system` (to be created) · README plan item: "Message System" (Scheduled Oct. 2026)
>
> No draft spec exists for this; the requirements below are the whole brief:
> > a simple message system **with history**. It should be as simple as providing an interface to **append a new message**, and **update on the screen with the latest N lines** (N configurable). The messages can have **different types**, and should be able to be displayed in **different colors per entry**.
>
> Goal: satisfy that brief with the **minimum code change**, in the same style the rest of `src/` already uses after the tile system (`docs/aigc/tile-system.md`) — a small pure-logic module plus a few lines in `game.render`.
>
> Note: the implemented tile system diverged from its own suggestion doc (e.g. `Tile.new` instead of `Tile.new_instance`, no `tile.classify()`; walls are derived from `has_floor_around` at generation time). **Treat the code as the source of truth** — this document describes the *shape* to follow and the decisions to make, not a rigid patch. Where it quotes code, it mirrors the style actually in `src/` today.

---

## 1. Where we are now

### The pieces that matter

| File | Role | Relevance |
|---|---|---|
| `conf.lua` | `SIZE_X=90`, `SIZE_Y=45`, `TILE_SIZE=32`, `CAMERA_WIDTH=32`, `CAMERA_HEIGHT=22`, `is_pos_valid` | Where `MESSAGE_LINES` / layout knobs belong (this is the established pattern: camera got `CAMERA_WIDTH/HEIGHT`, tile got `WALL_DEPTH`) |
| `tile.lua` | registry: a `defs` table maps type name → `{ name, passable, glyph, color }`; `Tile.new(type)` builds an instance; nil-safe `Tile.def_of` | The **exact pattern to copy**: one definition table keyed by type, colors as `{r,g,b}` arrays, pure logic, no `love` |
| `game.lua` | `game.render()` runs the tile loop, resets color to white after each tile, then prints the HUD (`ARM:`/`HP:`/`MP:` at `x=0, y=340/360/380`, i.e. 20 px steps) | Where messages are drawn. There is **no** UI/panel module and no `love.graphics.setFont` call — everything uses LÖVE's default font |
| `main.lua` | `love.load` → `game.init`; `love.keypressed` → `game.input.handle_move` | The only input hook. A message-on-move demo plugs in here |
| `player.lua`, `dungeon.lua`, `camera.lua` | gameplay/logic, no rendering | Sources of future messages ("You hit the rat", "You found a sword"); nothing to change now |

### Facts that constrain the design (measured on the current code)

1. **There is no message, log, or UI system at all.** `grep` for `message`/`log` finds nothing outside docs. This is a greenfield module.
2. **`game.render()` is stateless and redraws everything each frame.** LÖVE clears the screen every frame, so a history that is simply re-drawn (last N entries) needs **no dirty flag, no caching** — the simplest correct thing is also the cheapest here.
3. **Screen layout** (window 1280×720, `main.lua`):
   - tile map covers **1024 × 704** px (`CAMERA_WIDTH·TILE_SIZE × CAMERA_HEIGHT·TILE_SIZE`);
   - free areas: a **256 px right strip** and a **16 px bottom strip**;
   - the HUD already prints **over** the map bottom-left (y 340–390), so overlapping is the existing, accepted style. README lists "Improve UI Layout" and "More Organized UI System" as future work — this change should not try to fix layout.
4. **Color is already the display mechanism for types**: `tile.lua` stores `color = {r,g,b}` per type and `game.render` does `love.graphics.setColor(...)` then resets to white. Messages should do exactly the same, so the "different colors per entry" requirement reuses a solved pattern.
5. **Module convention**: `local X = {} ... return X`, pure logic modules (`camera`, `tile`) contain **zero `love.*` calls**; all drawing lives in `game.lua`. Headless testing with the system `lua` works for such modules (the tile doc relied on this).

So the message system is: **(a) a small history store with an append API, (b) a type→color registry, (c) a draw loop for the last N entries.** Nothing else.

---

## 2. Requirements & terminology

- **Message / entry** — one line: `{ text = string, type = string }` (plus an optional per-entry `color` override, see §3.3). This is the unit stored in history.
- **Message type** — a symbolic kind (`"info"`, `"combat"`, `"warning"`, `"good"`, …). A type maps to a default color; this is what makes "different colors per entry" work without every caller choosing a color.
- **History** — the ordered list of all entries so far (oldest first). "Latest N lines" are a **view** over the tail of history.
- **N (`conf.MESSAGE_LINES`)** — how many tail entries are drawn at once. Configurable, per the brief.
- **Append API** — the one public write path: `Message.add(text, type)`.

Functional requirements (from the brief, restated precisely):

1. `Message.add(text, type)` appends one entry to history.
2. Rendering shows the **last N** entries, where N is configurable.
3. Each entry is drawn in a color determined by its type (entry-level override optional).

Non-goals for this change (explicitly deferred): wrapping long lines, scrolling/paging through full history, message merging/repetition counters, timestamps, save/load of the log, fonts, a persistent UI panel, mouse interaction. Several are natural follow-ups (§6) — keep this change to the brief.

---

## 3. Options

### 3.1 Where the code lives

| Option | Idea | Verdict |
|---|---|---|
| **A. New `src/message.lua` (pure logic) + a few lines in `game.render` *(recommended)*** | Module owns history + type→color registry + `add`/`recent`; `game.lua` draws the tail | Mirrors `tile.lua`/`camera.lua` exactly (fact 5): logic is headless-testable, drawing stays in one place. Smallest surface that still separates concerns |
| B. Put history + a `Message.render()` (with `love.*` inside) in the module | One stop for everything | Breaks the "modules contain no `love`" convention and makes headless testing impossible. Reject |
| C. Put everything inline in `game.lua` (a local table + a loop) | Fewest files | Fastest to write, but no reusable API for `player.lua`/future systems to call, and it grows `game.lua`, which README already flags for refactor. Worth it only if the message system were throwaway |
| D. A generic UI/layout subsystem now | Panels, anchors, layers | Over-engineering; README defers this to "More Organized UI System". Reject |

### 3.2 History storage & the "latest N" view

| Option | Idea | Verdict |
|---|---|---|
| **A. Unbounded array, render the tail (`entries[#entries-N+1 .. #entries]`) *(recommended)*** | `history = {}`; `add` appends. `recent(n)` returns the tail | Simplest, and "history" literally means keep it. Cost is negligible (a few bytes per line; a long session is thousands of entries). No index bookkeeping bugs |
| B. Ring buffer capped at N (or at `MESSAGE_HISTORY_MAX`) | Fixed-size circular storage | Bounded memory, but adds wrap-around index arithmetic for no present benefit, and shrinks "history" to whatever N is. Revisit only if memory ever matters |
| C. Keep only the last N, drop older on append | Trivial tail | Directly contradicts "with history". Reject |

Recommended A, with an optional cap (`conf.MESSAGE_HISTORY_MAX`, default `nil` = unbounded) as an escape hatch rather than a default.

### 3.3 Type → color mapping (and per-entry color)

| Option | Idea | Verdict |
|---|---|---|
| **A. A `types` table in `message.lua` (type name → `{ color = {r,g,b} }`), mirroring `tile.lua` `defs`; unknown type → a `"info"`/default entry *(recommended)*** | `Message.add("You hit the rat", "combat")` picks the combat color | Consistent with the tile system, one place to add a type, callers stay declarative. Satisfies "different types ⇒ different colors" directly |
| B. Caller passes a raw color: `Message.add(text, {1,0,0})` | Maximum flexibility | Every call site re-decides RGB; no shared vocabulary of types. Keep as an **optional override**, not the primary API |
| C. Colors in `conf.lua` | Central palette | Mixes message semantics into general config; the tile system already chose the module-local `defs` pattern. Prefer A |

Recommended A, plus the small extension that makes the brief's "colors per entry" unambiguous: an entry may carry an explicit `color`, and rendering uses `entry.color or types[entry.type].color`. That covers both "color by type" (normal) and "this one line is special" (rare) with one `or`.

### 3.4 Where and how the last N are drawn

| Option | Idea | Verdict |
|---|---|---|
| **A. A `game.render_messages()` helper called at the end of `game.render()`, positioned by `conf` knobs *(recommended)*** | Column of N lines, oldest at top, newest at bottom, each printed with its color, then color reset to white | Matches how the HUD is already drawn (over the map, fixed screen coords); placement becomes data (`conf.MESSAGE_ORIGIN_X/Y`, `conf.MESSAGE_LINE_HEIGHT`). Reuses the established setColor/print/reset rhythm |
| B. A dedicated right-hand panel (x ≥ 1024) | Use the free 256 px strip | Cleaner separation, but is UI layout work (README defers it) and 256 px is narrow for text; would also want a background rectangle for legibility. Keep as a future option |
| C. Newest at top, older downward | Reverse order | Unconventional for roguelike logs; the newest line should be in a stable position (bottom). Reject |

Recommended A. Draw **after** the tile loop so messages overlay tiles, exactly like the HUD (fact 3), and keep the origin/line-height in `conf` so moving them later is a data edit.

### 3.5 API surface

| Option | Idea | Verdict |
|---|---|---|
| **A. `Message.add(text, type)` + `Message.recent(n)` + `Message.clear()` + exposed `Message.types` *(recommended)*** | Minimal write path, minimal read path | Covers the brief; `clear()` is one line and useful on `game.init`/new level; `types` lets future systems recolour or add types |
| B. Also add `Message.addf(format, type, ...)` | Formatting sugar | Convenience only; callers can `string.format` themselves. Optional |
| C. A full event/pub-sub system | Subscribers, delivery | Wildly out of scope for "append and show last N" |

Recommended A; note B as an optional one-liner if repetitive `string.format` calls appear.

---

## 4. Recommended plan

Total: **1 new file (`src/message.lua`) + 3 small edits (`conf.lua`, `game.lua`, and one demo call site)**. `dungeon.lua`, `player.lua`, `camera.lua`, `main.lua`, `tile.lua` and all of `map/` stay untouched.

### Step 1 — new `src/message.lua` (history + type registry; pure logic, no `love`)

```lua
-- Message: a small append-only log with typed, coloured entries.
-- Pure logic (no love.*): the caller draws `Message.recent(n)`.
local Message = {}

-- type name -> definition. Mirrors tile.lua's `defs` table.
--   color: {r, g, b} for love.graphics.setColor
local types = {
    info    = { color = {0.80, 0.80, 0.80} },   -- default / narration
    good    = { color = {0.30, 0.90, 0.30} },   -- healing, pickups
    combat  = { color = {0.95, 0.75, 0.20} },   -- hits, damage
    warning = { color = {0.95, 0.45, 0.10} },   -- danger, low HP
    bad     = { color = {0.90, 0.20, 0.20} },   -- death, critical failure
}
local DEFAULT_TYPE = "info"

local history = {}   -- ordered, oldest first

-- Append one message.
--   text: the line to show (build it with string.format at the call site)
--   type: a key of `types`; unknown/nil falls back to "info"
--   color: optional {r,g,b} overriding the type colour for this entry
Message.add = function (text, type, color)
    local t = types[type] and type or DEFAULT_TYPE
    history[#history + 1] = { text = text, type = t, color = color }
end

-- The last `n` entries, oldest first (n defaults to all of history).
Message.recent = function (n)
    if n == nil or n >= #history then return history end
    local out = {}
    local first = #history - n + 1
    for i = first, #history do out[#out + 1] = history[i] end
    return out
end

Message.count = function () return #history end

Message.clear = function () history = {} end

-- Colour an entry should be drawn in: explicit override, else its type's.
Message.color_of = function (entry)
    return entry.color or (types[entry.type] or types[DEFAULT_TYPE]).color
end

Message.types = types   -- exposed so future systems can add/recolour types

return Message
```

Notes:
- Unknown or `nil` type → `"info"`: a caller can never produce an uncoloured/crashing entry.
- `recent` returns the tail as a **new array**, so the renderer can iterate it safely; it returns the history table itself when `n` covers everything (no pointless copy).
- Everything is Lua tables — no `love`, so the whole module is headless-testable (§5).

### Step 2 — `conf.lua`: the knobs (mirrors `WALL_DEPTH` / `CAMERA_*`)

```lua
conf.MESSAGE_LINES       = 6    -- how many of the latest entries are shown (the "N")
conf.MESSAGE_LINE_HEIGHT = 20   -- px between lines (same step the HUD already uses)
conf.MESSAGE_ORIGIN_X    = 0    -- screen px of the first (oldest visible) line
conf.MESSAGE_ORIGIN_Y    = 400  -- below the HUD block (y 340/360/380)
-- conf.MESSAGE_HISTORY_MAX = 500  -- optional cap; omit for unbounded history
```

`MESSAGE_LINES` is the configurable N from the brief; the rest make placement data rather than magic numbers (currently the HUD hard-codes 340/360/380 — don't repeat that).

### Step 3 — `game.lua`: draw the tail

Add the require and a small helper, and call it after the HUD (or before it — messages just need to come after the tile loop):

```lua
local Message = require "message"

-- Draw the latest conf.MESSAGE_LINES messages, oldest at the top; newest at
-- the bottom so the most recent line always sits in a stable position.
game.render_messages = function ()
    local lines = Message.recent(conf.MESSAGE_LINES)
    for i, entry in ipairs(lines) do
        local y = conf.MESSAGE_ORIGIN_Y + (i - 1) * conf.MESSAGE_LINE_HEIGHT
        local c = Message.color_of(entry)
        if c then love.graphics.setColor(c[1], c[2], c[3]) end
        love.graphics.print(entry.text, conf.MESSAGE_ORIGIN_X, y)
    end
    love.graphics.setColor(1, 1, 1)   -- leave white for the next drawer
end
```

...and inside `game.render`, after the HUD prints:

```lua
    game.render_messages()
```

The helper takes no arguments and reads `conf`, so it is callable from `game.render` and (later) from tests or a different UI layer. Colour is reset to white at the end for the same reason the tile loop resets after every tile (fact 4) — never leak colour state into the next draw.

### Step 4 — produce messages (demo wiring; keep or replace)

The brief only requires the *interface*; wire one or two real call sites so it is visibly live, then gameplay systems replace them:

```lua
-- game.init, after dungeon/player init:
Message.clear()
Message.add("You descend into the ruins.", "info")

-- game.input.handle_move, inside the `if dx ~= 0 or dy ~= 0` branch:
Message.add(string.format("You move to (%d, %d).", player.x, player.y), "info")
```

This proves the API end-to-end without committing the message system to any gameplay meaning. (A "no move" branch — walking into a wall — is a natural second demo line and needs only an `else`.)

### Step 5 — Test

**Headless** (`message.lua` has no `love`, so the system `lua` can drive it; run from `src/`):

```lua
-- lua check_message.lua
package.path = package.path .. ";./?.lua"
local Message = require "message"

Message.clear()
-- append + ordering
Message.add("first", "info")
Message.add("second", "combat")
assert(Message.count() == 2)

-- latest N: only the tail, oldest-first, and N is respected
local tail = Message.recent(1)
assert(#tail == 1 and tail[1].text == "second")
local tail2 = Message.recent(2)
assert(#tail2 == 2 and tail2[1].text == "first" and tail2[2].text == "second")
-- asking for more than exists returns everything
assert(#Message.recent(99) == 2)

-- types drive colour; unknown type falls back; per-entry override wins
assert(Message.color_of(Message.recent(1)[1]) == Message.types.combat.color)
Message.add("mystery", "not-a-type")
assert(Message.recent(1)[1].type == "info")
Message.add("alarm", "warning", {1, 0, 0})
assert(Message.color_of(Message.recent(1)[1])[1] == 1)

-- clear empties history
Message.clear()
assert(Message.count() == 0 and #Message.recent(6) == 0)
print("message ok")
```

Edge cases the test pins down: empty history, `#history < N`, `#history == N`, `#history > N`, unknown type, explicit override, `clear()`.

**In-game** (`love .` from the repo root):
- [ ] The startup line appears (once) and lines do not flicker or accumulate visually — each frame redraws exactly the tail.
- [ ] Moving appends a new line; the newest is at the bottom; older lines shift up and eventually scroll off once more than `MESSAGE_LINES` exist.
- [ ] Each type is a visibly different colour; the HUD and tiles are **not** tinted (colour state is reset).
- [ ] Changing `conf.MESSAGE_LINES` changes how many lines are shown; changing `MESSAGE_ORIGIN_Y` moves the block.
- [ ] No crash with zero messages (fresh start before any `add`).

### Diff summary

| File | Change |
|---|---|
| `src/message.lua` | **new** — history, `types` registry, `add`/`recent`/`count`/`clear`/`color_of` |
| `src/conf.lua` | +4 lines: `MESSAGE_LINES`, `MESSAGE_LINE_HEIGHT`, `MESSAGE_ORIGIN_X`, `MESSAGE_ORIGIN_Y` |
| `src/game.lua` | +`require "message"`, `game.render_messages()`, one call in `render()`, 1–2 demo `Message.add` calls |
| everything else | **untouched** |

---

## 5. Why this shape

- **The brief maps 1:1 onto three mechanisms**: append = `Message.add`, latest N = `Message.recent(conf.MESSAGE_LINES)`, colours per entry = `types[type].color` with an optional override. Nothing extra is built.
- **It copies the tile system's proven pattern** (fact 4): a module-local `defs`-style table keyed by type, colours as `{r,g,b}`, drawing in `game.lua`, colour reset after use. A reader who knows `tile.lua` already knows `message.lua`.
- **History is kept, the view is a tail**: unbounded storage + `recent(N)` gives "history" and "latest N" without ring-buffer bookkeeping; rendering the tail each frame is correct *because* the frame is cleared each frame (fact 2) — no dirty tracking.
- **Types are a shared vocabulary, not per-call RGB**: systems say `"combat"`/`"warning"`, and the palette can be retuned in one table. The per-entry `color` override keeps the rare special case possible with one `or`.
- **Everything is conf-driven**: N, line height, and position are data, so tuning the panel is not a code change — the same reasoning that produced `conf.CAMERA_*` and `conf.WALL_DEPTH`.
- **It is headless-testable and future-proof**: no `love` in the module; the API (`add`/`recent`) is what the Item/Mob/Combat systems will call.

---

## 6. Afterwards (future roadmap hooks, not part of this change)

- **Command Pattern and Time System** (next README item) — turn actions into commands that emit messages; `Message.add` is the sink. Message *types* line up with command outcomes (`combat`, `good`, `warning`, `bad`).
- **Item / Mob / Construct Spawn systems** — spawn and pickup events call `Message.add`, e.g. `Message.add(string.format("You found a %s.", name), "good")`.
- **Scrolling / full-history view** — add `Message.recent()` with no argument (already returns all) plus a key binding in `main.lua` to toggle a full-screen or paged view; the storage already keeps everything.
- **Wrapping & measurement** — if lines exceed the panel width, wrap with `love.graphics.getFont():getWrap(text, width)` at draw time; the module stays unchanged because wrapping is a rendering concern.
- **Repetition merging** ("You hit the rat. (x3)") — a small post-process on append (if the new entry matches the last, bump a counter); decide then whether the counter lives on the entry or is derived at draw time.
- **Save & Load** (Queued) — serialize `history` as-is; entries are plain tables of strings/numbers.
- **More Organized UI System** (Queued) — this module is the first "widget"; a future UI layer can own placement while `message.lua` keeps owning the data, exactly as split here.
- **Fonts for ASCII Mode** (Improvements) — when a custom font lands, `MESSAGE_LINE_HEIGHT` and the origin are the only numbers to revisit.

---

## 7. TL;DR

Add `src/message.lua`: an append-only `history` array, a `types` table mapping type name → `{ color = {r,g,b} }` (mirroring `tile.lua`'s `defs`), and the API `Message.add(text, type[, color])`, `Message.recent(n)`, `Message.count()`, `Message.clear()`, `Message.color_of(entry)`. Add `conf.MESSAGE_LINES` (the configurable N) plus line-height/origin knobs. In `game.lua`, add `game.render_messages()` — draw `Message.recent(conf.MESSAGE_LINES)` oldest-at-top/newest-at-bottom, one `setColor`/`print` per entry, then reset to white — and call it after the HUD; wire one startup line and one on-move line as a live demo. History is unbounded (keeping it *is* the requirement), the on-screen view is just its tail, and because the frame is cleared each frame the tail is redrawn with no caching or dirty flags. Colours come from the entry's type by default with an optional per-entry override, so "different types ⇒ different colours per entry" is declarative at the call site. Diff: 1 new file + ~4 lines in `conf.lua` + ~15 lines in `game.lua`; `dungeon.lua`, `player.lua`, `camera.lua`, `main.lua`, `tile.lua` and `map/*` untouched, and the module is pure Lua so it tests headless with `lua check_message.lua`.
