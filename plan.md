# Isometric tilt, fast-forward, early wave start, radial tower menu

## Context

Four requested features, bundled in one message. The biggest one — "isometric top-down view" — could mean either a cheap visual trick or a full grid-system rewrite; confirmed with the user they want the **cheap camera-tilt trick**, not a true isometric tile/coordinate conversion (no new art, no Grid math changes, no risk to existing pathing/placement/click logic). The other three (fast-forward, early wave start with bonus gold, radial tower context menu) are smaller, independent additions that follow patterns already established in this codebase (group-lookup HUD wiring, `Timer`-based interruptible waits, world-anchored `Control` popups).

## Feature 1: Isometric-look camera tilt

Tilt the `Camera2D` in [scenes/main/main.tscn](scenes/main/main.tscn) only — nothing else. `Camera2D` is already a sibling of `Level1`, isolated from the gameplay tree.

- `rotation = deg_to_rad(45)` (flip sign if it looks backwards once visible)
- `zoom = Vector2(1.0, 0.5)` (classic 2:1 dimetric squash; widen toward 0.6 if too flat)
- **`ignore_rotation = false`** — this defaults to `true` in Godot 4 and silently no-ops the whole feature if left unset. Must be explicit.

Why camera-only is safe: `Grid.cell_to_world`/`world_to_cell`, all `CharacterBody2D` movement (enemy/ally/hero), tower range/targeting math, and Area2D click-picking (build pads, tower `ClickArea`) never read through the camera — they operate on `global_position` in the untouched orthogonal space under `Level1`. A `Camera2D` transform only affects the viewport's final render and its inverse-projection for mouse un-projection (which Godot already handles automatically for both physics picking and `get_global_mouse_position()`), so nothing in `hero.gd`, `build_pad.gd`, `tower.gd`, or `spell_manager.gd` needs to change.

Two things **will** visually tilt along with everything else, and that's accepted rather than fixed here: unit shapes (flat `Polygon2D`s on enemy/ally/hero — fine, they're simple flat colors, not detailed sprites) and world-anchored `Control` popups (`build_pad.gd`'s `Menu`, and the new radial tower menu in Feature 4, plus `health_bar.gd`'s bars) — since `Control` is a `CanvasItem` like `Node2D` with no special-casing, it renders through the same tilted camera transform. This is purely cosmetic (input un-projection still works correctly), and keeps this feature to a single-node change. Not doing per-unit counter-rotation — added complexity not worth it for flat placeholder shapes.

HUD (`CanvasLayer`) is unaffected by design — Godot renders `CanvasLayer` content independent of the active camera transform.

## Feature 2: Fast-forward 2x toggle

New `FastForwardButton` in [hud.tscn](scenes/ui/hud.tscn)'s `AbilityBar`. In [hud.gd](scripts/ui/hud.gd), a local bool toggles `Engine.time_scale` between `1.0`/`2.0` and updates the button's label. No new autoload — every `Timer` node and every delta-based movement script in the project already respects `Engine.time_scale` automatically (confirmed no code anywhere uses time-scale-immune ticking like `Time.get_ticks_msec()`).

## Feature 3: Early wave start with bonus gold

`wave_manager.gd`'s between-wave wait currently uses an uncancellable `get_tree().create_timer(...).timeout`. Since the spawn-then-drain-to-zero sequence always finishes *before* that wait begins (confirmed — strictly serial, no overlapping-wave support needed), only that one wait needs to become interruptible.

- **Promote `WaveManager` to its own packed scene** `scenes/waves/wave_manager.tscn` (`Node` root + a `BetweenWaves` `Timer` child, `one_shot = true`) — mirrors how `spell_manager.gd` needed its own `.tscn` once it needed a child `Timer`. Update [level_1.tscn](scenes/levels/level_1.tscn) to instance it (`[node name="WaveManager" parent="." instance=ExtResource(...)]`) instead of attaching the script to a bare `Node`, preserving the `enemy_scene` export override exactly as today.
- `wave_manager.gd`: add `add_to_group(&"wave_manager")` (currently in no group — needed for the same HUD lookup pattern as `"spell_manager"`/`"hero"`), `signal waiting_for_next_wave(is_waiting: bool)`, `@export var early_start_bonus_gold := 15`.
- Replace the final `await get_tree().create_timer(time_between_waves).timeout` with a helper that starts `BetweenWaves`, emits `waiting_for_next_wave(true)`, and `await`s the timer's own `timeout` signal; emits `waiting_for_next_wave(false)` once resumed.
- New `start_next_wave_early() -> bool`: no-ops (returns `false`) if the timer isn't currently running (mid-spawn/mid-drain); otherwise stops it, grants `GameManager.add_gold(early_start_bonus_gold)`, and manually `.emit()`s `timeout` so the same `await` resumes immediately — one code path for both the natural and early-triggered continuation.
- HUD: new `StartWaveButton`, starts disabled, connects to `wave_manager.waiting_for_next_wave` to grey/brighten (same pattern as the Rain of Fire / Hero Ability cooldown buttons), and its `pressed` handler calls `start_next_wave_early()` via the group lookup.

## Feature 4: Radial context menu on tower click

- **Enum change** in [tower.gd](scripts/towers/tower.gd): `enum TargetingMode { FIRST_IN_PATH, CLOSEST_TO_TOWER, STRONGEST, LAST_IN_PATH }` — `LAST_IN_PATH` **must be appended at the end** (value `3`). Archer/Mage/Artillery already bake raw ints (`1`, `0`, `2`) into their `.tscn` files for the first three values; inserting anywhere else would silently reassign and corrupt those. `_select_target()` gets a new `LAST_IN_PATH` case: reduce to the *minimum* `path_progress` (the straggler, opposite of the existing default `FIRST_IN_PATH` max-progress case).
- Radial UI exposes exactly **3** targeting toggles — First / Last / Strongest, per the request. `CLOSEST_TO_TOWER` stays a valid mode (Archer ships pre-configured with it) but isn't reachable from the UI — a stated scope choice, not an oversight.
- New `scripts/towers/radial_menu.gd` + `scenes/towers/radial_menu.tscn`: a small `Node2D` holding 4 `Button`s (First/Last/Strongest/Sell) positioned in a ring via simple trig (`center + Vector2(radius, 0).rotated(angle)`, radius 60px — clear of the tower body, inside even the smallest range circle). Not true pie-slice wedges — Godot has no built-in wedge hit-testing, and a ring of ordinary buttons reads as "radial menu" just fine while reusing standard, already-proven click handling. The layout loops over however many buttons exist, so it "leaves space" architecturally — future items just get added to the array, no layout code changes needed.
- Active targeting mode shown via `button.disabled = true` on whichever of the 3 targeting buttons matches `tower.targeting_mode` (Godot's default disabled styling gives a free, clear "active" look; also conveniently blocks redundant clicks). Sell is never disabled.
- Sell: `GameManager.add_gold(int(tower.cost * 0.5))` (50% refund) then `tower.queue_free()`. Confirmed sufficient — no other system holds a persistent reference to a specific tower instance (projectiles track their target enemy, not the firing tower; the `"towers"` group lookup is on-demand).
- Wired into the **existing** click/dismiss plumbing rather than a parallel system: `_on_click_area_input_event` also toggles `_radial_menu.visible` alongside `_show_range` (both open/close together — useful to see range while deciding to retarget/sell), and `hide_range()` (already called by `_unhandled_input`'s dismiss-elsewhere and `_close_other_towers()`'s mutual-exclusivity) also hides the menu — zero new dismiss logic required.
- Added to `tower_basic.tscn`/`archer.tscn`/`mage.tscn`/`artillery.tscn` only — **not** `barracks.tscn`, which is a separate `Node2D` spawner with no click detection or targeting concept at all.

## Critical files

- [scenes/main/main.tscn](scenes/main/main.tscn) — Camera2D tilt
- [scripts/waves/wave_manager.gd](scripts/waves/wave_manager.gd) + new `scenes/waves/wave_manager.tscn`
- [scenes/levels/level_1.tscn](scenes/levels/level_1.tscn) — WaveManager becomes a scene instance
- [scripts/towers/tower.gd](scripts/towers/tower.gd) — enum, targeting case, radial menu wiring
- New `scripts/towers/radial_menu.gd` + `scenes/towers/radial_menu.tscn`
- [scripts/ui/hud.gd](scripts/ui/hud.gd) + [scenes/ui/hud.tscn](scenes/ui/hud.tscn) — 2 new buttons + group-lookup wiring

## Verification

1. Structural checks via `mcp__godot-editor__open_scene`/`list_nodes`/`get_node_properties` for each new/changed node (Camera2D properties, `BetweenWaves` timer, `WaveManager` as scene instance, `RadialMenu` under all 4 tower scenes, new HUD buttons) — catches wiring mistakes before ever running the game. Specifically double-check the `TargetingMode` enum text reads `{ FIRST_IN_PATH, CLOSEST_TO_TOWER, STRONGEST, LAST_IN_PATH }` in that exact order, since a wrong order silently corrupts the three towers' baked-in int overrides.
2. Forced reload (`EditorInterface.reload_scene_from_path` / `ResourceLoader.load(..., CACHE_MODE_REPLACE)`) of every touched scene/script, then `EditorInterface.play_main_scene()` and read `~/Library/Application Support/Godot/app_userdata/towerdefensecc/logs/godot.log` for a clean boot — catches `@onready` path typos and the manual-`.emit()` timer pattern misfiring.
3. Needs the user's own eyes (no click/screenshot access in this sandbox): whether the 45°/0.5-zoom tilt actually looks like a convincing isometric view or needs sign/ratio tuning; whether pads/towers/hero-move still feel natural to click under the tilt; radial menu button spacing/legibility at the tilted scale; watching one full wave cycle to confirm the early-start button greys/brightens at the right moments.
