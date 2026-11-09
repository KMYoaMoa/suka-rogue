# Decisions:

Use MVC Design Pattern

Composition Over Inheritence
- prefering A has B over A is B
- do inheritence only when it is inevitable

Write Minimal Code for New Feature
- don't overdesigning things
- avoid thinking ahead, strictly follow the scope

## Architecture

- `core/`: game-agnostic mechanics (scheduler, RNG, stable config).
- `content/`: data-only definitions (items, mobs, NPCs, constructs, rooms, biomes, tiles, palettes).
- `game/`: application/game-level aggregates and use cases (Game, World, turn/input orchestration, messages, presentation, spawn/inventory commands).
- `modules/`: feature modules with public facades (player, actors, items, combat, ai, vision, dungeon).
- `ui/`: input mapping, camera, and views. `love.*` belongs in `ui/` and `main.lua` only.
- `services/MessageService.lua` is a compatibility message port over `game/MessageLog`; new code should prefer the game/module facade.

## Tests

Run the behavior baseline with:

```sh
./tests/run-tests.sh
```
