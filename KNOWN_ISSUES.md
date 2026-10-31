# Known Issues & Placeholders

## Unverified
- **Windows .exe not launched yet.** It was exported successfully and the same data pack runs outside the editor on Linux, but nobody has run it on Windows 10/11. Please launch it and report: does it start, frame rate, controller detection.
- **Game feel untested by a human.** Timings were set by design and verified by tests, not by hands-on play. Expect tuning requests.
- **Gamepad bindings** are defined but untested on a physical controller.

## Placeholders (by design for Milestone 1)
- **All art is TEMPORARY procedural art** drawn in code (`*_visual.gd`, `StoneBlock`, backgrounds). Final Aseprite sprites arrive in Milestone 4 (protagonist) and Milestone 5 (first region).
- **No audio at all** — no SFX or music. Volume setting exists but nothing plays.
- In-world control hints in the test arena are hard-coded to default keys.
- UI fonts are stand-ins chosen from the fonts installed on the dev machine.

## Missing (planned)
- Saves currently contain: checkpoint, deaths, play time, current level and world flags. Inventory, equipment, quests and map discovery will be added as those systems arrive (the save format is versioned for this).
- Enemies killed since your last rest are not saved (by design: they revive on rest and on death anyway).
- Air dodge is not available (deliberate for now — decide in playtest).
- Enemies do not block the player's body (player passes through enemies; only attacks deal damage). Deliberate for M1; revisit with final sprites.
- Enemy AI does not path across platforms; enemies stay on their floor segment.
- Boss state machine (Milestone 6).

## Hollowmere Manor
- Placeholder art throughout (procedural hall, ghosts, Aldous). The manor is dim by design; if NPCs are hard to read on your monitor, tell me and I will brighten it further.
- Residents repeat their field dialogue (Ommen's idle lines etc.), with no manor-specific lines yet except Aldous. The Gallery is sealed; nothing lies beyond it yet.
- The sigil is saved as a flag holding where you left from; a save edited by hand to a bad level falls back to the last candle.
- Resting at the manor candle makes the manor your respawn point.

## Gear
- Balance is untested by a human: weapon damage/speed, upgrade and forge costs, material drop rates, naked/heavy armour trade-offs. The greatsword and hammer are deliberately slow; the rapier and sabre deliberately fragile in reach/poise.
- Parry window and dodge base cost stay with the character (preset), not the weapon: a shield-less Bulwark keeps its 12-frame parry. Weapons do not yet have strength requirements.
- Placeholder art: all weapon/armour visuals and icons are procedural; heavy armours differ mainly by silhouette and colour.
- Relic-gated gear can be forged any time the relic is carried, but the relic items are one-off drops: if a boss is skipped the item cannot be forged.
- No selling or dismantling of gear; unused weapons/armour stay in the pickers.

## After the prologue
- The Marshal, the road and the new enemies are untested by a human: expect balance changes. The Marshal's banner window and the crows' damage are the most likely to need tuning.
- The road ends at a sealed gate ("coming in the next build"); there is no area beyond the Crossroads yet.
- Dialogue is text only (no portraits, no voices); the typing blip is a placeholder sound. Conversations cannot be re-read once finished (Ommen's story pages are said once, in order; only idle lines repeat).
- NPCs and the candles share the Interact button: stand a few steps from the candle to talk to Ommen (they are placed ~80 px apart on purpose).
- The shop has unlimited stock and no selling. Embers are the only currency.
- Placeholder art for Wenna, Ommen, the pikeman, crow and Marshal is procedural.

## New enemies
- Moth, Oathguard and Mimic balance is untested by a human. Moth dive parry timing is at contact (later than the glint), unlike ground enemies.
- Flying enemies do not path around walls; they slide along them. A parried moth over water/the drowned shaft falls in (it does not drown; it lies on the bottom).
- The mimic's tell (breath of ash) is small at 1080p in a dark area; may need to be stronger.

## Remapping / difficulty
- L2 / R2 (analog triggers) cannot be bound yet; only digital buttons are accepted on the controller column.
- Esc always cancels listening, so Esc cannot be assigned through the menu (it is Pause by default; *Reset controls* restores it).
- Rebinding the keyboard column replaces all keys of that action (e.g. Dodge "L / Shift" becomes just the new key).
- Difficulty sliders are untuned beyond the obvious maths; no "difficulty" label is shown on saves.

## Prologue ending
- There is no way back from Vaelmoor, Awake to the Hollow areas except dying (which returns you to your last candle) — decide whether that is intended.
- The daylight area reuses the menu music (pitched up) because the download is at its size limit.

## Drowned Catacombs / Drowned Canon / map
- Untested by a person: the shaft crossing (20 px stepping stone while wading), wave-jump timing, Canon balance (820 HP).
- The Canon's body is drawn over the floor while it sinks (it fades out instead of being clipped by the water).
- Enemies are not slowed by water; only the player is.
- Map: no minimap, no markers you can place, no fast travel; the level layout on the map is schematic (door positions line up, nothing else is to scale between areas).
- The Windows zip is only ~65 KB under the 30 MB chat upload limit.

## Forsaken Village / travel
- Blockout quality: plain masonry blocks, no house details, no ladders; the rooftop climb uses three planks.
- Not play-tested by a person: jump distances, enemy density (10 enemies) and the two candles' spacing are first guesses.

## Audio
- All audio is synthesised placeholder and has never been listened to by a person; volumes/mix are estimates.
- Music loops start on a bell/drum hit; if the loop point is audible, the generator's loop lengths can be adjusted.

## Boss
- Bell-Warden balance is untested by a human (650 HP, damage 20-36 per hit, cooldowns). Tune in `data/enemies/bell_warden.tres` and `data/attacks/warden_*.tres`.
- No boss music, sounds, intro cutscene or camera framing yet; the name banner is the intro.
- The boss can be pressed against the gate pillar while the gate is open (only after the player has died, when it idles until the respawn reset).

## Economy / inventory
- Numbers (ember rewards, level costs, +8/+6/+4% steps, item effects) are first-pass and unplaytested; there is only one enemy type, so embers have little to spend on yet.
- No shops/NPCs, no equipment swapping (the equipment screen shows your preset's one weapon and armour), and no item uses beyond four consumables; the Rusted Key opens nothing yet.
- Candle menu opens automatically after resting (about 1 second), with no option to disable it yet.
- Items can be used in the pack while paused; healing at full health is blocked, but there is no cooldown or use animation (instant).

## Controller
- Never tested with a physical DualSense. Prompts for rebound buttons follow the bindings, and can be changed in Settings → Controls (remapping not yet tried on a physical pad). Pause menu has no button hint bar. L2/R2 and the touchpad are unbound.

## Video
- Fps above 60 relies on Godot 2D physics interpolation; a one-frame smear may appear after teleports (respawn/rest). Untested on a real high-refresh monitor.
- Art is still low-detail placeholder; High-res mode makes that more visible, not less.

## Presets
- Preset balance is untested by a human; stat numbers live in `data/presets/*.tres` and `data/attacks/`.
- Perk/drawback text on the selection screen is hand-written in each preset file, not generated, so it must be updated by hand when numbers change.
- Preset is fixed per save slot; there is no in-game respec or armour/weapon swapping yet (equipment system planned).
- All preset art is temporary procedural placeholder art.

## Save system notes
- Verified: unit tests for corruption/tampering/backup recovery/newer versions/write failure, an in-process menu flow test, and a two-process write-then-read check on Linux. **Not yet tried on Windows** (Windows cannot rename over an existing file, so the code has a remove-then-rename fallback; the backup file covers that moment, but it has only been exercised on Linux).
- Hand-editing a save file makes it fail its checksum and count as damaged (it falls back to the backup). This is intentional integrity protection, not a bug.
- Progress is saved at candles and respawns only, so quitting mid-fight loses everything since the last rest ("Progress since your last rest is lost" warning in the pause menu).
- Menu text now uses Lora / GFS Baskerville (bundled, OFL). Text is smooth, not pixel-art, and looks softer in the 480x270 Pixel graphics mode.

## Minor
- With hit-stop on, overlapping hits supersede rather than extend the freeze (intended, but very short freezes may feel clipped).
- Far-layer lit windows can look like they float, because distant spires are close in colour to the sky.

## Combat depth, quests, side areas, day and night (new)
- **Nothing here has been played by a human.** Automated tests cover the rules (triggers, resists, skills spend focus and hit, parry windows, guard, quests, levels load and are grounded, mini-bosses attack and enter phase two, the cycle spawns and removes night enemies), not whether it feels good. Skill costs, focus gain, status numbers (bleed 16% burst, poison 2%/s, burn 4%/s, frost x0.62), elite stats and mini-boss health are first guesses.
- **Temporary art**: the Archer, Cantor, both mini-bosses, Vesper, the cellar/gallery/graveyard backdrops and the focus bar are procedural placeholders.
- Frost slows walking (and dodge/air control through the shared move multiplier) but not attack speed.
- Focus is not saved: it resets to 30 on loading a game and to full when you rest.
- Day/night follows play time, so a long menu session does not advance it; resting does not skip the night. Night enemies despawn at dawn only if they are not already hunting you.
- The summoner's minions are Gloam Moths; they count for kill errands (a Wenna crow errand also counts crows summoned by the Marshal).
- Weapon skills fire from the ground only; there is no aerial skill.
- `gen_enemy_data.py` is older than the status system: re-running it rewrites the enemy/attack files without the `status` / `status_resist` lines added since. Re-apply them (or avoid re-running it) - see git history for the tables.
- Download size: the build zip is expected to exceed the 30 MB chat limit with this content; use GitHub Releases (not connected yet).


## UI polish (trading / upgrading)
- The Forge menu (ui/forge/forge_menu.gd) has not been restyled to match the new shop and upgrade screens.
- Sell prices are first-guess balance; there is no buy-back.
- Layout verified only via headless/Xvfb screenshots, not on Windows or with a controller.

## Endings, New Game+, Ashen Chapel
- Epilogue texts are drafts; no music or art for the endings, just text pages.
- New Game+ keeps all relics and weapons; the scaling (+60% HP, +35% damage per cycle) is a first guess and compounds linearly, not tuned.
- Mother Cinder / Ser Ashfall reuse the brute silhouette with new colours; Cinderbrand and Ashfall Pike reuse existing attack sets and icons (placeholder).
- The chapel sky is the graveyard's with a warmer tint.
- Ser Ashfall's crypt is behind a breakable wall; there is no hint besides a tablet.
- Quest chain `ilse_lantern` only needs you to carry the Sexton's Lantern.

## Download size
- The Windows build must fit one chat file (< 31,457,280 bytes zipped). The Godot template alone zips to ~30.1 MB, leaving ~1.3 MB for the game. To fit, music is encoded at 8 kHz / 10 kbps and effects at 12 kHz / 12 kbps (muffled; originals can be regenerated with tools/audio/gen_audio.py and gen_audio_extra.py, whose Ogg settings are higher quality). Publishing builds as GitHub Releases would remove this limit.

## Expansion (Sunken Reliquary, arts, trials)
- **Nobody has played any of it.** Tests cover rules (loads, grounded placement, ambush wakes, arts cost and cast, weapons equip and hit, trial waves, records). Numbers (boss health, art costs, wave sizes, rewards, modifier strength) are first guesses.
- Placeholder art: Salt Abbot is a recolour of the brute; Lurker and Drowned Pilgrim are new/tinted placeholders; the Reliquary backdrop reuses the cellar's casks and racks; catalyst/crozier/axe icons are simple drawings.
- Arts have no icons and no HUD indicator (the Arts tab shows the equipped one). Tidecall and Ember Lance are straight bolts (no wave).
- The Boss Rush skips the Drowned Canon (needs its flooded arena). Winning it marks every rush boss defeated, which also unlocks their arts for a save that had not beaten them.
- The Gauntlet and Rush spawn in the ring without gates; the player can still wander left; only the exit is sealed during a run.
- No ShortcutGate in the Reliquary (the village still has the only one).
- New weapon/art sounds reuse existing effects; the Art button on a pad shows a generic trigger glyph.
- Download size: ~55 KB under the single-file cap. Any further content needs audio trimmed or the build published elsewhere.

## The Hollow Keep (3 bosses)
- Placeholder art: Gaoler Vess, Foundrymaster Brand and the Hollow Regent are recolours of the brute with small extra props (chains, embers, crown). The Keep reuses the cellar-style backdrop with a warm tint.
- Boss balance (HP, damage, timings) is untested by a human. Only automated tests ran: they check the bosses attack, hurt, change phase and drop their relic, not that the fights are fun or fair.
- The three relics reuse existing effects (status resist, flask heal, parry focus), so they stack in a similar way to the older relics.
- Windows build still not launched on Windows.

## Drowned Belfry / Crown ending
- Last Ringer is another brute recolour (placeholder, bell prop); its balance is a first guess and untested by a human.
- The Crown ending's epilogue text and tint are first drafts; the ending menu now has four buttons and was not checked visually.
- The "Mend" ending now needs Hesk's errand, so it needs Vess killed in the Keep. Intentional, but worth knowing.

## Four more parts
- The four new regions share one layout template (different enemies, hazards, tint and lore), so they will feel similar to walk. They have no new enemy types, NPCs or shops.
- The four bosses are placeholder recolours of the brute with small props; their balance numbers are guesses that no human has tested. The Boss Rush (15 bosses) is very long and its reward was not retuned.
- The Hall backdrop styles used (0 and 1) were not looked at on screen for these regions.
- Windows build still not launched on Windows.

## Talismans and alchemy
- All talisman and potion numbers are first guesses; stacking three boss talismans plus potions can make the late game much easier. Nobody has played it.
- Potion buffs are not saved: quitting or loading drops them. Dying also ends them.
- Potion icons all use one vial picture (colour not varied); talismans use the relic icon style. Placeholder art.
- Talisman and potion text, drop chances (12% for elites) and recipe costs are untested by a human. The elite pool only drops talismans you do not own yet.
- Boss Rush grants boss talismans (as it does arts).

## The Descent
- All 11 maps share one layout template and all 33 bosses are brute-rig recolours with generated attack sets: expect repetition. Balance numbers (hp, embers, talisman strengths) are guesses nobody has played; a full playthrough was not done.
- Music loops for four tracks were shortened to 32 s (not listened to; a loop seam may be audible). Candle order in the travel list within one map is reversed.
- The Unsworn ending, new weapon icons (reusing existing shapes) and the 33 talisman emblems (8 generic shapes) are placeholder.
- Windows build still not launched on Windows; Hall backdrops and the 5-button ending menu were not checked on screen.

## Wayfarers update
- Dialogue and lore are first drafts for the creative director to rewrite; the Descent story (the First Oath) is new and not yet foreshadowed by earlier tablets or NPCs.
- Armour numbers, relic strengths and shop prices are untested guesses. The 11 relics are stronger than the old ones; with 2 slots they can trivialise the late game.
- The backdrops draw per frame (cheap per slot) but were not profiled; frame rate on a real Windows machine is unverified. Backdrop colour and silhouette art are procedural placeholders.
- Keepsakes have no mechanical use (lore only) and use the generic item icon.
- The Descent difficulty ramp is by health only (attack damage is shared by tier); nobody has played it, so the pacing is a guess.
- The Oath Gate asks a second time after the Oath Eternal falls (only Go Unsworn is offered then); the earlier choice stays recorded as a deed. Not played through by a human.
