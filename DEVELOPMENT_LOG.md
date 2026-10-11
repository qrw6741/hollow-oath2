# Development Log

Status keys: **Tested** = verified by an automated test or a rendered capture · **Implemented** = in the game, exercised only by smoke runs · **Planned** = not built.

---

## 2026-10-11 (later) — Save system and main menu

### Built
- **SaveSystem** autoload: 3 slots, versioned JSON with SHA-256 integrity checksum, verified temp-file write, automatic `.bak` of the previous good save, damaged files kept as `.corrupt`, recovery from backup, newer-version saves refused and left untouched, per-version `_migrate()` hook, field normalisation (malformed values become defaults).
- **GameState** extended: active slot, play time, level path/name, world flags (`set_flag/get_flag`), `to_dict/apply_dict`, session ids so a pending respawn from an ended session can never fire.
- **Autosave** on resting at a candle and on respawning; "Progress saved" HUD indicator; failed writes surface a message instead of failing silently.
- **Main menu**: title screen (Continue / New Game / Load Game / Settings / Quit), slot picker showing place, play time, deaths and date, two-step confirmation for overwrite and delete, damaged / too-new slot handling, fully keyboard / gamepad / mouse navigable, animated backdrop.
- **Shared UI theme** and **Settings panel** (screen shake, flashes, hit-stop, volume) used by both main menu and pause menu.
- **Pause menu** reworked: Resume, Settings, Quit to Main Menu (confirmed), Quit to Desktop; unavailable while in the main menu.
- **Main** now owns the session flow with fade transitions; dev/test runs can skip the menu (`show_menu_on_start = false`).
- Save folder is `%APPDATA%\TheHollowOath` (custom user dir) rather than Godot's default name-dependent folder.

### Verified
- **Automated suite: 31/31 pass** (18 existing + 13 new covering saving and menus).
- **Mutation check**: removing the session guard in `GameState` made the new "death then quit is clean" test fail, restoring it made it pass — the test genuinely detects that bug.
- **Cross-process check**: one game launch created a new game, rested and exited; a second launch picked the most recent slot, continued, and restored deaths, flags, checkpoint and player position.
- **Rendered captures** of title, slots, overwrite confirmation, load, settings and pause screens inspected visually.
- **Windows export** rebuilt. The .exe has still **not** been launched on Windows.

### Fixed during this step
- Title-screen emblem and button frames were left-aligned / stretched to the title width (size flags); also applied to pause and settings buttons.
- Area banner showed through the pause overlay; overlay made more opaque.
- Two weak assertions in my own tests (always-true checks) tightened.

## 2026-10-11 — Milestone 1 vertical slice (v0.1.0-m1)

### Built
**Foundation**
- Godot 4.3 project, GL Compatibility renderer (widest Windows GPU support), 480×270 pixel viewport integer-scaled to the window.
- Autoloads: `Events` signal bus, `Settings` (accessibility/audio, persisted), `InputConfig` (default bindings + runtime rebind + persistence), `GameFeel` (hit-stop, sparks, damage numbers), `GameState` (checkpoint + death→respawn flow).
- Physics layers named: world, player_body, enemy_body, player_hurtbox, enemy_hurtbox, interactable.

**Combat system (shared by player and enemies)**
- `AttackData` resource: startup / active / recovery frames, chain and dodge-cancel frames, damage, poise, stamina, knockback, hitbox, lunge, gravity scale, hit-stop, shake, AI range/weight/chain chance.
- `AttackRunner` plays an attack timeline frame-by-frame; `Hitbox`/`Hurtbox` areas; `HitData` with HIT / IGNORED / PARRIED results.
- `HealthComponent`, `StaminaComponent` (overdraw-to-zero + exhaustion delay).
- `WeaponData`: the Oathblade — 3-hit light combo, heavy, aerial, riposte. All attacks are `.tres` data.

**Player** — run, variable-height jump, coyote time, input buffer; light combo with Souls-style input queueing; heavy; aerial attack (ends on landing); dodge roll with i-frames and attack-cancel tail; parry window → riposte; Ember Vial healing (3 charges, slowed movement, applies mid-animation); hurt + post-hit invulnerability; death; rest at checkpoint.

**Enemy: Hollow Penitent** — patrol / idle look-around, detection (front full range, back half), chase with spacing, ledge avoidance, weighted attack choice by distance (overhead chop, lunging thrust, 40% chance overhead → low sweep follow-up), tracking only in the first 60% of wind-up, recover backstep, poise + stagger, parried state with riposte window, death fade, leash/return home.

**World** — `Level` base, `CameraRig` (look-ahead, smoothing, bounds, noise shake), `StoneBlock` level primitive (masonry / rubble / one-way planks, auto collision), `SpikePit` hazard (hurts player and enemies, re-hit cooldown), `OathCandle` checkpoint with real flickering light, `EnemySpawner` (revives enemies on rest/respawn), parallax gothic skyline + moon, drifting ash, `CanvasModulate` darkness.

**Test arena "The Penitent's Yard"** — candle, training dummy, spike pit, four one-way platforms, raised ledge, three Penitents (patroller, patroller, sentry on a ledge).

**UI** — health bar with damage trail, stamina bar, vial icons, interaction prompt showing the bound key, area/checkpoint banners, death screen ("THE OATH BREAKS") with fade, F3 debug overlay, pause menu with screen-shake / flash / hit-stop toggles.

### Verified
- **Automated suite: 18/18 pass** (`tests/run_tests.tscn`, headless, fixed 60 fps, simulated input) — see README for the list.
- Main scene runs 20 simulated seconds with no errors.
- **Rendered captures** under Xvfb/Mesa (`tests/capture_screens.tscn`): spawn, rest, light attack, enemy telegraph glint, parried enemy + riposte cue, riposte critical (70), platforms, death screen, respawn — all visually correct.
- **Windows export** produced `TheHollowOath.exe` (PE32+ x86-64, PCK embedded). The identical exported data pack was run outside the editor with the Linux engine for 15 s with rendering: no script errors. **The .exe itself has not been launched on Windows.**

### Fixed during the milestone
- Script-level `preload()` of scenes created a class-compilation load cycle that left the weapon resource half-loaded (player could not attack in tests). Replaced with exported/lazy scene references. Rule added to ARCHITECTURE.md.
- Spike pit damaged enemies every frame → per-target re-hit cooldown.
- Hit-stop relied on wall-clock time → now uses an unscaled timer with a supersede token.

### Next (Milestone 2 polish → 3)
Milestone 1 already covers most of Milestone 2/3's combat and loop. Remaining before Milestone 4: playtest feel on real hardware (your notes), tune timings, add placeholder SFX, aerial-attack bounce decision, first Windows launch report.
