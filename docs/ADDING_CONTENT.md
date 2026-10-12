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

## Flying, shielded and mimic enemies
- **FlyingEnemy** (`actors/enemies/flying_enemy.gd`, e.g. `gloam_moth.tscn`): gravity is off except when staggered / parried / dead. Place its spawner in the air (that point is its home). Tune `hover_height`, `hover_side`, `dive_speed`; the dive attack's `active_frames` is the dive length.
- **ShieldEnemy** (`oathguard.tscn`): frontal hits while not mid-swing are BLOCKED and drain `max_guard` (poise_damage x0.8 + damage x0.6). Guard 0 = guard break (riposte window). `turn_delay` sets how slowly it turns.
- **Mimic** (`mimic.tscn`): give its spawner a unique `spawn_id` (saved "slain" flag). Real chests are `world/pickups/treasure_chest.gd` (`chest_id`, `item`, `count`, `embers`). Generators have `chest(...)` and `enemy(..., spawn_id=...)` helpers.

## Weapons, armour and the forge
- Weapon: author the AttackData files (see tools/gen_gear.py for a compact generator), a WeaponData in data/weapons/ (set `look` = a PresetData.WeaponLook; add a new look by adding an enum value and a drawing in `player_visual.gd`), list its id in `Weapons.IDS`, give it an icon in `icon_art.gd`. Animation keys the visual knows: slash, slash_rev, heavy, air, riposte, smash, sweep, thrust.
- Armour: an ArmorData in data/armors/ (`look`, damage_taken_mult, run_speed_mult, dodge_stamina_add, colours), id in `Armors.IDS`; its icon is automatic (`armor_<id>`).
- Make it obtainable: add a recipe to `Forge.RECIPES` ({kind, embers, mat[, relic]}). Starter gear (a preset's own) must share the preset's id and values - `test_gear_data` enforces it.
- New materials/drops: set `bonus_drop_item` / `bonus_drop_chance` / `bonus_drop_count` on an EnemyData.
- New station: an Npc with `station` = &"forge" or &"vials" (or add a kind to `ForgeMenu`).

## NPCs, dialogue and shops
- Place a `world/npcs/npc.gd` node (Area2D, origin = feet): `npc_id`, `display_name`, `look` (Pedlar / Figure; add a look by adding a `_draw_*` function), optional `shop_id`. Keep it ~80 px from any candle so the two interact zones do not overlap.
- Lines live in `systems/dialogues.gd` (`conversation(npc_id)` returns `{speaker, lines}`; `finish()` records the talk in the flag `talks_<npc_id>`). Lines may be Strings or `{"who", "text"}`.
- Shops: add an entry to `Shops.STOCK` (item id + price in embers) and a name in `Shops.NAMES`; give the Npc that `shop_id`. The shop opens after the conversation.

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

## A new boss
1. Make attack `.tres` files (set `parryable = false` for attacks the player must dodge; animation `&"leap"` makes the boss jump and land on the hit frame).
2. Make an `EnemyData` for it (health, poise, phase-1 `attacks`, `ember_reward`, `drop_item`).
3. Copy `actors/bosses/bell_warden.tscn`, set `boss_id` (unique; it becomes the saved defeat flag), `phase2_attacks`, `phase2_threshold`, and a visual script.
4. In the level, add a `BossArena` node at the bottom of the arena entrance; set `boss_scene`, `boss_offset`, `gate_height`, `trigger_width`, `victory_text`. Put solid geometry above the gate opening.
5. Put an Oath Candle just before the gate.

## Connecting levels
- Put a `LevelExit` (world/transitions/level_exit.gd) where the player leaves: `target_level`, `target_entry`; `mode` WALK for open edges, DOOR for doors (`required_item`, `door_id`, texts; `sealed` for not-yet-built content).
- Put a `LevelEntry` (level_entry.gd) with the matching `entry_id` in the target level, a little away from its own exits.
- One-way shortcuts: `ShortcutGate` with a unique `gate_id` and `lever_side`.
- `test_levels_wired_correctly` fails if an exit points at a missing level/entry or an id is reused; add new level paths to its list.
- The Forsaken Village is generated by `tools/levels/gen_forsaken_village.py` (blockout); edit the script or the scene, but not both.

## The map
- Add the level's path to `WorldMap.LEVELS` (systems/world_map.gd) and set the level root's `map_origin` so its entry sits next to the door it connects to on the neighbouring level (a test checks the Yard/Village pair; add one for new pairs).
- Nothing else: blocks, water, candles, exits and boss arenas are read from the scene automatically.

## Water, drowning, secrets
- `WaterZone` (world/hazards/water_zone.gd): origin = top-left of the surface, `size`. Slows the player.
- `DrownZone`: deadly deep water / pits.
- `BreakableWall` (world/blocks/breakable_wall.gd): unique `wall_id`, `hits_needed`.

## Ranged enemies
- Give an attack `projectile_speed > 0` (and `projectile_offset`): it fires a `Projectile` on its first active frame instead of a melee hit (damage / knockback / parryable carry over). Use `ranged_enemy.gd` as the scene script for the keep-distance brain.

## A new level
1. New scene, root `Node2D` with `world/levels/level.gd`. Set `level_id`, `display_name`, `bounds`, `default_spawn`.
2. Build terrain with `StoneBlock` nodes (set `size`; tick `one_way` for platforms).
3. Add hazards (`SpikePit`), `OathCandle` instances (unique `checkpoint_id`), `EnemySpawner`s.
4. Background: copy the `Background` ParallaxBackground from `test_arena.tscn` and change seeds/colours.
5. Point `Main.start_level` at it (room transitions arrive in M8). Levels must live in `res://world/levels/` — saves only accept paths there.
6. Anything that must persist (boss defeated, shortcut opened): `GameState.set_flag(&"name", true)` / `get_flag(&"name")`. Flags are saved automatically at the next autosave. See "Persistence" in `docs/ARCHITECTURE.md` before adding other kinds of saved data.

## Status effects, skills, quests, elites, day and night
- **Status on an attack**: set `status` (`bleed`/`poison`/`burn`/`frost`) and `status_amount` on its AttackData (100 = one hit triggers). **On a weapon**: same two fields on WeaponData (used when the attack has none). **Resistance**: `resist` on ArmorData, `status_resist` on EnemyData, e.g. `{"poison": 1.0}` immune, `{"frost": -0.3}` weak. Bosses (anything with `start_fight`) never take status.
- **Weapon skill**: an AttackData in `data/attacks/skill_<weapon>.tres`, referenced by WeaponData `skill`, with `skill_cost` (max focus is 60). `invulnerable_frames` gives i-frames for lunges. **Parry**: `parry_window_bonus`, `parry_recovery_bonus`, and `block_reduction` > 0 for a hold-to-guard weapon.
- **Elite**: copy an EnemyData, set `elite = true`, `damage_mult`, more health/poise/rewards. `tools/gen_combat_depth.py` shows the pattern (and generates the shipped ones).
- **Quest**: add a dictionary to `Quests.DEFS` (kinds collect / kill / have / flag) and its id to `Quests.ORDER`; the giver's dialogue offers, reminds and pays by itself. State is in world flags.
- **Manor-only lines**: `Dialogues.MANOR_GREETINGS[npc_id]`. **Lore commentary**: `Dialogues.ARCHIVE[item_id]` (Vesper).
- **Night-only enemy**: set the EnemySpawner's `when` to Night only (or Day only); add a `DayNightCycle` node to the level so spawners hear about dusk. `DayNight.CYCLE` sets the length.
- **Mini-boss**: `tools/gen_side_areas.py` (attacks, data, scene on BossBase with `brute_visual.gd`) and a BossArena in the level (`tools/levels/gen_side_levels.py`).

## Checklist after any content change
- Run `res://tests/run_tests.tscn` (must end with 0 failed; currently 31 tests).
- Do the relevant part of `docs/TESTING_CHECKLIST.md`.
- Log it in `DEVELOPMENT_LOG.md`; record placeholders in `KNOWN_ISSUES.md`.
