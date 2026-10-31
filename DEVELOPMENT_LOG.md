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

## 2026-10-12 — Hollowmere Manor and the Hollowmere Sigil

- **The sigil**: Ommen gives you the Hollowmere Sigil on his fourth talk (page four of his story; players who already heard everything are offered it on their next visit). Use it from the pack ("Travel to Hollowmere"): the oath folds the road and you arrive in the manor's front hall. Used in the manor ("Return") - or through the manor's own door - it puts you back at the exact spot you left (saved with the game). Reusable, never consumed, never the quick item, and refused during a live boss fight.
- **Hollowmere Manor** (new peaceful hub, `tools/levels/gen_hollowmere_manor.py`, 2500 px): a haunted great hall - moonlit windows, portraits whose painted eyes glint, chandeliers (real light), a grandfather clock, armour with faint eyes, bookshelves, cobwebs, drifting ghosts and dust motes (`ManorHall`, procedural placeholder art). Residents: Ommen (the candle's keeper), Hobb's forge, Sister Ilse's vials, Wenna's trade hall, and the new **Steward Aldous Vane** (a ghost butler: introduces the house, reacts to the Marshal's fall). A mezzanine with a chest (4 Forge Scrap + 350 embers) and the Visitors' Ledger, the Hollowmere Candle (checkpoint + fast travel), and the sealed Gallery at the far end. On the world map.
- **Bug fixed**: Hobb and Ilse in Vaelmoor, Awake were sunk 40 px into the hill (reported by the user). Now a test checks every NPC in Awake, the Road and the Manor stands on a block's top surface.

### Verified
- Automated suite, with new tests: sigil gift (pages, late offer, once only, never quick item), Aldous's lines, travel there and back to the exact spot, the boss-fight refusal, the manor door, manor wiring/spacing/climbable balcony/candle/saves, NPC grounding.
- Rendered captures (tests/capture_manor.tscn) - reviewed; the hall was brightened after the first look (NPCs were hard to read).
- Not verified: how the manor feels to play (nobody has), the Windows build launching, balance of the balcony chest.

## 2026-10-12 — Gear: new weapons, armour you can take off, upgrade stations

- **Equipment is now a saved layer** (`Loadout`, `GameState.weapons/armors/weapon_id/armor_id/flask_level`): you own weapons and armours, each with an upgrade level (+0..+5), and you equip one of each. The preset still decides vitals, handling and the starting gear; armour now decides damage taken, run speed and dodge cost. The four starting armours mirror their presets exactly (a test checks it), so nothing about existing characters changed.
- **Take armour off and put it on** (Equipment tab -> select the Armour slot -> "Take off all armour" or pick a piece). Naked: take 135% damage, run 12% faster, drawn without armour. Same picker swaps weapons. Works anywhere you can open the pack.
- **5 new weapons** (data in data/weapons + data/attacks, made by tools/gen_gear.py; each drawn on the character with its own thrust/swing poses): Wayfarer's Rapier (fast thrusts, long lunge, big riposte), Kingsfall Greatsword (slow, huge, heavy poise damage), Toll Hammer (poise breaker), Marshal's Lance (longest reach, thrusts), Tide-Sabre (4-hit wave combo).
- **4 new armours**: Pilgrim's Coat, Penitent's Shroud (light), Drowned Canon's Mail (medium), Marshal's Plate (heavy, +4 dodge cost). Armour upgrades take 3% off the damage taken per level (-15% at +5).
- **Blacksmith Hobb** (Vaelmoor, Awake and the Road's Pilgrim's Rest): upgrades weapons and armour (embers + Forge Scrap) and forges new gear. The great pieces need a relic you carry - Bell Warden's shard (hammer), Marshal's Crest (lance, plate), Canon's Seal (sabre, mail), Penitent's Tear (shroud) - shown to Hobb, never consumed. Greatsword, rapier, coat need only embers + scrap.
- **Sister Ilse, the Vial-Keeper** (same two places): upgrades the Ember Vials (embers + Hollow Resin): +6 healing per level, one extra vial at +2 and another at +5.
- **Materials**: Forge Scrap and Hollow Resin. Every enemy now has a second drop roll for them (scrap from armed/armoured foes, resin from the flying and the ember-touched; mimics and all bosses guarantee scrap). Wenna sells both as a fallback (110 / 170 embers).
- **UI**: `ForgeMenu` (both stations, tabs WEAPONS / ARMOUR, shows the exact gain before you pay), Equipment tab pickers; the character preview and the in-game character draw whatever you wear and wield.
- Save format: additive fields (version stays 1; old saves load with their preset's loadout). Hostile values in a save are clamped/dropped and a broken loadout repairs itself.

### Verified
- Automated suite, including 8 new tests (gear data and icons, equip/take-off numbers on the live player, forge rules and costs, save round-trip + legacy + hostile saves, both menus driven by presses, equip pickers, every new weapon landing hits and finishing its swing, the smiths' placement and talk -> station flow).
- Rendered captures (tests/capture_gear.tscn): the smiths on the road, both station menus, equipment screen with pickers, every new weapon mid-swing - reviewed.
- Not verified: balance (damage, costs and drop rates are my guesses; nobody has played the new weapons), feel of thrust weapons, whether the material economy is generous enough, Windows launch.

## 2026-10-12 — After the prologue: the Vaelmoor Road, NPCs, shop, Sir Orren

- **The Vaelmoor Road** (new level, daylight, ~3600 px): Pilgrim's Rest (arrival, Wenna's stall, Wayside Candle), the Crow Fields (rise, chest, pikemen, crows), the Ford (wading, an Oathguard in the water, broken bridge planks), the Marshal's Camp (Camp Candle, a Mimic on the bank, pikemen, an Oathguard at the gate) and the Crossroads (boss). Reached from the east edge of Vaelmoor, Awake (the sealed gate is gone); the road's west edge leads back. On the world map; both candles are fast-travel destinations. The road to the Citadel is sealed ("next build").
- **Dialogue system**: `DialogueBox` (typewriter, speaker plate, Interact / Confirm / Light attack to continue, Cancel skips; pauses the game) and `Dialogues` (all lines, chosen by NPC, how many times you have talked — saved as a flag — and story progress).
- **NPCs**: `Npc` node. **Ommen** (hooded figure at candles: Awake, Wayside, Camp) tells the story one page per visit (the Oath, the Night, who he is, the road ahead), is "Hooded Figure" until the third talk, and has a one-time reaction after the Marshal falls, then idle lines. **Wenna the Pedlar** introduces herself once, then greets you and opens her shop.
- **Shop**: `ShopMenu` + `Shops` (stock, prices, buy rules). Ash Bandage 40, Pale Tonic 90, Pilgrim's Draught 150 embers; full stacks and empty pockets are refused without taking embers.
- **New items**: Pilgrim's Draught (heals 70), Marshal's Crest (key item, boss drop); icons added.
- **New enemies**: Carrion Crow (flying, reuses FlyingEnemy), Roadside Pikeman (long pike thrust, parryable; low sweep, unparryable - jump it).
- **Boss: Sir Orren, the Hollow Marshal** (900 hp): lance thrust and sweep (parryable, glint), couched charge (unparryable). Phase 2 adds a pole vault (unparryable) and **Raise the Banner** (calls two Carrion Crows, never more than two, no embers from them; a free opening). Drops the Marshal's Crest + 3200 embers. Third music pitch variant of the boss theme.
- **Sound**: talk blip, coin, caw (3 new sounds). Audio regenerated as a whole (noise-based sounds differ slightly from before).
- **Download size**: fonts subset to the characters used (Lora 212 -> 92 KB, GFS Baskerville 73 -> 7 KB; originals in tools/fonts_src, script tools/subset_fonts.sh), which pays for this chunk.
- Generators: `tools/gen_enemy_data.py` (newer enemy data/scenes), `tools/levels/gen_vaelmoor_road.py`.

### Verified
- **Automated suite: 83/83 pass** (new: dialogue box flow, shop buying rules + UI, NPC story pages / name reveal / one-time Marshal reaction / saved counter / Wenna intro then shop, road level wiring + population + candle fast travel + chest, road enemy data, Marshal boss incl. banner crows cap + rewards).
- Rendered captures (`tests/capture_road.tscn`): Ommen prompt + dialogue, Wenna, shop, the road's regions, pikeman / crow telegraphs, the Marshal's thrust, sweep, charge, roar, banner and crows - reviewed.
- Not verified: balance and feel of the road and the Marshal (nobody has played them); dialogue text has not been read aloud or proofread by anyone but me; Windows build not launched on Windows.

## 2026-10-12 — New enemies: Gloam Moth, Oathguard, Mimic (+ treasure chests)

- **Gloam Moth** (flying): hovers above and beside you, rears back with an eye glint, then dives in a straight line; after a dive it hangs dazed low — the time to hit it. Parried, it drops to the ground for a riposte. Village roofs / square, flooded nave.
- **Oathguard** (shielded): its tower shield blocks frontal hits while it is not swinging (your blade bounces back). Each blocked hit cracks the shield; heavy attacks drain guard much faster. Guard break = riposte window. Turns slowly, so rolling behind it works. Village square, catacomb stair.
- **Mimic**: looks exactly like a chest and offers "Open chest"; opening it springs an unparryable bite. The tell: it breathes ash every few seconds. Hit it first and it wakes staggered. Stays dead once killed; drops 3 ember shards and 400 embers. Village square ledge, start of the flooded nave.
- **Treasure chests** (real ones, so the mimic is a real question): village corridor (2 bandages + 120 embers), catacomb alcove (tonic + 300 embers).
- Engine: `HitData.Result.BLOCKED`; player recoils on a blocked swing. EnemySpawner `spawn_id`.

### Verified
- **Automated suite** — see the entry's final count in README; new tests: moth hover/dive/hit/daze/parry/fall/riposte, Oathguard block/drain/player-swing-blocked/guard-break/backstab/slow-turn, chest contents + flag, mimic dormant/ambush/bite/slain-flag/no-respawn/hit-first stagger.
- Rendered captures (`tests/capture_enemies.tscn`) reviewed.
- Not verified by a human: difficulty and fairness of the three enemies.

## 2026-10-12 — Fast travel, button remapping, difficulty & accessibility

- **Fast travel**: resting at a candle offers *Travel*, listing every lit candle grouped by area (lit candles were already on the map). Travelling makes that candle your respawn point and moves you there through the usual fade.
- **Settings split into tabs**: Display / Game / Controls (switch with the tabs, or Parry / Heal = L1 / R1).
- **Controls tab (remapping)**: every action shows its keyboard and controller binding (PlayStation or Xbox names). Select a cell, press the new key / mouse button / controller button; Esc cancels (also times out after 5 s). Taking a binding another action used swaps the two and says so. *Reset controls to defaults*. Saved to `user://input.cfg`; HUD prompts update immediately. Controller movement stays on stick + D-pad.
- **Difficulty / accessibility (Game tab)**: *Damage you take* 50–200 %, *Enemy health* 50–150 % (bosses included), *Parry assist* (+4 frames on every parry window). Saved in settings.cfg under `[gameplay]`.
- Test runner: `TEST_ONLY=test_a,test_b` runs a subset.

### Verified
- **Automated suite: 74/74 pass** (new: fast travel, remapping incl. listen → key press → saved file → jump still works → swap → Esc cancel → reset, difficulty scaling + parry assist window length, settings tabs with L1/R1).
- Rendered captures of all three tabs and the listening state reviewed.
- Not verified: remapping with a physical controller; nothing has been played on Windows by a human yet.

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

- (Manor chunk) Download size: sound effects now 16 kHz (was 24 kHz) to keep the Windows zip under the 31,457,280-byte chat limit (31,426,254 now: ~31 KB spare). Further content needs GitHub Releases.

## Combat depth, quests, side areas, day and night
**Added**
- **Hollowmere travel key (T)** with a combat lock (5 s after any blow dealt or taken, a hunting enemy within 360 px, any live boss fight). New remappable actions `travel_manor` and `skill`.
- **Status effects**: `StatusFx` (kinds, numbers), `StatusComponent` (buildup, trigger, DoT, frost slow, pips overhead) on enemies and the player; fields on AttackData / WeaponData / ArmorData / EnemyData; projectiles carry them; bosses are immune. HUD ring row.
- **Focus + weapon skills**: nine skills (data), focus from hits and parries, HUD bar, `skill` input. **Weapon parry/guard**: per-weapon window and recovery bonuses, hold-to-guard shield (block 75%, stamina cost, guard break).
- **Enemies**: Hollow Archer, Candle Cantor (`SummonerEnemy`, <=2 minions), elites via `EnemyData.elite` + `damage_mult` + `EliteMark`: Gilded Penitent, Oathguard Captain, Pike Sergeant.
- **Quests**: `Quests` (collect / kill / have / flag; flags only, no save change), offered / reminded / paid in dialogue; Journal tab in the pack; quest toasts. Manor-only lines for Ommen, Wenna, Hobb, Ilse. **Vesper**, ghost archivist, comments once on each lore item you carry.
- **Side areas**: Hollowmere Cellar (Grume the Cellarer -> Gallery Key), Hollowmere Gallery (Vesper, Ghostlight Raiment, lore), Pilgrim's Graveyard (cantors, archers, Gilded Penitent, Hale the Gravewarden -> Sexton's Lantern). Two mini-bosses on `BossBase` with a shared `brute_visual`.
- **Day/night**: `DayNight` (14-minute cycle from play time), `DayNightCycle` node (tint, sky, banners, `Events.daynight_changed`), EnemySpawner `when` (always / day / night); five night-only road spawners.
- Tests: now 112 (all passing) (new: travel key + combat lock, status, data validity, skills, focus, weapon parry and guard, new enemy data, archer and cantor, elite, quests, gating + manor lines, journal, side levels, gallery gate, minibosses, day/night).

**Verified**: see test run in the README. **Not verified**: feel and balance by a person; the Windows .exe on Windows.


## Step: UI polish for upgrading and trading
- Upgrade (candle) menu: three StatCards (Vigor/Endurance/Strength) with emblem, big value, 20 pips, "now -> next" numbers, ember price tag (red if unaffordable) and a pop animation on purchase; EmberChip counter in the header; Pack / Travel / Leave in a foot row.
- Shop: now a counter with BUY and SELL tabs (Parry / Heal switch tabs), item rows with icon, owned count and price, and a detail pane (large icon, description, effect, "you carry", embers before -> after). Selling pays 40% of buy price (Shops.SELL_RATE); embers shard / penitent's tear have fixed prices; keys and lore are never sold.
- Tests: new test_shop_selling; suite now 112, all passing (headless). Layout checked from screenshots (tests/capture_shop.gd) at 480x270 under Xvfb; not seen on a real Windows machine.
- Not done: the Forge menu still has the older plain look.

## Step: Forge restyle, tutorial tips, accessibility
- Forge menu now matches the shop: header with EmberChip + material count, weapon/armour tabs, list with price column (red when unaffordable), detail pane with large icon, level and cost. Row/describe/act API unchanged.
- Tutorial tips (systems/tutorial.gd): one-time hints for focus, status effects, manor travel, night, errands, weapon parry; shown by the HUD, remembered in save flags (`tip_<id>`), toggle in Settings > Game.
- Accessibility: colourblind-safe status colours (Okabe-Ito) via StatusFx.color_of, setting saved in settings.cfg.
- Tests: new test_tips_and_access (subset run passed; full suite run still pending at this step).
- Not done: a separate hold-to-parry toggle (shield already blocks while parry is held).

## Step: Bestiary and deeds
- Bestiary (systems/bestiary.gd): creatures are met when they first chase you or die; entries unlock lore after 1 kill and weaknesses/resistances after 3. Flags `bs_<id>`, `bk_<id>` (no save-format change).
- Deeds (systems/deeds.gd): 13 achievements (kills, bosses, errands, bestiary, level, all four statuses, gallery, surviving a night), flags `deed_<id>`, toast on unlock.
- Inventory menu now has 5 tabs: Equipment, Items, Journal, Bestiary, Deeds.
- Tests: new test_bestiary_and_deeds (subset passed). Not yet looked at in a screenshot.

## Step: Weapon infusions and relics
- Infusions (Forge.infuse): Hobb soaks a weapon in bleed/poison/burn/frost (300 embers + 2 Hollow Resin; cleaning is free). Stored as flag `infuse_<weapon>`; applied in Player.apply_loadout via Forge.effective_status. Button in the Forge detail pane cycles the infusion.
- Relics (systems/relics.gd): six passive trinkets as key-kind items, 2 worn at once from the new Relics tab (flag `relics_eq`). Effects: focus gain, weapon status buildup, status resist, ember gain, vial healing, parry focus. Sources: four errand rewards, Sexton's graveyard chest (Widow's Thorn), Gallery chest (Duellist's Glove).
- Sexton's second graveyard chest no longer gives 3 Ember Shards (now the Thorn).
- Inventory menu now has 6 tabs.
- Tests: new test_relics_and_infusion; affected forge/quest/chest/level tests pass in a subset run. Balance numbers are guesses.

## Step: Endings, quest chains, night merchant
- Oath Gate (world/story/oath_gate.gd, systems/endings.gd, ui/ending/ending_menu.gd): replaces the sealed Citadel exit at the end of the Vaelmoor Road. After the Marshal falls you choose KEEP, BREAK, or MEND (MEND needs every errand done and the Gallery opened). Epilogue pages then play; the choice is permanent for the save (flags `ending_chosen`, `ending_<id>`). A deed records reaching an ending. Epilogue text is a first draft for the creative director to rewrite.
- Quest chains: four follow-up errands (`needs` = the giver's first errand): Hobb (2 Pike Sergeants), Wenna (4 Gloam Moths), Ilse (show the Sexton's Lantern), Ommen (open the Gallery). Ommen's post-Marshal line updated.
- Night merchant: the Lantern-Man (Npc `when` = night only) on the road sells cheaper goods and Ember Shards. Placeholder pedlar art with a blue tint.
- Map screen already existed (ui/map), so nothing was added there.
- Tests: new test_endings, test_night_merchant; quest/sigil tests updated for the chain (subset runs pass; full suite pending). Not seen in a screenshot yet: Oath Gate art, ending screen.

## Step: New Game+, the Ashen Chapel, unique weapons
- New Game+ (GameState.begin_new_cycle, Main.begin_new_cycle): after an ending, interact twice at the Oath Gate to restart the story. Kept: weapons, armour, stats, embers, items, relics, infusions, deeds, bestiary, tips, candle lighting. Cleared: boss/chest/door/quest/conversation flags. Each cycle: enemies +60% health, +35% damage, +50% embers. Flag `ng_cycle`.
- The Ashen Chapel (world/levels/ashen_chapel.tscn, generated by tools/levels/gen_side_levels.py): reached through a new exit at the east end of the Pilgrim's Graveyard. Elites, archers, a cantor, sergeants, an Oathguard Captain, two candles, two chests, night spawners.
- Bosses: Mother Cinder (burn, drops Cinder Heart) and the optional Ser Ashfall, behind a cracked wall past the nave (bleed/frost, drops Ashfall Seal). Generated by tools/gen_side_areas.py; brute_visual.gd got CINDER and ASHFALL styles (recolours of the brute silhouette; placeholder art).
- Unique weapons: Cinderbrand (greatsword set, burn) and Ashfall Pike (lance set, bleed), forged by Hobb from the boss relics. New WeaponData.damage_mult (1.15). They reuse existing attack sets and icons.
- Vesper has lines for the new items and for every relic.
- Tests: new test_chapel_and_unique_weapons, test_new_game_plus; test_minibosses covers the new bosses (subset runs pass; full suite pending). Balance numbers for the new bosses/weapons are first guesses and nobody has fought them.
- Screenshots (Xvfb) of the chapel and the Oath Gate looked fine; Mother Cinder and Ashfall were not captured mid-fight.
- Full suite: 120 tests, all passing (119 in the full run, plus the one fixed afterwards re-run on its own).

## Step: Weapons tab, single-file download
- Inventory has a WEAPONS tab (after Items): every weapon in the game in a grid; ones you have show their icon, the rest are a grey "?" with "???" details. Press a found weapon to equip. Header counts found / total. IconSlot gained `locked`. Test: test_weapons_tab.
- Download is again one zip (31,352,644 bytes, under the 31,457,280 limit) by re-encoding music (8 kHz, 10 kbps) and effects (12 kHz, 12 kbps). Sound quality is worse than before; not listened to.

## Text smoothing (inventory / weapons / shop)
- Font imports: hinting off, subpixel positioning 4, mipmaps on (Lora + GFS Baskerville).
- Numbers in ember chip / stat cards / weapons+relics headers use the Lora body font (lining digits) instead of old-style numerals.
- Verified: screenshot at 1920x1080 looks smooth; 4 UI tests pass. Not verified: appearance on a real Windows display, or in the low-res chunky (non-hires) mode.

## Step: Expansion (second region, weapons, arts, variety, secrets, trials, story, audio)
- **Sunken Reliquary** (world/levels/sunken_reliquary.tscn, tools/levels/gen_side_levels.py `reliquary()`): entered by a new stair at the east end of the Ashen Chapel's vestry. Stone-vault backdrop (reuses the cellar hall art), wading water, hidden Lurkers, Drowned Pilgrims, an archer loft, a cantor, an elite, an Oathguard Captain, fire jets, spike pit, three candles, the merchant Pell (shop `salt_diver`, two-part errand), and the boss Abbot Merrow, the Salt Abbot (generated by tools/gen_reliquary.py; brute_visual.gd style SALT, placeholder recolour). Drops the Abbot's Signet.
- **Weapons** (tools/gen_weapons2.py): Gravedigger's Greataxe (new AXE look; found in a hidden chest behind an illusory wall), Veilglass Daggers (twin look, fast, poison; forged from a Lurker's Fang), Candle Catalyst (new STAFF look; light/heavy attacks fire bolts; forged from a Cantor's Wick, found in a hidden chest), Abbot's Crozier (STAFF look, frost, holds a guard; forged from the Signet). Player can now fire projectiles (`Player._fire_player_projectile`, `Projectile.target_mask`).
- **Arts** (systems/arts.gd, tools/gen_arts.py, inventory ARTS tab): six focus abilities, each taught by a boss, one equipped, cast with the new Art action (U / left trigger, remappable). State: world flags `art_has_*`, `art_equipped` (kept through New Game+).
- **Enemy variety**: elites roll a modifier (frenzied / stoneskin / venomous; tinted marker); `pack_alert` enemies call unaware neighbours; the Reliquary Lurker is a hidden ambusher (actors/enemies/lurker.gd).
- **Secrets and hazards**: IllusoryWall (walls and blocks with no collision, flag `secret_<id>`), FireJet (warn then burst, burns), Secrets helper counts them (breakable walls count too; deed "Seeker" at 4).
- **Challenge**: the Trial Ring (world/levels/trial_ring.tscn; entered by a door in Hollowmere Manor that opens once an ending is chosen): Boss Rush (7 bosses in a row, timed) and a ten-wave Gauntlet, records and one-time rewards (systems/trials.gd). Bosses that were never beaten are marked defeated by a Rush win (so their arts unlock).
- **Story**: first meeting with a boss shows letterbox bars with its name and a lore line (flag `intro_<id>`); each ending tints the epilogue its own colour and types the text. More deeds (Book Closed, Seeker, Every Art, Giant Slayer).
- **Audio**: no new sound files (size limit: the zip is within ~55 KB of the one-file cap). New events reuse existing sounds (fire jet burst = burning sound, secret = relic chime). Levels of all 66 files measured with ffmpeg: none silent; swing_light peaked at 0 dB so it was turned down 5 dB. I cannot listen, so music quality is still unjudged.
- Tests: 8 new (region, lurker, elite modifiers/alert, arts, second weapon set, secrets/hazards, trials, boss intro card); the three old tests that changed (attack data, remapping count, only-shield-guards) updated. Full suite: 129 tests, all passing (run headless, after the last code change).

## Step: The Hollow Keep (3 more bosses)
- **The Hollow Keep** (world/levels/hollow_keep.tscn, tools/levels/gen_side_levels.py `keep()`): entered by a new exit at the east end of the Sunken Reliquary (`ToKeep` / entry `from_keep`; keep entry `from_reliquary`). Three zones, each with a candle, a lore tablet, enemies and one boss arena. Chests, fire jets and a gantry for variety.
- **Bosses** (tools/gen_keep.py): Gaoler Vess, the Chain-Warden (long-reach sweeps, chain hurl, dragging lunge; 900 HP); Foundrymaster Brand (slow heavy hits, burning slag, molten pour in phase 2; 1050 HP); the Hollow Regent (fast cuts, thrust, volley, "The Oath Breaks" leap; 1400 HP). Each is a two-phase BossBase scene with its own brute_visual style (GAOLER, FOUNDRY, REGENT: all placeholder recolours/props of the brute).
- **Relics** (drops): Gaoler's Shackle (resist 30% status), Foundry Ladle (Ember Vials heal 40% more), Hollow Crown (parry gives 20 focus). They use existing relic effects, so no new hooks. Vesper has a line for each.
- Registered in: Bestiary, Deeds (Unchained, Furnace Out, Long Live Nobody), Audio voices, Boss Rush (now 10 bosses), World map, item icons.
- Tests: test_minibosses covers the three bosses (two-phase, attacks, hurts the player, drop, archive line); new test_keep_region (level, placement, links, registration).
- Balance numbers are first guesses; none of the three bosses has been fought by a person.

## Step: Drowned Belfry, Crown ending, Hesk, boss-death feel
- **The Drowned Belfry** (world/levels/drowned_belfry.tscn, `belfry()` in gen_side_levels.py): entered from the east end of the Hollow Keep (`ToBelfry` / `from_belfry`). Reuses bell bearers, moths, elites, cantor, pilgrim; fire jets and spikes. Boss **Verger Tolland, the Last Ringer** (tools/gen_keep.py, brute_visual style RINGER, 1200 HP) drops the **Bell Clapper** relic (foes pay 35% more embers). Deed "Silence in the Tower"; in the Boss Rush (now 11 bosses).
- **Fourth ending, "Take the Crown"** (systems/endings.gd): unlocked by defeating the Hollow Regent (flag boss_defeated_hollow_regent); tint and banner added. No save-format change.
- **Hesk**, a freed prisoner in the Keep, with one errand ("The Last Link": show him Vess's Shackle). Note: Quests.ORDER grew by one, so the "Mend" ending and the "Good Neighbour" deed now also need this errand, which needs the Gaoler dead.
- **Boss death feel**: a 0.3 s freeze, a heavy shake and a spark burst when any boss dies (honours the hit-stop and screen-shake settings).
- Not done: shortcut gates (candles already work as fast travel, the new levels are linear), real art, audio rework, GitHub.
- Tests: new test_belfry_and_crown; test_minibosses covers the Ringer.

## Step: Four more parts (Bleeding Gardens, Iron Orrery, Sunken Basilica, Crownless Citadel)
- Four regions chained after the Drowned Belfry (Belfry `ToGardens` → Gardens → Orrery → Basilica → Citadel; each has `ToPrev`/`ToNext`, entries `from_prev`/`from_next`). Generated from `PART_SPECS` / `parts()` in tools/levels/gen_side_levels.py: 5000 wide, two candles, two lore tablets, ~11 enemies (existing types, themed per region), three chests and a cache, one hazard type (spikes / fire jets / water), one boss arena. Map origins continue along the world map.
- Bosses (tools/gen_parts.py, brute_visual styles THORN / IRON / BASILICA / CROWNLESS): Elsbet the Thornmother (1300 HP, poison), Calloway the Orrerist (1450, bleed), Bishop Anselm the Drowned (1650, frost), the Crownless King (2200, burn). Four attacks each (three plus a phase-2 leap), first-guess numbers.
- Relics: Briar Locket (focus +40%), Orrery Gear (weapon status +50%), Drowned Chalice (vial heal +60%), Oathbreaker's Ring (parry +30 focus). Existing effects, no new hooks. Vesper has lines for each. Deeds for each boss; all four join the Boss Rush (15 bosses now).
- Tests: test_four_parts (levels, links, placement, registration), test_minibosses extended to every boss.
- Not done: new enemy types for these regions (they reuse existing ones), NPCs, real art.

## Step: Animated main menu
- ui/menu/menu_anim.gd (MenuAnim), added by main_menu.gd `_build_backdrop`: twinkling stars, breathing moon halo, two drifting mist bands, a flickering candle, rising embers, a lone lantern-bearer pacing the ledge, slow parallax sway of the three ruin layers. On launch the screen fades up from black and the title column fades in piece by piece (`_intro`). Purely visual, no state.
- tests/capture_menu.tscn saves three title-screen frames (needs a display). Checked: frames at 8 / 100 / 160 show the fade, the walker and mist moving (software GL under Xvfb). Not checked: on a real Windows display, motion smoothness, or with a controller.
- Temporary art: the figure and mist are simple procedural shapes.

## Step: Talismans and alchemy (timed potion buffs)
- **Talismans** (systems/talismans.gd, generated systems/talisman_data.gd + data/items/tal_*.tres via tools/gen_talismans.py): 16 unique boss talismans (every boss drops its own, once, through GameState._on_enemy_killed → Talismans.roll_drop) and 7 smaller ones that elite enemies drop (12% chance, from the not-yet-owned pool). Wear up to 3 on the new TALISMANS tab of the pack; worn list is the world flag `tal_eq` (no save-format change). Effects: damage, damage taken, max health, stamina regen, run speed, embers from kills, vial healing, focus gain, weapon status, status resist, focus per parry.
- **Boosts** (systems/boosts.gd) adds talisman and potion effects; hooks in Player (apply_loadout, apply_stats via _max_health_value, add_focus, parry focus, damage bonus) and GameState (embers). Relic effects stay separate and multiply with these.
- **Potions / Alchemy** (systems/buffs.gd, systems/alchemy.gd): 7 potions (Might, Ward, Vigor, Swiftfoot, Embergreed, Resolve, Focus), new ItemData.Effect.BUFF. The ALCHEMY tab brews them from carried materials plus a few embers; drink them from the ITEMS tab or as the quick item. Buffs last 3 to 5 minutes, run down only while playing, show on the HUD (ui/hud/buff_bar.gd), are NOT saved, and end on death or when a game starts or loads.
- Pack UI: two new tabs (TALISMANS, ALCHEMY); to fit ten tabs the tab font is smaller and EQUIPMENT is labelled GEAR. The relic list now scrolls too (it had no room for all 14+ relics).
- Boss Rush side effect: rush kills also grant boss talismans (like arts).
- Tests: test_talismans, test_potions_and_alchemy. Screenshots (Xvfb) of the HUD, both tabs and the tab bar looked right. Not verified: balance of the numbers, controller navigation of the new tabs, Windows display.
- Items.IDS lists the talisman and potion ids literally (a class constant cannot be built from another class's constant); re-running gen_talismans.py with new entries needs those ids added to Items.IDS (test_talismans fails if one is missing).

## Step: Talisman icons
- ui/icons/talisman_art.gd (TalismanArt): every talisman has its own procedural 16x16 icon (bell, crest, key, nail, flame, post-and-bar, tear, salt crystals, chain links, anvil, crown, bellflower, thorn seed, gear, wafer-cross, four-point star, bead, feather, ember bead, needle and thread, whetstone, knot, pebble). Boss talismans get a gilded rim, four studs, a glowing gem tinted by the item colour and a pulsing aura; elite ones get a plain silver rim. IconArt routes `tal_*` ids to it.
- tests/capture_icons.tscn renders a contact sheet of all of them (needs a display). Checked visually in Xvfb; not on a Windows display. Still placeholder art, not hand-painted.
- Size: to stay under the one-file cap the night and chapel music were re-encoded at 8 kbps (was 10); not listened to. Zip 31,433,221 bytes.

## Step: The Descent (11 maps, 33 bosses) + fixes
- **Content**: tools/expansion_data.py (data) + tools/gen_expansion.py generate 33 bosses (22 mini, 10 main, 1 final: the Oath Eternal), their enemy data, 108 shared attack sets, 33 talismans (tools/gen_talismans.py), 6 new weapons and the registrations (Bestiary, Weapons, WorldMap, Deeds incl. a "25 giants" deed). systems/expansion.gd is generated. The new bosses use the brute rig's new `CUSTOM` style (coat, trim, prop, scale per boss).
- **Maps**: tools/levels/gen_side_levels.py `grand()` writes 11 maps (7,400 px wide, 3 arenas each: mini, mini, main/final; 4 candles, 3 tablets, hazards, 7 chests). They chain on from the Crownless Citadel (its right edge now leads to the Weeping Ossuary) down to the Hollow Heart. A 5th ending, "Go Unsworn", unlocks when the Oath Eternal falls.
- **Fixes**: the TRAVEL list now scrolls (ScrollContainer, wheel and controller focus). The forge lists weapons you own first under "YOURS - UPGRADE", then "NOT OWNED - FORGE A NEW ONE"; unowned weapons say they cannot be upgraded (the rule itself already refused). The 2 shop-less weapons (rapier, greatsword) now sit in chests in the Cellar and Graveyard; the six new weapons are in chests at the end of six Descent maps; the WEAPONS tab shows "Where to find it" for every weapon you lack (Weapons.HINTS).
- **Size**: music trimmed to 32 s loops (village, night, chapel, yard) and Lora subset to Latin to stay under the cap: zip 31,433,938 bytes. Not listened to.
- Tests: test_descent added; screenshot (Xvfb) of the scrolled travel list checked.

## Step: Wayfarers of the Descent (story, items, armour, backdrops)
- **Story**: the Descent now has a thread: the First Oath was nine words between a candlewright (Aure) and a soldier (Wend), copied by the kingdom until it hollowed; at the bottom Wend still keeps it. Eleven **Wayfarers** (one per new map; tools/descent2_data.py -> generated systems/descent_npcs.gd, hooked into Dialogues) tell it in three conversations: a first meeting, passing lines, and a farewell after the map's main boss falls that gives a **keepsake** (lore item). Flags: `talks_<id>` (shared), `dn_after_<id>`; no save change. Vesper comments on every keepsake and new relic.
- **Shops**: three Wayfarers sell (Ouse in the Tallow Mines, Haggle in the Bone Market, Tove in the Forge of Vows): `Shops.stock` consults `DescentNpcs.SHOPS`.
- **Gear**: 11 new armours (data/armors, one hidden chest per map at x=3650), 8 consumables (heal / stamina / embers), 11 wearable relics (one dropped by each new main boss; effects reuse the six existing relic effects at higher values). Icons for armour/relic use the generic routines (placeholder).
- **Graphics**: world/background/descent_backdrop.gd replaces the manor hall in the 11 maps: 11 themes, two parallax silhouette layers drawn only for the visible part, haze, light shafts, themed ambient particles (embers, bubbles, pages, glints, spores, snow) and flickering PointLights; the Hollow Heart pulses. Contact sheet checked in Xvfb (all 11 look distinct); not on a Windows display.
- Tests: test_wayfarers (conversations, farewell once, gifts, shops, armour/item/relic validity, Vesper). Generators: tools/gen_descent2.py (idempotent).
