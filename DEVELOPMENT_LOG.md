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

## 2026-10-12 — Icons instead of text

- `IconArt` (ui/icons/icon_art.gd): 17 vector icons on a 16x16 grid: every item (bandage, ember shard, tonic, rusted key, bell shard, penitent's tear, Candlewright's note, Canon's seal), every weapon (Oathblade, twin blades, sword and shield, bare hands), every armour (mail with sash, leathers, plate, bone-cloth wraps) and a Status sigil. No image files: crisp at any resolution, no download cost.
- `IconSlot`: a square, focusable slot (gold frame on focus, stack count, gold mark for the quick item, optional caption).
- Equipment tab: Weapon / Armour / Item / Status are now four icon slots; the detail panel shows the big icon beside the name. Items tab: a 5 x 4 grid of slots (filled + empty) instead of a text list, big icon in the details. HUD quick item: icon + count instead of the name.
- Tests: still 70; the equipment test now checks slot icons, that selecting a slot names it, and that every item/weapon/armour id has an icon. Rendered icon sheet (`tests/capture_icons.tscn`) reviewed; the bell shard was redrawn after it read as a boot.

## 2026-10-12 — Equipment & status screen

- The pack became a two-tab character screen (`ui/inventory/inventory_menu.gd`). **Equipment**: your character drawn large on a pedestal (current preset look), name, level and embers; slots for Weapon, Armour, Quick item and Status. Weapon details: damage of every light-combo hit, heavy, aerial, riposte (Strength bonus included), stamina per swing, poise damage, speed and reach. Armour: damage taken, base health/stamina, vials and heal, run speed, dodge cost, parry window. Status: health, stamina, Vigor/Endurance/Strength and what they add, embers and next level cost, deaths and time. **Items**: the old pack. L1/R1 (Parry/Heal) or clicking switches tabs.
- Presets gained `armor_name` / `armor_description` (Oathsworn Mail, Candlewright Leathers, Bulwark Plate, Bone-cloth Wraps). `WeaponStats` turns attack data into the displayed numbers.
- Tests: 70 (new `test_equipment_screen`: armour text for all presets, Oathblade 12/13/20, Strength scaling, four-hit fists, slots/preview follow the preset, armour and status rows, tab switching, close).
- Not done: you still own exactly the weapon and armour of your preset; there is no equipment swapping yet.

## 2026-10-11 — The end of the prologue: the light, and Vaelmoor awake

- After the Drowned Canon falls, a pillar of light rises in the Drowned Choir (`ShiningLight`, spawned by `BossArena` after `light_delay`; it stays on later visits). Walking into it lifts the player into the light, the music cuts to the victory sting, and the screen fades through warm white (`Main.teleport`) into a new area.
- **Vaelmoor, Awake** (`tools/levels/gen_vaelmoor_awake.py`): the first daylight in the game (day sky with sun and clouds, grass ground style, drifting petals, brighter music: the menu theme at 1.15x pitch). Peaceful: the First Light Candle, the Waking Stone (readable; explains that the prologue was the Hollow, the oath's dream) and the sealed road to the kingdom (next build). On first arrival: banner "PROLOGUE COMPLETE", flag `prologue_complete`, autosave.
- New pieces: `LoreTablet` + HUD reading panel (`Events.message_requested`), `PrologueEnd`, `Sky.daylight`, `StoneBlock.Style.GRASS`, `Level.music_pitch`, coloured / timed fades in `Main.change_level`.
- On the map the true Vaelmoor sits apart from the Hollow areas (a different world).
- Tests: 69 (new `test_prologue_ending`: no light before the boss falls, light after, walking in teleports to the arrival point, prologue flag set, fade cleared, light persists, stone readable and closes when you walk away).
- Size: single-file zip still under the 30 MB limit (~54 KB to spare); no new audio files were needed.

## 2026-10-11 — The Drowned Catacombs, the Drowned Canon, and the map

- **Area 3, the Drowned Catacombs** (`tools/levels/gen_drowned_catacombs.py`): through the village chapel door (now open). Two screens tall: Ossuary Stair (Ossuary Candle) -> eight-step descent -> the Flooded Nave (waist-deep water, a drowned shaft with a broken-pillar stepping stone, Acolytes on pillar ledges, a Bell-Bearer, Penitents) -> Canon's Ledge (Canon's Rest Candle; a cracked wall hides an alcove with two Ember Shards) -> the Drowned Choir, the boss arena (shallow water). Behind the boss, the flooded stair to the Ashen Cathedral is sealed (end of this build). Own ambience (`catacombs`: drips, low drone, distant bells).
- **New world pieces**: `WaterZone` (wading: 60% run speed, lower jump, shorter roll, splash), `DrownZone` (instant death, ignores i-frames), `BreakableWall` (three hits, remembered).
- **Boss 2, the Drowned Canon** (`DrownedCanon` extends `BossBase`, 820 HP): Rosary Lash (long reach, parryable; phase 2 chains a returning lash), Bile Hymn (three parryable shots in a fan), Undertow (sinks, invulnerable, surfaces under you after a bubbling ring; unparryable), phase 2 Flood Psalm (a wave rolls along the floor; jump it). Boss music reuses the boss theme slowed to 0.82 (`BossBase.music_track/music_pitch`). Rewards: 2600 embers + Canon's Wax Seal (key item for the next region).
- **Map** (`ui/map/map_menu.gd`, `systems/world_map.gd`): M / PS touchpad / L3, or Map in the pause menu. Every level is read from its scene and placed at its `Level.map_origin` so connected doors line up. Only explored 64 px cells are drawn (revealed in a radius as you walk; saved per level). Marks: you, Oath Candles (gold once rested at, with names), bosses (crossed out when defeated), doors and passages; area name and % explored. Pan, zoom (Parry / Heal or mouse wheel), drag.
- **Projectiles** gained rectangle shapes, configurable drop and "pass through walls" (the floor wave).
- Tests: 68 (5 new): chapel door -> catacombs and back, wading is slower, the drowned shaft kills, the cracked wall breaks and stays broken, the Canon (start, submerge invulnerability and surfacing under the player, three-shot fan, phase 2 wave toward the player that a full jump clears, defeat rewards), map (cells revealed, saved and sanitised, data for all levels, Yard/Village doors line up, open/close/pause, candles light up). Level-wiring test now covers every level in WorldMap.LEVELS.
- Found by tests: the floor wave was too tall to jump while wading (lowered to 18 px); the boss's roar reset its attack cooldown during a scripted test.
- **Size**: the single-file Windows zip is now ~65 KB under the 30 MB upload limit. The next sizeable addition will need audio trimmed or the build split again.
- **Not verified**: nobody has played the catacombs or the Canon; the shaft jump and the wave timing need a real hands-on check.

## 2026-10-11 — Fix: split download did not launch; back to one file

- Reported on Windows: "Couldn't load project data ... Is the .pck file missing?" The two-zip build extracted into two folders, separating the exe from its .pck. **First real launch report on Windows**: the error means the exe itself started.
- Fix: audio converted from WAV/QOA to Ogg Vorbis (sfx 24 kHz q0, music 22 kHz q0) and the ambient loops shortened (menu 32 s, yard 36 s, village 40 s); audio went from ~3.1 MB to ~0.8 MB. The build is again one self-contained .exe in one zip under the 30 MB upload limit. 63/63 tests pass.

## 2026-10-11 — The Forsaken Village (second area) and level travel

- **Travel system**: `LevelExit` (walk / door, key items, sealed doors), `LevelEntry`, `Main.change_level` with fade and autosave, entry-or-candle spawn rule, death respawn at a candle in another level, `checkpoint_level` / `level_entry` saved (old saves normalise to empty = previous behaviour).
- **Bell Door** at the back of the Bell-Warden arena; the Warden's Bell Shard unlocks it (remembered).
- **The Forsaken Village** (`world/levels/forsaken_village.tscn`, generated by `tools/levels/gen_forsaken_village.py`): outskirts with the Village Gate Candle, rooftops over a low corridor, the village square, the chapel road with the Chapel Steps Candle, a spike pit, and the barred chapel door (end of this build). Ten enemies, five pickups, its own music (`village`).
- **Shortcut**: an iron gate between the outskirts and the corridor, raised by a lever from the corridor side only; remembered.
- **New enemies**: *Ember Acolyte* (Candlewright novice; keeps its distance and throws burning wax, a parryable projectile you can also dodge through; weak censer swipe up close) and *Bell-Bearer* (heavy; high poise; parryable bell slam with a glint, unparryable chain swing with a red glow; rings its bell before attacking).
- **Systems**: `AttackData.projectile_speed` (ranged attacks), `Projectile`, `RangedEnemy` brain. New item: Candlewright's Note (lore). New sounds: throw, fizzle, small bell, door open/locked, gate.
- Tests: 63 (7 new): every exit lands on a real entry and ids are unique; Bell Door locked/unlocked + travel both ways; respawn at a candle in another level (and in the same level); Continue in the village; shortcut gate blocks / opens from one side / persists; projectile hurts, is parried, and passes through dodge i-frames; Bell-Bearer poise and unparryable swing.
- **Not verified**: the village has only been "walked" by teleport captures, never played through by a person; jumps and enemy placement may be too hard or too easy. Windows build not launched.

## 2026-10-11 — Placeholder audio

- 35 sound effects and 3 looping music tracks, all synthesised by `tools/audio/gen_audio.py` (deterministic). `Audio` autoload with Music/SFX buses, pooled players, positional sounds, music crossfades. Volume / Music / Effects sliders in Settings. Details in `docs/AUDIO.md`.
- Hooked: player combat and movement, enemy wind-ups and deaths, the Bell-Warden (bell toll telegraph, stomps, leap landing, roar, death), economy and world events, menu ticks, music per context.
- Tests: 56 (new `test_audio_files_and_music_flow`: every sound name used in code exists, music loops, music follows menu / level / boss / victory, volume reaches the bus).
- **Not verified by ear.** No audio output here; levels were set from measured peak/RMS. Needs a listen and a rebalance.

## 2026-10-11 — Intro boss: the Bell-Warden; ember counter reverted

- **HUD**: removed the LV plaque; the ember counter is back to the plain icon + number (user request).
- **Boss framework** (`actors/bosses/boss_base.gd`, `BossBase` extends `EnemyBase`): dormant until its arena starts the fight, no leash, two phases (below 50%: roar that shoves the player back, new attack pool, +30% speed, shorter cooldowns), leap attacks that land on the hit frame, defeat flag in `GameState.flags` (`boss_defeated_<id>`).
- **Boss arena** (`world/boss/boss_arena.gd`): fog gate at the entrance; the fight starts when the player is inside the arena zone (polled, armed 30 frames after a spawn), the gate seals, HUD boss bar appears. Player death ends the fight; on respawn/rest the boss is recreated at full health and the gate reopens. Victory opens the gate for good, banner "THE BELL FALLS SILENT", immediate autosave.
- **The Bell-Warden**: 650 HP, poise 95. Phase 1: Clapper Smash (parryable, glint), Sweeping Toll -> Backhand, Shoulder Charge (unparryable, red aura). Phase 2 adds the three-hit Toll combo and the Falling Bell leap (unparryable; red ring marks the landing). Reward 1500 embers + Warden's Bell Shard (key item).
- **Level**: the Penitent's Yard now continues through a gate into a 640 px boss arena (right wall moved to x 2560); new Bell-Gate Candle just before the gate; third Penitent moved off the ledge.
- Tests: 55 (8 new): data, dormant until the gate, sealing, the boss lands a hit, parry -> riposte on the boss, phase 2 + leap landing on the player, reset on player death, defeat persists through rest and a save reload. Rendered captures of gate, intro, smash glint, charge aura, roar, leap marker, victory.
- Bugs caught by tests: teleporting past a thin trigger skipped the fight (now a polled zone); on respawn the physics server still reported the dead player inside the arena and restarted the fight (now armed after 30 frames); a boss struck from outside the zone started fighting without sealing the gate (all fight starts now go through one event).
- **Not verified**: difficulty/fairness with a human player (numbers are first pass), feel of the leap and charge with a real pad, Windows.

## 2026-10-11 — UI upgrade pass

- **Fonts**: Lora (variable, heavier weight) for text and GFS Baskerville for titles and menu choices, both SIL OFL, bundled in `assets/fonts/` (credits in `docs/CREDITS.md`). Everything previously used Godot's default font.
- **Framing**: dark panels with stone border and gold corner brackets (`UITheme.frame` / `draw_panel`), gold rule with diamond under headings, `FancyButton` (gold diamonds beside the focused/hovered choice), fade-in when switching menu screens.
- **HUD**: bars with framed gold-diamond end caps; plaque top right with level (`LV n`) and ember count; framed quick-item slot with its button glyph; area banners and death text in the title face with rules; pause menu now shows level / embers / deaths / play time.
- Verified by rendered captures of title, slots, preset, settings, pause, candle, pack and HUD; suite 47/47 unchanged. Fonts were chosen from what is installed on the build machine (no network for downloads): they can be swapped by replacing the two files and the two functions in `ui/theme/ui_theme.gd`.
- Not done: custom pixel icons for items (items still have no icon art), animated bar effects, proper widescreen/ultrawide layout testing (UI is laid out for 16:9), localisation.

## 2026-10-11 — Embers (currency), levelling and inventory

- **Embers**: awarded by kills (`EnemyData.ember_reward`, Penitent = 45). Shown top right. Dying drops all carried embers as a glowing stain where you last stood safely (never inside a hazard); touching it recovers them; dying again before that destroys the older stain. The stain is saved.
- **Level up** at the Oath Candle: resting opens a menu (after a short delay) to buy Vigor (+8 health), Endurance (+6 stamina) or Strength (+4% damage). Level = 1 + points; each point costs more (60, 96, 144, 204...). Works on top of any preset.
- **Inventory**: `ItemData` resources (`data/items/`, registry `Items`): Ash Bandage (heal 30), Pale Tonic (+40 stamina), Ember Shard (+120 embers), Rusted Key (key item, no use yet), Penitent's Tear (lore, 30% drop from Penitents). Stack caps; pack screen (Tab / Create) with Use and quick-item slot (F / R3); also reachable from the pause and candle menus. World pickups (`ItemPickup`, press interact) are remembered as saved flags; 3 placed in the arena.
- **Saves**: embers, stain, stats, inventory, quick item added (no version bump; `_normalize` clamps/cleans bad values and fills defaults for older saves).
- Tests: 47 total (8 new economy/inventory tests, including death → stain → recovery, replacing a stain, level-up maths, damage boost on the dummy, use rules, pickup persistence, save round-trip + hostile data, candle/pack menu flow). Rendered captures of HUD, pickup, stain, candle menu, pack.
- Bugs caught by tests: a fresh stain overlapped the still-dying player's body and was collected instantly (now arms after 30 frames and polls overlap); input events vs polled input in tests.
- Not verified: balance (costs, rewards, damage bonus), the feel of the stain pickup and menus with a real pad, anything on Windows.

## 2026-10-11 — Fix: controller could not operate menus

- Bug (reported by user on a real pad): pressing Cross on Continue/Settings did nothing, also in the pause menu. Root cause: Godot's built-in `ui_accept`/`ui_cancel` carried **no joypad buttons** in this project (confirmed by dumping InputMap), so only D-pad navigation worked. My earlier "controller compatible" claim was wrong for menus; the in-game actions were fine.
- Fix: `InputConfig` adds Cross/A to `ui_accept` and Circle/B to `ui_cancel`; pause menu also treats Circle as back/resume.
- New test `test_menu_works_with_controller` simulates pad events: Cross on Continue starts the game; Options pauses; D-pad + Cross opens Settings; Circle closes it; Cross on Resume resumes. Suite 39/39. Still not run on a physical DualSense.

## 2026-10-11 — Controller prompts (PS5 icons)

- New `InputPrompts` autoload tracks the last-used device (keyboard / PlayStation / Xbox-style; Sony pads are detected by name, with a manual override in Settings) and says which button each action uses. `Glyph` draws the prompt (Cross/Circle/Square/Triangle, L1/R1, Options, D-pad, or a keycap) with vector primitives, so no image files and crisp at any resolution. `HintBar` shows rows of "[icon] label" and redraws when the device changes.
- Used in the HUD interact prompt, the in-arena controls hint, and the main-menu footer. Rumble on hits/parries (toggle in Settings). Settings: Controller icons, Controller vibration.
- Button layout was already pad-complete via SDL's mapping (A=Cross etc.); no bindings changed.
- Verified: suite 38/38 (new `test_input_prompts`), rendered keyboard / PlayStation / Xbox hint bars and the settings screen.
- **Not verified on a real DualSense** (none available here): device-name detection, rumble feel, and whether Steam Input / wireless affect the reported name. The Auto icon choice falls back to Xbox letters if the name isn't recognised; set Controller icons to PlayStation to force it.

## 2026-10-11 — Video options (resolution / fps)

- The game was rendered into a fixed 480x270 buffer and integer-scaled (chunky "480p" look). It now defaults to **High-res (smooth)**: the same 480x270 world rendered natively at the window size (canvas_items stretch, fractional scaling), so text and shapes are sharp at 1080p and above.
- Settings (main menu and pause): Display (Windowed/Fullscreen), Window size (720p, 900p, 1080p, 1440p, 4K; default 1920x1080, shrunk to fit the desktop), Graphics (High-res / Pixel 480x270), Frame rate limit (30/60/120/144/240/Unlimited), VSync. Saved in `settings.cfg` under `[video]`. Default: windowed 1080p, VSync on, unlimited cap.
- Gameplay still simulates at a fixed 60 Hz; physics interpolation is enabled so motion renders smoothly above 60 fps.
- Verified: suite 37/37, rendered 1920x1080 captures of arena and settings screen. **Not verified:** high-refresh behaviour, fullscreen switching and interpolation artefacts on a real monitor (headless/xvfb only); Windows build not launched.

## 2026-10-11 — Visual and main-menu polish pass

- Sky: seeded stars and a smooth ember glow on the horizon. Parallax ruins: aerial haze that fades each layer toward fog near its feet (depth). New `Vignette` layer (dark corners, below the HUD).
- Main menu: low mist, stone ledge, a lit candle in the foreground, gold ornament under the subtitle, crimson title shadow, wider gold focus frame.
- Verified by re-rendering menu and arena captures and re-running the suite (37/37). Judged by eye only; this is still temporary procedural art (real sprites are Milestone 4).

## 2026-10-11 — Starting presets ("Choose your oath")

### Built
- Four selectable starting presets, picked after the slot on New Game: **Sworn Knight** (balanced sword, the old defaults), **Twin-Blade Duelist** (fast, fragile, 4-hit chain), **Bulwark** (plate, sword & shield, shield bash, long parry window, 4 flasks), **The Unsworn** (no armour, fists only: 4-hit jab/cross/hook/uppercut chain, haymaker, "Hollow Palm" riposte; low HP, takes +30% damage, big stamina, fast).
- Data-driven: `PresetData` resources in `data/presets/`, registry `systems/presets.gd`, new weapons (`twin_blades`, `sword_and_shield`, `fists`) and their attack `.tres` files. `Player._apply_preset()` applies stats; damage multiplier applied in `receive_hit`.
- Preset stored in the save (`preset_id`, no version bump: `_normalize` defaults missing/unknown ids to `sworn_knight`). `Events.new_game_requested` now carries the preset id.
- Placeholder art for every look/weapon/attack animation in `player_visual.gd`; the Unsworn is a bare-torso, non-explicit figure with bone-cloth wraps. Selection screen shows an animated-preview figure, stats, perks and drawbacks.

### Verified
- Automated: suite is now 37 tests (6 new: preset validation, stats applied per preset, Unsworn bare/fists, each preset's light combo lands on the dummy, preset save round-trip + unknown/legacy fallback, preset screen flow). All pass headless on Linux.
- Rendered captures (xvfb) of the selection screen and all four presets idle / light / heavy / parry reviewed by eye (`tests/capture_presets.tscn`).
- A bug caught by this work: first draft of the preset `.tres` files had an invalid `PackedStringArray` literal, so they failed to load and the game silently fell back to defaults. The new tests now fail loudly if any preset does not load.

### Not verified
- Balance: numbers are first-pass, **not playtested by a human**. The Unsworn's real feel (reach, damage taken) needs hands-on testing.
- Windows build re-exported but still not launched on Windows.

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
