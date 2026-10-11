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
