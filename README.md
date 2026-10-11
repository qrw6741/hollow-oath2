# THE HOLLOW OATH

A 2D dark-fantasy Soulslike action-platformer built in **Godot 4.3 (GDScript)**, targeting Windows 10/11 64-bit.

**Current state: Milestone 1 vertical slice + save system and main menu (v0.1.0-m1).** One combat test arena — *The Penitent's Yard* — with a full player moveset, one enemy type, a checkpoint, a hazard, the death/respawn loop, three save slots and a main menu. All art is **temporary procedural placeholder art** (see `docs/ART_BIBLE.md`); there is no audio yet.

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

47 automated tests drive the real scenes with simulated input: 18 gameplay tests (movement, combo, stamina, dodge i-frames, parry + riposte, healing, checkpoint, death/respawn, AI, spikes, hit-stop) 13 save/menu tests, 6 preset tests and 9 economy / controller tests (round trip, corruption, tampering, backup recovery, newer-version and malformed saves, write failure, autosave, the full menu → play → die → quit → continue flow, overwrite/delete confirmation, pause menu). Exit code 0 = all pass. Windows shortcut: `tools\run_tests.bat` (edit the Godot path inside first).

Cross-process save check (two separate game launches; the second must restore what the first saved):

```
godot --headless --path . --fixed-fps 60 res://tests/persistence_probe.tscn -- write
godot --headless --path . --fixed-fps 60 res://tests/persistence_probe.tscn -- read
```

Visual capture (renders scripted moments to PNG; needs a display, or `xvfb-run` on Linux; `capture_menus.tscn` does the same for the menu screens):

```
godot --path . --fixed-fps 60 res://tests/capture_screens.tscn -- <output_folder>
```

## Project layout

```
autoload/        Global singletons: Events (signal bus), Settings, InputConfig, GameFeel, GameState, SaveSystem
systems/combat/  HealthComponent, StaminaComponent, Hitbox, Hurtbox, AttackRunner, AttackData, WeaponData, HitData
systems/         Palette (master colours), LightTex (procedural light texture)
actors/player/   Player controller scene + placeholder visual
actors/enemies/  EnemyBase (reusable AI), EnemyData, Hollow Penitent, training dummy
data/            .tres data: attacks/, weapons/, enemies/   ← tune the game here
world/           Level base, CameraRig, StoneBlock, SpikePit, OathCandle, EnemySpawner, backgrounds, levels/
ui/              HUD, pause menu, main menu (ui/menu), settings panel (ui/settings), shared theme (ui/theme)
fx/              Hit sparks, damage numbers
main/            Persistent game root: session flow, World, Camera, FX layer, HUD, menus
tests/           Automated test suite + screenshot capture
docs/            ARCHITECTURE, ART_BIBLE, ADDING_CONTENT, WORLD_BIBLE, TESTING_CHECKLIST
build/           Export output (not committed)
```

## Starting presets
On New Game you choose one of four starting loadouts: **Sworn Knight** (balanced), **Twin-Blade Duelist** (fast, fragile), **Bulwark** (armoured, shield) or **The Unsworn** (no armour, fists only). The choice is saved with the slot. Add more in `data/presets/` (see `docs/ADDING_CONTENT.md`).

## Saves and settings
Progress is saved automatically each time you rest at an Oath Candle and each time you respawn after dying (you will see "Progress saved"). Three slots; each slot keeps a backup of the previous save.

| | Windows | Linux |
|---|---|---|
| Saves | `%APPDATA%\TheHollowOath\saves\slot_N.json` | `~/.local/share/TheHollowOath/saves/` |
| Settings / key bindings | `%APPDATA%\TheHollowOath\settings.cfg`, `input.cfg` | same folder |

To reset everything, delete that folder. A damaged save is set aside as `slot_N.json.corrupt` rather than deleted.

## Documents
- `CONTROLS.md` — controls reference
- `DEVELOPMENT_LOG.md` — what was built, when, and how it was verified
- `KNOWN_ISSUES.md` — open problems and placeholders
- `docs/TESTING_CHECKLIST.md` — repeatable manual test pass
- `docs/ADDING_CONTENT.md` — adding attacks, weapons, enemies, levels
- `docs/ARCHITECTURE.md`, `docs/ART_BIBLE.md`, `docs/WORLD_BIBLE.md`
