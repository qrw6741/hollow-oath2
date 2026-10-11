# Architecture

## Principles
1. **Data drives tuning.** Attacks, weapons and enemy types are `.tres` Resources in `data/`. Designers change numbers there, never in scripts.
2. **Components over inheritance for shared mechanics.** Health, stamina, hitboxes, hurtboxes and attack timelines are child nodes reused by the player, enemies and (later) bosses.
3. **Signals between independent systems.** Global events go through the `Events` autoload; local ones through component signals. The HUD never references the level, the level never references the HUD.
4. **Gameplay never reads visuals.** `*_visual.gd` nodes only read actor state. Swapping placeholder art for sprite sheets touches no gameplay code.
5. **Frame-exact combat.** Everything combat-related runs in `_physics_process` at a fixed 60 Hz and is counted in frames.

## Scene tree at runtime
```
root
├─ Events, Settings, InputConfig, GameFeel, GameState, SaveSystem   (autoloads)
└─ Main (main.gd)                    persistent across level changes
   ├─ World (Node2D)
   │  ├─ <Level> (level.gd)          swapped by Main.load_level()
   │  │  ├─ Background (ParallaxBackground)
   │  │  ├─ Geometry (StoneBlocks, SpikePits)
   │  │  ├─ OathCandle, TrainingDummy, EnemySpawners → spawned enemies
   │  │  └─ Player (spawned by Level)
   │  ├─ FX  (group "fx_layer": sparks, damage numbers)
   │  └─ Camera (camera_rig.gd)
   ├─ HUD (CanvasLayer 10)
   ├─ MainMenu (CanvasLayer 5; title / slots / settings)
   ├─ PauseMenu (CanvasLayer 20, process always)
   └─ fade layer (CanvasLayer 50, created by Main)
```

## Combat flow
```
Owner (_physics_process) → AttackRunner.tick()
   frame ≤ startup              → STARTUP   (anticipation, no hitbox)
   ≤ startup + active           → ACTIVE    (Hitbox overlaps → Hurtbox.receive_hit(HitData))
   ≤ total                      → RECOVERY  (chain / dodge-cancel open at configured frames)
Hurtbox → receiver.receive_hit(hit) → returns HIT / IGNORED / PARRIED
AttackRunner.hit_confirmed(target, result, hit) → owner reacts (hit-stop, or enter PARRIED stagger)
```
- Each swing hits each hurtbox at most once.
- Player i-frames: dodge window (frames 2–14), post-hit (40 frames), riposte (whole animation), respawn (60).
- Environmental hits (`HitData.environmental`) ignore dodge i-frames and can't be parried.

## Physics layers
| # | Name | Who is on it | Who scans it |
|---|---|---|---|
| 1 | world | StoneBlocks | all bodies, ledge rays |
| 2 | player_body | Player | OathCandle |
| 3 | enemy_body | Enemies | — (nothing collides with enemies; deliberate) |
| 4 | player_hurtbox | Player hurtbox | enemy hitboxes, hazards |
| 5 | enemy_hurtbox | Enemy/dummy hurtboxes | player hitbox, hazards |
| 6 | interactable | Checkpoints | — |

## State machines
- **Player** (`player.gd`): FREE, ATTACK, DODGE, PARRY, HEAL, HURT, REST, DEAD. Inputs are buffered 8 frames; attack inputs during an attack are queued until the chain window.
- **EnemyBase** (`enemy_base.gd`): PATROL ⇄ IDLE → CHASE → ATTACK → RECOVER → CHASE; STAGGER, PARRIED, RETURN, DEAD. Subclass hooks: `choose_attack`, `on_target_acquired`, `on_attack_started`, `on_staggered`, `on_parried`, `on_died`.
- **Bosses (M6)** will get a `BossBase` extending EnemyBase with explicit phase states, scripted intros and a persistent "defeated" flag in GameState.

## Persistence
`SaveSystem` (autoload) owns files; `GameState` owns what goes into them (`to_dict()` / `apply_dict()`).
- Three slots: `<user dir>/saves/slot_N.json` = `{ "checksum": sha256, "data": { "version": 1, ... } }`.
- **Write**: temp file → read back and verify → copy the current good file to `.bak` → swap in. A failed write never damages the existing save and reports via `Events.save_failed`.
- **Read**: main file → if damaged/missing, `.bak` (the damaged file is kept as `.corrupt`) → else status CORRUPT. A save from a newer game version is TOO_NEW and is never modified.
- **Versioning**: `CURRENT_VERSION` + `_migrate(data, from_version)` upgrades one version at a time; `_normalize()` forces every field to a valid type with defaults, so malformed or hand-edited values cannot crash the game. To add data: add it to `GameState.to_dict/apply_dict` and `_normalize`; bump the version and add a `_migrate` arm only if old saves need transforming.
- **Autosave** on `checkpoint_rested` and `player_respawned`, only when a slot is active (`GameState.current_slot > 0`). Dev/test sessions have slot 0 and never write.
- Only durable state is saved — never mid-combat state.
- `Main` validates the saved level path (must exist inside `res://world/levels/`) and falls back to the start level.
- Session flow lives in `Main` (`start_new_game`, `continue_slot`, `return_to_menu`) behind `Events.new_game_requested / load_game_requested / quit_to_menu_requested`; `GameState.session_id` invalidates timers from an ended session (e.g. a pending respawn).

## Rules learned the hard way
- **Do not `preload()` scenes in scripts that have a `class_name`.** Class compilation can trigger a load cycle that leaves resources half-initialised. Reference scenes through `@export var x: PackedScene` (set in the .tscn) or `load()` at runtime. Preloading plain scripts is fine.
- Tests must run as a scene (`res://tests/run_tests.tscn`), not with `-s`, so autoloads exist when scripts compile.
