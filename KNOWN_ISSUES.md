# Known Issues & Placeholders

## Unverified
- **Windows .exe not launched yet.** It was exported successfully and the same data pack runs outside the editor on Linux, but nobody has run it on Windows 10/11. Please launch it and report: does it start, frame rate, controller detection.
- **Game feel untested by a human.** Timings were set by design and verified by tests, not by hands-on play. Expect tuning requests.
- **Gamepad bindings** are defined but untested on a physical controller.

## Placeholders (by design for Milestone 1)
- **All art is TEMPORARY procedural art** drawn in code (`*_visual.gd`, `StoneBlock`, backgrounds). Final Aseprite sprites arrive in Milestone 4 (protagonist) and Milestone 5 (first region).
- **No audio at all** — no SFX or music. Volume setting exists but nothing plays.
- In-world control hints in the test arena are hard-coded to default keys.
- Default Godot font for UI.

## Missing (planned)
- Remapping UI (Milestone 10; the remapping backend exists). The settings screen currently has screen shake, hit flashes, hit-stop and master volume.
- Saves currently contain: checkpoint, deaths, play time, current level and world flags. Inventory, equipment, quests and map discovery will be added as those systems arrive (the save format is versioned for this).
- Enemies killed since your last rest are not saved (by design: they revive on rest and on death anyway).
- Air dodge is not available (deliberate for now — decide in playtest).
- Enemies do not block the player's body (player passes through enemies; only attacks deal damage). Deliberate for M1; revisit with final sprites.
- Enemy AI does not path across platforms; enemies stay on their floor segment.
- Boss state machine (Milestone 6).

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
- Menu text uses the default Godot font (custom pixel font planned).

## Minor
- With hit-stop on, overlapping hits supersede rather than extend the freeze (intended, but very short freezes may feel clipped).
- Far-layer lit windows can look like they float, because distant spires are close in colour to the sky.
