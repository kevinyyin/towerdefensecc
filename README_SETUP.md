# Setup Guide — Core Systems (Milestone 2)

This describes the scene tree as it exists in the project right now, so you can rebuild or extend it by hand in the editor if needed.

## Scene tree

```
Main.tscn                          (Node2D, no script)
└── Level1  [instance of level_1.tscn]

level_1.tscn                       Level1 (Node2D, level.gd)
├── TileMapLayer                   visual grid, painted at runtime from path_cells
├── EnemyContainer (Node2D)        WaveManager spawns enemies here
├── WaveManager (Node, wave_manager.gd)
├── Tower1        [instance of tower_basic.tscn]
└── Tower2        [instance of tower_basic.tscn]

enemy.tscn                         Enemy (CharacterBody2D, enemy.gd)
├── CollisionShape2D                 CircleShape2D, radius 14, on physics layer "enemies" (layer 2)
└── Visual (Polygon2D)                red square placeholder

tower_basic.tscn                   Tower (Area2D, tower.gd)
├── CollisionShape2D                 shape built at runtime from range_radius, mask = "enemies"
├── Visual (Polygon2D)                blue square placeholder
└── Cooldown (Timer)                  fire-rate timer, started from script

projectile_basic.tscn              Projectile (Node2D, projectile.gd)
└── Visual (Polygon2D)                small yellow dot
```

Autoloads (Project → Project Settings → Autoload): `Grid` (`scripts/autoload/grid.gd`), `GameManager` (`scripts/autoload/game_manager.gd`).

## Building it by hand

If you're recreating a piece of this in the editor instead of using the files directly:

1. Create the node with the type shown above (e.g. `Area2D` for a tower).
2. Select it, open the Script tab, and **Attach Script** pointing at the matching `.gd` file (e.g. `res://scripts/towers/tower.gd`).
3. Add the children listed under it (`CollisionShape2D`, `Visual`, `Cooldown`, etc.) with the same names — scripts look up children by name via `$NodeName`, so the names have to match exactly.
4. Save the scene as a `.tscn` in the matching `scenes/<feature>/` folder.

## Physics layers

Layer 2 is named **"enemies"** in Project Settings → Layer Names → 2D Physics, so it shows up as a labeled checkbox instead of a bare number.

- `Enemy` sets `collision_layer = 2` (it *is* on the enemies layer) and `collision_mask = 0` (it doesn't need to detect anything itself).
- `Tower`'s `Area2D` sets `collision_mask = 2` (it *detects* the enemies layer) and `collision_layer = 0` (nothing needs to detect the tower).

Because of this, Tower's `CollisionShape2D` doesn't need a shape assigned in the editor — `tower.gd` builds a `CircleShape2D` from `range_radius` at runtime in `_ready()`. Change `range_radius` in the Inspector and the actual detection area updates automatically.

## Signal chain, end to end

```
Enemy.died(gold_reward) ─┐
Enemy.reached_end ───────┼─→ WaveManager (_on_enemy_died / _on_enemy_reached_end)
                          │        │
                          │        ├─→ GameManager.add_gold(gold_reward)
                          │        └─→ GameManager.take_damage(1)
                          │
                          └─→ decrements WaveManager._active_enemies (drives when a wave is "cleared")

GameManager mutates state and emits its own public signals:
  health_changed(current_hp, max_hp)
  gold_changed(new_gold)
  wave_started(wave_number)
  game_over
```

`Enemy` and `Tower` never talk to `GameManager` directly — only `WaveManager` does. A future HUD only needs to connect to `GameManager`'s four signals; it doesn't need to know `Enemy` or `WaveManager` exist.

## Testing

1. Open the project in Godot 4.7, press **F5** (or run `main.tscn`).
2. Enemies spawn from the path's start cell in waves (5 per wave by default, one every `spawn_interval` seconds), walk the tan path tiles, and the two blue towers fire yellow projectiles at whichever enemy is targeted by their `targeting_mode` (default: furthest along the path).
3. Watch the Output panel — a killed enemy's gold is added to `GameManager.gold`, and an enemy that reaches the end reduces `GameManager.base_hp`. Add a temporary `print()` in `GameManager`'s signal handlers if you want to see the numbers change live before a HUD exists.

## Not built yet (intentionally)

- Tower placement UI / spending gold to place towers — `Tower1`/`Tower2` are just static test instances in `level_1.tscn` right now.
- Wave-to-wave difficulty scaling — `WaveManager`'s `enemies_per_wave`/`spawn_interval` are flat; ramping them per `current_wave` is a small addition to `_run_waves()` when you're ready.
- A HUD — connect a `Control`/`Label` scene to `GameManager`'s `health_changed`/`gold_changed`/`wave_started`/`game_over` signals.
