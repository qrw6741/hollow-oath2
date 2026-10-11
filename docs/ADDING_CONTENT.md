# Adding Content

## A new attack
1. Duplicate a file in `data/attacks/` (e.g. `oathblade_heavy.tres`) and rename it.
2. In the Inspector set a unique `id` and tune the groups:
   - **Timing**: `startup_frames` (wind-up), `active_frames` (≥ 2), `recovery_frames`; `chain_open_frame` / `dodge_cancel_frame` (recovery-relative, `-1` = never).
   - **Damage**, **Hitbox** (offset is for facing right, from the feet), **Movement** (lunge), **Feel**.
   - Enemy attacks also use **AI** (range, weight, chain chance).
3. Reference it from a weapon or an enemy (below). Run the tests — `test_attack_data` validates every attack file.

## A new weapon class
1. Create attacks as above.
2. Right-click `data/weapons/` → New Resource → `WeaponData`; fill `light_combo_start` (chain more via each attack's `next_in_combo`), `heavy`, `aerial`, `riposte`.
3. Assign it to the Player scene's `weapon` export (equipment menu comes in M7).
4. Add a pose key for any new `animation` value in `player_visual.gd → SWINGS` (until real sprites exist).

## A new enemy variant (same behaviour, different numbers)
1. Duplicate `data/enemies/hollow_penitent.tres`, adjust stats/attacks.
2. In a level, add an `EnemySpawner` with `enemy_scene = hollow_penitent.tscn` and `data_override = <your .tres>`.

## A new enemy type (new behaviour)
1. New script `extends EnemyBase`; override `choose_attack()` and any `on_*` hook.
2. Duplicate `hollow_penitent.tscn`, swap the root script and the `Visual` node.
3. Keep the child names `Health`, `Hurtbox`, `Hitbox`, `AttackRunner` — EnemyBase looks them up.

## A new preset (starting loadout)
1. Create attack `.tres` files in `data/attacks/` and a weapon in `data/weapons/` (or reuse an existing weapon).
2. Duplicate a file in `data/presets/`, set id, text, stats, `weapon`, colours, `armor_look` and `weapon_look`. Use `PackedStringArray("a", "b")` (no brackets) for `perks`/`drawbacks`.
3. Add the id to `Presets.IDS` in `systems/presets.gd` (order = order on the selection screen).
4. If you need a new attack animation key, add its pose to `player_visual.gd` (`SWINGS`, `TWIN` or `FISTS`).
5. Run the tests: `test_presets_valid` and `test_each_preset_combo_lands` cover every registered preset automatically.

## A new item
1. Duplicate a file in `data/items/`; set id, text, kind, effect, amount, stack size, colour.
2. Add the id to `Items.IDS` in `systems/items/items.gd` (order = order in the pack).
3. To place it in a level: add an `ItemPickup` (Area2D with `world/pickups/item_pickup.gd`), assign `item`, `count` and a **unique** `pickup_id` (it becomes the saved "taken" flag).
4. To drop it from an enemy: set `drop_item`, `drop_chance`, `drop_count` in that enemy's `.tres`. Embers: `ember_reward`.
5. New effects: add to `ItemData.Effect` and handle in `Items.use`.

## A new level
1. New scene, root `Node2D` with `world/levels/level.gd`. Set `level_id`, `display_name`, `bounds`, `default_spawn`.
2. Build terrain with `StoneBlock` nodes (set `size`; tick `one_way` for platforms).
3. Add hazards (`SpikePit`), `OathCandle` instances (unique `checkpoint_id`), `EnemySpawner`s.
4. Background: copy the `Background` ParallaxBackground from `test_arena.tscn` and change seeds/colours.
5. Point `Main.start_level` at it (room transitions arrive in M8). Levels must live in `res://world/levels/` — saves only accept paths there.
6. Anything that must persist (boss defeated, shortcut opened): `GameState.set_flag(&"name", true)` / `get_flag(&"name")`. Flags are saved automatically at the next autosave. See "Persistence" in `docs/ARCHITECTURE.md` before adding other kinds of saved data.

## Checklist after any content change
- Run `res://tests/run_tests.tscn` (must end with 0 failed; currently 31 tests).
- Do the relevant part of `docs/TESTING_CHECKLIST.md`.
- Log it in `DEVELOPMENT_LOG.md`; record placeholders in `KNOWN_ISSUES.md`.
