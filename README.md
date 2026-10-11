# THE HOLLOW OATH

A 2D dark-fantasy Soulslike action-platformer built in **Godot 4.3 (GDScript)**, targeting Windows 10/11 64-bit.

**Current state: Milestone 1 vertical slice (v0.1.0-m1).** One combat test arena — *The Penitent's Yard* — with a full player moveset, one enemy type, a checkpoint, a hazard and the death/respawn loop. All art is **temporary procedural placeholder art** (see `docs/ART_BIBLE.md`); there is no audio yet.

## Run it

### From the editor
1. Install **Godot 4.3 stable** (standard build, not .NET): https://godotengine.org/download/archive/4.3-stable/
2. Launch Godot → *Import* → select this folder's `project.godot`.
3. Press **F5** (Run Project). The main scene is `res://main/main.tscn`.

### The Windows build
`build/windows/TheHollowOath.exe` is a single self-contained executable (game data embedded). Double-click to play. It was exported but **has not been launched on Windows yet** — see `KNOWN_ISSUES.md`.

To re-export: *Project → Export → Windows Desktop → Export Project* (requires the 4.3 export templates: *Editor → Manage Export Templates → Download*). Or from a terminal:

```
godot --headless --path . --export-release "Windows Desktop" build/windows/TheHollowOath.exe
```

## Run the tests

```
godot --headless --path . --fixed-fps 60 res://tests/run_tests.tscn
```

18 automated gameplay tests drive the real scenes with simulated input (movement, jump, combo chain, heavy/stamina, dodge i-frames, enemy hits, parry + riposte, healing, checkpoint, death/respawn, AI engagement, enemy death/reset, spikes, hit-stop/FX cleanup). Exit code 0 = all pass. Windows shortcut: `tools\run_tests.bat` (edit the Godot path inside first).

Visual capture (renders scripted moments to PNG; needs a display, or `xvfb-run` on Linux):

```
godot --path . --fixed-fps 60 res://tests/capture_screens.tscn -- <output_folder>
```

## Project layout

```
autoload/        Global singletons: Events (signal bus), Settings, InputConfig, GameFeel, GameState
systems/combat/  HealthComponent, StaminaComponent, Hitbox, Hurtbox, AttackRunner, AttackData, WeaponData, HitData
systems/         Palette (master colours), LightTex (procedural light texture)
actors/player/   Player controller scene + placeholder visual
actors/enemies/  EnemyBase (reusable AI), EnemyData, Hollow Penitent, training dummy
data/            .tres data: attacks/, weapons/, enemies/   ← tune the game here
world/           Level base, CameraRig, StoneBlock, SpikePit, OathCandle, EnemySpawner, backgrounds, levels/
ui/              HUD (bars, vials, prompts, death screen, F3 debug), pause menu
fx/              Hit sparks, damage numbers
main/            Persistent game root (World, Camera, FX layer, HUD, Pause)
tests/           Automated test suite + screenshot capture
docs/            ARCHITECTURE, ART_BIBLE, ADDING_CONTENT, WORLD_BIBLE, TESTING_CHECKLIST
build/           Export output (not committed)
```

## Documents
- `CONTROLS.md` — controls reference
- `DEVELOPMENT_LOG.md` — what was built, when, and how it was verified
- `KNOWN_ISSUES.md` — open problems and placeholders
- `docs/TESTING_CHECKLIST.md` — repeatable manual test pass
- `docs/ADDING_CONTENT.md` — adding attacks, weapons, enemies, levels
- `docs/ARCHITECTURE.md`, `docs/ART_BIBLE.md`, `docs/WORLD_BIBLE.md`
