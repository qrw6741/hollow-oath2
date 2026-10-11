# Repeatable Testing Checklist

Run **automated tests first**: `godot --headless --path . --fixed-fps 60 res://tests/run_tests.tscn` → must end with `0 failed`.

Then play the test arena (F3 shows state, frame counter, i-frames). Tick each item; note build/version.

## Movement
- [ ] Run left/right feels responsive; stops quickly.
- [ ] Tap jump = short hop; hold = full jump (~3 tiles). Jump works a few frames after walking off a ledge (coyote).
- [ ] Jump pressed just before landing still jumps (buffer).
- [ ] Can jump up through planks from below and stand on them.
- [ ] Camera leads in the facing direction, never shows outside the arena.

## Combat
- [ ] Light ×3 on the dummy: three distinct swings, dummy total = 45.
- [ ] Mashing early still produces the combo (queued), not dropped inputs.
- [ ] Heavy has a visible wind-up, lunges, hits for 32.
- [ ] Jump + light = falling cut; landing ends it.
- [ ] Late in a swing, dodge cancels it; early in a swing, it does not.
- [ ] Stamina bar drains per action; empty bar blocks the next action until it regenerates.
- [ ] Dodge through a Penitent's blow: no damage (F3 "i-frames true" mid-roll).
- [ ] Parry on the crimson glint: gold ring, enemy kneels, gold diamond. Light attack → riposte, gold critical number.
- [ ] Mistimed parry: you get hit; the whiff recovery is noticeable.
- [ ] Two heavies break a Penitent's poise (it reels back).
- [ ] Hits produce sparks, hit-stop and shake; toggles in Pause disable shake / flashes / hit-stop.

## Enemies
- [ ] Penitent patrols, pauses and turns; notices you in front at range and behind only up close.
- [ ] It never walks off the raised ledge or into the pit while patrolling or chasing.
- [ ] It mixes overhead (close) and lunging thrust (mid range); sometimes follows overhead with a low sweep.
- [ ] Run far away: it gives up and walks home.
- [ ] Killing it: fade-out, ember burst; it stays dead until you rest or die.

## Healing, checkpoint, death
- [ ] R heals ~45 after a short delay; one vial icon empties; movement slows during the drink.
- [ ] Getting hit mid-drink cancels it without consuming the vial.
- [ ] With 0 vials, R does nothing.
- [ ] E at the candle: "OATH KINDLED" first time, "OATH RENEWED" after; health/vials full; enemies revived.
- [ ] Spikes: one hit (20), thrown upward, can climb out.
- [ ] Death: "THE OATH BREAKS", fade, respawn beside the last candle (or the start if none), full health/vials, enemies revived, brief invulnerability.

## Build
- [ ] Windows .exe launches from a folder with no Godot installed.
- [ ] Holds ~60 FPS (F3) with all enemies active.
- [ ] Gamepad works without configuration.
- [ ] Alt-tab / window resize keeps crisp pixels.
