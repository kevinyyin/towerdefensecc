# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Godot 4.7 (Forward Plus) tower-defense prototype written entirely in GDScript. There is no external build system, package manager, or test suite — the project runs and is verified inside the Godot editor.

## Running / testing

- Open the project in **Godot 4.7** and press **F5** (or run `scenes/main/main.tscn` directly). There is no headless test command — verification is playing the game and reading editor Output/log.
- The `Godot MCP` editor plugin (`addons/godot_mcp/`) is enabled in `project.godot` and exposes `mcp__godot-editor__*` / `mcp__godot__*` tools (open/list/edit scenes, run/stop the project, read debug output). Prefer these over hand-editing `.tscn` files when making structural scene changes, and use `get_debug_output` / the Godot log instead of asking the user to check the editor.
- Log file for a running instance: `~/Library/Application Support/Godot/app_userdata/towerdefensecc/logs/godot.log`.
- No linter/formatter is configured; `.editorconfig` only sets UTF-8. Match existing GDScript style (tabs for indentation, `snake_case` functions/vars, `@export`/`@onready` typed vars, `signal` declared at top of file).

## Architecture

### Autoloads (global singletons, `project.godot` `[autoload]`)
- `Grid` (`scripts/autoload/grid.gd`) — pure coordinate math, `CELL_SIZE = 64`. `cell_to_world`/`world_to_cell` only; no state.
- `GameManager` (`scripts/autoload/game_manager.gd`) — owns `base_hp`, `gold`, `current_wave`, `is_game_over`. Emits `health_changed`, `gold_changed`, `wave_started`, `game_over`. This is the single source of truth for player-facing state; other systems call `GameManager.add_gold()` / `spend_gold()` / `take_damage()` rather than mutating state themselves.
- `ScreenShake` (`scripts/autoload/screen_shake.gd`) — trauma-based camera shake. A camera calls `register_camera()`; anything can call `ScreenShake.shake(amount)` (e.g. `enemy.gd` on a heavy hit).

### Scene tree shape
```
main.tscn (Node2D, Camera2D)
└── Level1 [instance of level_1.tscn]
    ├── TileMapLayer          painted at runtime from level.gd's path_cells
    ├── EnemyContainer        WaveManager spawns enemies here
    ├── TowersContainer       build_pad.gd spawns purchased towers here
    ├── AlliesContainer       barracks.gd / hero spawn allies here
    ├── WaveManager           wave_manager.gd
    ├── BuildPad instances    build_pad.gd (Area2D, click → tower-purchase menu)
    ├── Tower instances       tower_basic / archer / mage / artillery / barracks
    └── SpellManager, Hero, HUD (CanvasLayer)
```
Scripts look up children with `$NodeName` / `@onready`, so child node names in a `.tscn` must exactly match what the script expects — renaming a node breaks the script silently until run.

### Group-based lookup, not direct references
Systems find each other via `get_tree().get_nodes_in_group(...)` / `get_first_node_in_group(...)` rather than exported node references. Groups in use: `"enemies"`, `"allies"`, `"hero"`, `"towers"`, `"build_pads"`, `"level"`, `"spell_manager"`, `"wave_manager"`. When adding a new interactive system, add it to a group in `_ready()` and look up collaborators the same way — this is the established pattern (see `hud.gd`'s lookups of `"spell_manager"`/`"hero"`, `barracks.gd`'s lookup of `"level"`).

### Signal chain (gameplay → player state)
`Enemy.died(gold_reward)` / `Enemy.reached_end` are only consumed by `WaveManager`, which then calls into `GameManager`. `Enemy` and towers never touch `GameManager` directly — `WaveManager` is the sole intermediary for wave/combat outcomes reaching player state. HUD only listens to `GameManager`'s signals plus the `"spell_manager"`/`"hero"` group signals; it has no direct knowledge of `Enemy`/`WaveManager`.

### Combat
- `damage_type.gd` defines `DamageType.Type { PHYSICAL, MAGIC }`. Enemies mitigate `PHYSICAL` damage by `armor`; `MAGIC` is unmitigated. Towers/spells pass their `damage_type` through to `enemy.take_damage(amount, damage_type)`.
- `tower.gd` (`Area2D`, mask = physics layer 2 "enemies") tracks enemies in range via `body_entered`/`body_exited`, fires on a `Cooldown` `Timer`, and targets via `TargetingMode` (`FIRST_IN_PATH` default, `CLOSEST_TO_TOWER`, `STRONGEST`) — `_select_target()`'s `reduce()` pattern is how new targeting modes should be added. Range circle drawn via `_draw()`, toggled on click through `ClickArea`; only one tower's range is shown at a time (`_close_other_towers()`).
- Archer/Mage/Artillery/Barracks are scene variants of `tower_basic.tscn` with different exported stats — check the `.tscn` for baked-in overrides before changing `tower.gd` defaults or enum ordering (enum int values are baked into scenes).
- `spell_manager.gd` is a click-to-cast AoE spell (Rain of Fire): `arm()` follows the mouse, left-click casts (damage in `radius`, triggers `spell_impact.tscn` VFX), right-click cancels, then a cooldown `Timer` gates re-arming.
- `hero.gd` / `ally.gd` are melee `CharacterBody2D` units that auto-engage the nearest enemy in `aggro_radius`, otherwise return to a move target (`hero`, right-click) or `rally_point` (`ally`, set by `barracks.gd`). Hero has a timed, temporary invulnerability + attack-speed ability (`activate_ability`); allies from Barracks despawn on a `lifespan` timer.
- `barracks.gd` spawns squads on an interval, capped by `max_alive` (tracked via `_living_allies` and each ally's `tree_exited` signal), rallying to the nearest point on the level path.

### Placement & waves
- `build_pad.gd` (`Area2D`) shows a purchase menu on click; on afford + purchase it instantiates the chosen tower into `TowersContainer` at the pad's position, then disables/hides itself (one tower per pad, non-refundable in current code).
- `wave_manager.gd` runs a single `while true` loop: spawn `enemies_per_wave` on `spawn_interval`, wait for all to die/finish (`_active_enemies == 0`), wait `time_between_waves`, repeat. It is strictly serial — waves never overlap.

### Physics layers
Layer 2 is named `"enemies"` in `project.godot` (`[layer_names]`). Enemies set `collision_layer = 2, collision_mask = 0`; towers' `Area2D` sets `collision_mask = 2, collision_layer = 0`. Tower range shapes are built at runtime from `range_radius` in `_ready()`, not authored in the editor — change the export, not the `CollisionShape2D`.

## Notes on repo docs

- [README_SETUP.md](README_SETUP.md) documents the milestone-2 scene tree/signal chain in more manual, step-by-step form (useful if rebuilding a scene by hand in the editor) — it predates towers/hero/barracks/spells and is partially superseded by this file.
- [plan.md](plan.md) is a design doc for a *not-yet-implemented* feature set (camera tilt, fast-forward, early wave start, radial tower menu). Don't assume anything it describes exists in the code — cross-check against the actual scripts first.
