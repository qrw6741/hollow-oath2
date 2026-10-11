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
- Remapping UI (Milestone 10; the remapping backend exists). The settings screen currently has screen shake, hit flashes, hit-stop and master volume.
- Saves currently contain: checkpoint, deaths, play time, current level and world flags. Inventory, equipment, quests and map discovery will be added as those systems arrive (the save format is versioned for this).
- Enemies killed since your last rest are not saved (by design: they revive on rest and on death anyway).
- Air dodge is not available (deliberate for now — decide in playtest).
- Enemies do not block the player's body (player passes through enemies; only attacks deal damage). Deliberate for M1; revisit with final sprites.
- Enemy AI does not path across platforms; enemies stay on their floor segment.
- Boss state machine (Milestone 6).

## Forsaken Village / travel
- Blockout quality: plain masonry blocks, no house details, no ladders; the rooftop climb uses three planks.
- Not play-tested by a person: jump distances, enemy density (10 enemies) and the two candles' spacing are first guesses.
- The chapel door is sealed: the village is the end of the current build.
- No map, so the shortcut and routes are only signposted by the gate prompt.

## Audio
- All audio is synthesised placeholder and has never been listened to by a person; volumes/mix are estimates.
- Music loops start on a bell/drum hit; if the loop point is audible, the generator's loop lengths can be adjusted.

## Boss
- Bell-Warden balance is untested by a human (650 HP, damage 20-36 per hit, cooldowns). Tune in `data/enemies/bell_warden.tres` and `data/attacks/warden_*.tres`.
- No boss music, sounds, intro cutscene or camera framing yet; the name banner is the intro.
- The boss can be pressed against the gate pillar while the gate is open (only after the player has died, when it idles until the respawn reset).

## Economy / inventory
- Numbers (ember rewards, level costs, +8/+6/+4% steps, item effects) are first-pass and unplaytested; there is only one enemy type, so embers have little to spend on yet.
- No shops/NPCs, no equipment swapping, and no item uses beyond four consumables; the Rusted Key opens nothing yet.
- Candle menu opens automatically after resting (about 1 second), with no option to disable it yet.
- Items can be used in the pack while paused; healing at full health is blocked, but there is no cooldown or use animation (instant).

## Controller
- Never tested with a physical DualSense. Prompts for rebound buttons follow the bindings, but there is no in-game remapping UI yet. Pause menu has no button hint bar. L2/R2 and the touchpad are unbound.

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
