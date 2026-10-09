# Biome System — Suggestions & Integration Notes

> Branch: `biome-system` · Draft spec: `docs/draft/Biomes.md` · README plan item: "Biome/Room-Type System"
>
> Status: **mostly implemented on this branch** (connected edges, prune + biome assign inside `MapFactory.create`, new `src/map/Biome.lua`). Two items remain open:
> 1. **keep-largest-component logic** — see `docs/aigc/largest-connected-component.md`
> 2. **headless test script** — instructions in that document's §6
>
> Translation of the draft:
>
> > A biome consists of 1–3 adjacent rooms. Generation logic: randomly pick a room, roll an integer `1..min(3, available neighbours)` as the biome size, then randomly pick adjacent rooms for the same biome. This may require **improving the dungeon generation logic** so we can **accurately tell whether two rooms are connected by a path**, and **delete rooms that cannot be connected**. Placeholders like `BiomeA` are fine. For now only the room→biome mapping matters; how biomes affect tiles is a tile-system problem.

---

## 1. Where we are now

### Merged BSP integration (master)

- Map modules live in `src/map/` (`Cell`, `Map`, `Path`, `MapFactory`); `conf.SIZE_X/Y = 30/15`, `min_dimension = 3`, `num_rooms = 8`.
- `dungeon.lua` carves the dense tile grid from `map.cell_list` + `map.path_list`, then keeps `dungeon.rooms = map.cell_list`, `dungeon.paths = map.path_list`.
- `player.lua` spawns at the center of `dungeon.rooms[1]`.
- Rendering: 30×15 tiles at 32 px each (`TILE_SIZE = 32`; the 2× transform up-scales the default **16 px font** to tile size) → **960×480**, comfortably inside the 1280×720 window. (Earlier drafts claimed an overflow here — wrong; corrected. The unused `game.camera` block was removed on this branch.)

### Implemented on this branch

| Change | File |
|---|---|
| `connected = {}` field (rooms actually joined by a corridor), with a comment that `h/v_neighbours` does **not** guarantee eventual connection | `src/map/Cell.lua` |
| `add_path` records `i.connected ⧺ j` both ways every time it creates a corridor | `src/map/MapFactory.lua` |
| `prune_unreachable(map)` (BFS from `cell_list[1]`, keeps the larger of the two sets) runs before biome assignment | `src/map/MapFactory.lua` |
| `Biome:assign(map)` — 1–3-room contiguous clusters over `connected`, round-robin `BiomeA…BiomeE` | new `src/map/Biome.lua` |
| `create()` order: `divide → … → add_path → prune → assign` | `src/map/MapFactory.lua` |
| Removed dead code: `GRID_SIZE` global, `Map:display()`, unused `game.camera` | `Cell/Map/game.lua` |

Design note: pruning inside `MapFactory` is neater than the earlier "return dead rooms, let `dungeon.lua` seal the grid" suggestion — the returned product never contains unreachable rooms and `dungeon.lua`/`player.lua` stay untouched. Agreed.

### Open issue (why we're here)

`prune_unreachable` needs a root, and a root is the wrong tool: you want to keep the **largest connected component**, regardless of where `cell_list[1]` sits. The current pairwise max (`#out1 > #out2`) is only correct for ≤ 2 components — with 3+ components it returns a disconnected union, and on ties it arbitrarily drops the root's own component. **The full analysis, correct algorithm and required cleanup (cell_list / connected / path_list) are in `docs/aigc/largest-connected-component.md`.**

---

## 2. Measurements (what prompted the connectivity work)

Ran the merged `MapFactory` 300 times (30×15, min_dim 3, 8 rooms), rasterized, flood-filled, and cross-checked every geometric neighbour pair against actual corridor creation:

| Metric | Result |
|---|---|
| Maps with a fully reachable dungeon (tile flood-fill = room-graph connectivity) | 300 / 300 |
| Geometric neighbour pairs checked | 3685 |
| Pairs that lost overlap after shrinking → **no corridor** | 162 (**4.40 %**) |

Interpretation:
- **Room-graph fragmentation never occurred in these 300 runs** — "delete unreachable rooms" is currently a safety net, not a live path. It becomes a *live* path when parameters change (more rooms, bigger `min_dimension`, future experiments).
- **Pair-level inaccuracy is real (4.40 %)**: `h_neighbours` ≠ "connected by a path". Clustering on raw adjacency would occasionally join two rooms with a wall between them. This is exactly why `connected` is recorded at corridor-creation time.

About the seeds: the headless run called `math.randomseed(os.time())` **once per process**, so the 300 iterations consumed one continuing random stream — not 300 identical restarts. (Caveat that prompted the comment: two *separate* processes launched within the same second — e.g. running the game twice quickly — re-seed to the same value and produce identical maps, because LÖVE seeds `math.random` from `os.time()` too. The follow-up doc's test therefore iterates **explicit seeds** per map, which is reproducible and unambiguous.)

---

## 3. Options (as of the current implementation)

### 3.1 Accurate room↔room connectivity — ✅ done

| Option | Status |
|---|---|
| **A. Record `connected` at corridor creation (chosen)** | implemented — 2 lines in `add_path` + field in `Cell:new`; exact by construction |
| B. Infer from `path_list` (rect matching) | not needed |
| C. Flood-fill the tile grid (reachability only) | still useful, but only as an integrity check in the test harness (§6 of the follow-up doc) |

### 3.2 Handling "rooms that cannot be connected" — partially done

| Option | Status |
|---|---|
| **A. Prune inside `MapFactory` (chosen — product never contains dead rooms)** | implemented, but the keep-larger logic is **wrong for ≥ 3 components / ties** → fix per the follow-up doc (includes cleaning `connected` and filtering `path_list`, or `Biome:assign` can still reach discarded rooms) |
| B. Seal back to `"#"` in `dungeon.lua` (earlier suggestion) | superseded by A — less neat, drops the map/grid separation |

### 3.3 Biome clustering — ✅ done (`src/map/Biome.lua`)

Cluster growth over `connected`: contiguous by construction (each added room shares a corridor with the cluster), size `math.random(1, 3)` with early stop when candidates run out — equivalent to the draft's `min(3, available)` formula. Only caveat inherited from the open prune issue: with stale `connected` lists, `available_neighbours` can return discarded rooms (they're never in `assigned`), so clusters could include rooms outside `cell_list` — fixed by the connected-list cleanup in the follow-up doc.

### 3.4 Storage & placement — ✅ done

`room.biome` field; `BIOME_TYPES = {BiomeA…BiomeE}` assigned round-robin (small fixed set, ready to grow into real biome definitions when the tile system lands). Module `src/map/Biome.lua` mirrors the other map modules — better than an earlier in-`dungeon.lua` idea.

---

## 4. Remaining work (checklist)

- [x] `connected` recorded in `add_path`
- [x] prune + biome assign inside `MapFactory.create`
- [x] `Biome.lua` cluster growth
- [x] dead-code cleanup (`GRID_SIZE`, `Map:display()`, `game.camera`)
- [ ] **keep-largest-component logic** — replace the pairwise `#out1 > #out2` body; together with it: rebuild kept cells' `connected`, filter `path_list` corridors by endpoints → `docs/aigc/largest-connected-component.md`
- [ ] **headless test script** — seeded-per-iteration checks (single component, biome invariants, contiguity, no corridor stubs, spawn validity) → `docs/aigc/largest-connected-component.md` §6

---

## 5. Edge cases & notes (updated)

- `num_rooms = 8` on 30×15 can occasionally fail to partition fully — `MapFactory` caps attempts (`MAX_ATTEMPTS_PER_ROOM = 50`, prints a warning). Biomes iterate the actual `cell_list`, never assume a count.
- Clusters/biomes walk `connected` only; `h_neighbours`/`v_neighbours` stay as pure geometry (future doors/décor).
- With prune inside `MapFactory`, the carving in `dungeon.lua` is automatically consistent **as long as `path_list` is filtered too** — otherwise floating corridor stubs get carved between kept rooms and the void (follow-up doc §3.3).
- Spawn stays valid after keep-largest: `dungeon.rooms[1]` is always a kept room (original order, minus pruned). Don't rely on it still being the leftmost BSP leaf.
- Randomness: unseeded `math.random` at game level → new dungeons/biomes per launch; seed explicitly (e.g. per-run seed or high-resolution timer) if you need reproducible runs — separate from the test's per-iteration seeding.
- Future hooks: tile system will need tile→biome lookup (`dungeon.biome_at(x, y)` point-in-rect over the ~8 rooms) or a precomputed per-tile map; `BIOME_TYPES` is where biome definitions (palette/rules) will grow.

---

## 6. TL;DR

BSP integration is in; on this branch the biome system is implemented the clean way (record `connected` at corridor creation; prune + assign inside `MapFactory.create`, so `dungeon.lua` never sees dead rooms). Corridor-connectivity is real and measured (4.40 % of geometric pairs end up walled apart). **One logic bug remains**: the prune keeps the larger of *two* sets, which is wrong for ≥ 3 components and on ties — switch to the largest-component algorithm and do the three coordinated cleanups in `docs/aigc/largest-connected-component.md`, then add the seeded headless test from that document's §6.