# towerdefensecc

A 2D tower defense prototype made in Godot 4.7 with GDScript.

## What it does

Slimes walk a winding path across a graveyard map toward your base. You start with 100 gold and 10 HP, each slime that reaches the end costs 1 HP, and you win by surviving 10 waves. Killing a slime pays 5 gold.

Six build pads sit along the path. Click one to open a radial menu and buy a tower:

| Tower | Cost | Damage | Shots/s | Range | Notes |
|---|---|---|---|---|---|
| Archer | 30 | 4 | 2.5 | 110 | targets the closest enemy |
| Mage | 70 | 50 | 0.4 | 260 | magic damage, ignores armor |
| Artillery | 90 | 35 | 0.5 | 190 | targets the strongest enemy |
| Barracks | 60 | | | | every 10 s sends soldiers to the path, up to 3 alive at once |

Physical damage is reduced by the enemy's flat armor (2), so the archer's 4 damage lands as 2. Two basic turrets are already placed when the level starts.

Other controls:

- Click a placed tower to show its range and a radial menu. From there you can switch its targeting (first on the path, last, or strongest) or sell it for half its cost.
- Right-click to move the hero. The hero and barracks soldiers fight in melee, and an enemy stops to fight the first free ally within reach, so allies hold the path.
- Hero Ability makes the hero invulnerable and attack 25% faster for 5 s.
- Rain of Fire arms an area spell. Click the map to deal 40 magic damage in a radius, or right-click to cancel. It has a 10 s cooldown.
- Between waves, Start Wave calls the next wave early for 15 bonus gold. 2x Speed toggles fast-forward.

Winning awards stars: 3 for finishing at full HP, 2 at half or more, 1 otherwise. In the main menu, stars buy permanent upgrades to archer fire rate, barracks soldier HP, mage damage and artillery range (+10% per level, 5 levels each). Progress is saved to `user://save.cfg`.

## How it works

Four autoloads hold global state:

| Autoload | Job |
|---|---|
| `Grid` | cell math only (`cell_to_world`, `world_to_cell`, 64 px cells) |
| `GameManager` | base HP, gold and the current wave; emits `health_changed`, `gold_changed`, `wave_started`, `game_over` |
| `ScreenShake` | trauma-based camera shake, triggered by heavy hits |
| `Upgrades` | stars and upgrade levels, loaded from and saved to `user://save.cfg` |

Gameplay events reach player state through one path:

```
Enemy.died(gold_reward) ─┐
Enemy.reached_end ───────┴─► WaveManager ─► GameManager.add_gold / take_damage ─► signals ─► HUD
```

Enemies and towers never call `GameManager` directly. The HUD listens to `GameManager`'s signals and finds the hero, spell manager and wave manager through node groups (`get_first_node_in_group`) instead of exported node references. Other systems use the same lookup pattern.

- The level stores only the path's turn points (`path_cells` in `level.gd`). At startup it walks the straight runs between them and paints grass and path tiles onto a `TileMapLayer`, with each 64 px gameplay cell drawn as a 4×4 block of 16 px tiles.
- `WaveManager` runs one serial loop: spawn 5 enemies 0.8 s apart, wait until all of them have died or escaped, then start a between-waves timer. Start Wave stops that timer early.
- A tower is an `Area2D` whose collision mask is physics layer 2 (named "enemies"). It builds its range circle from `range_radius` at runtime, fires on a `Timer`, and picks a target from the enemies in range by its targeting mode. Archer, Mage and Artillery are variants of `tower_basic.tscn` with their own stats.
- Scripts look up child nodes by name (`$NodeName`, `@onready`), so renaming a node in a `.tscn` breaks its script.

## Tech stack

| Area | Tools |
|---|---|
| Engine | Godot 4.7, Forward Plus renderer |
| Language | GDScript |
| Art | Craftpix free packs: swordsman sprites (hero and soldiers), slime mobs, undead tileset |

There are no plugins, packages or build steps.

## Run

1. Install [Godot 4.7](https://godotengine.org/download) (the standard build; the project has no C#).
2. In the Godot project manager, choose Import and select `project.godot`.
3. Press F5. The game opens on the main menu.

## Project layout

```
scenes/      levels, towers, enemies, allies, hero, spells, menus, HUD (.tscn)
scripts/     GDScript, one folder per scene type; autoload/ holds the four singletons
resources/   tilesets and sprite animation frames
assets/      Craftpix sprite packs (PNGs only)
```

## Status

A playable prototype with one level and one enemy type. Waves do not get harder: every wave is 5 slimes with the same stats. Towers and projectiles are placeholder colored shapes, while the hero, soldiers and slimes are animated sprites. There are no automated tests; the game is checked by playing it.

## Credits

Sprites and tiles are free packs from [Craftpix](https://craftpix.net), used under the [Craftpix license](https://craftpix.net/file-licenses/). Each pack's folder under `assets/` includes its `License.txt`.
