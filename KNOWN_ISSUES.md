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
- Save/load to disk (Milestone 5). Checkpoint state lives only in memory; quitting resets progress.
- Main menu, settings screen, remapping UI (Milestone 10; remapping backend exists).
- Air dodge is not available (deliberate for now — decide in playtest).
- Enemies do not block the player's body (player passes through enemies; only attacks deal damage). Deliberate for M1; revisit with final sprites.
- Enemy AI does not path across platforms; enemies stay on their floor segment.
- Boss state machine (Milestone 6).

## Minor
- With hit-stop on, overlapping hits supersede rather than extend the freeze (intended, but very short freezes may feel clipped).
- Far-layer lit windows can look like they float, because distant spires are close in colour to the sky.
