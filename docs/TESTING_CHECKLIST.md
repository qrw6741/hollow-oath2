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

## Saving and menus
- [ ] Fresh install: main menu opens; Continue and Load Game are greyed out; New Game works.
- [ ] New Game → pick slot 1 → game starts; quit and relaunch → Continue is enabled and shows slot 1, place and play time.
- [ ] Rest at a candle: "Progress saved" appears bottom-right. Quit to menu, Continue: you spawn beside that candle with full health and vials.
- [ ] Die, wait for respawn, quit and Continue: the death count is kept.
- [ ] Walk away from a candle, quit to menu without resting: Continue returns you to the *candle*, not where you quit (expected).
- [ ] Slots screen: Overwrite and Delete both need a second press; waiting 3 s resets them. Esc / B goes back.
- [ ] Quit to Main Menu from the pause menu asks "Sure?"; the death screen never appears in the next session.
- [ ] Damaged save: close the game, open `slot_1.json` in a text editor, delete half of it, relaunch → it recovers from the backup, or says "damaged" and offers Delete — never crashes.
- [ ] Settings changes (shake / flashes / hit-stop / volume) survive a relaunch.
- [ ] Settings → Controls: rebind Jump on keyboard and on the controller, play, relaunch — bindings kept; HUD prompts show the new buttons; Reset restores.
- [ ] Settings → Game: Damage 50% / Enemy health 50% / Parry assist feel right; survive a relaunch.
- [ ] Candle → Travel to another lit candle in another area; die → respawn at the travelled-to candle.
- [ ] Keyboard-only and gamepad-only navigation of every menu works; the focused item is always visible.

## Presets
- [ ] New Game → slot → "Choose your oath" shows 4 presets; the preview figure and text change as you move; Esc goes back to slots.
- [ ] Each preset starts with its own HP / stamina / flasks and looks different in game.
- [ ] Each preset: light combo, heavy, aerial, dodge, parry + riposte all work and read clearly.
- [ ] The Unsworn: bare torso, fists only; takes noticeably more damage; Hollow Palm riposte hits very hard.
- [ ] Quit, then Continue: the same preset is restored.

## Embers and inventory
- [ ] Killing an enemy adds embers (counter top right ticks up, +N appears).
- [ ] Die with embers: counter goes to 0, a glowing stain appears where you fell; walk into it to get them back.
- [ ] Die twice without recovering: only the newest stain exists.
- [ ] Rest at the candle: menu opens; buy Vigor/Endurance/Strength; bars grow; Pack and Leave work; Esc / Circle leaves.
- [ ] Pick up the bandages / shard / key with E; they do not come back after resting or reloading the save.
- [ ] Tab opens the pack; Use a bandage when hurt; quick item shows bottom left; F uses it.
- [ ] Quit and Continue: embers, stain, level, pack and quick item are restored.

## Boss: the Bell-Warden
- [ ] Bell-Gate Candle just before the fog; the boss stands still until you pass the fog.
- [ ] Entering seals the gate (red fog), name banner and boss bar appear; you cannot walk back out.
- [ ] Smash shows a glint and can be parried, then riposted. Charge and leap glow red and cannot be parried; the leap shows where it lands.
- [ ] At half health it roars, pushes you back, and fights faster with the leap and the three-hit combo.
- [ ] Die: on respawn the boss is at full health and the gate is open.
- [ ] Win: banner, +1500 embers, Warden's Bell Shard, gate opens; boss never returns after resting or reloading.

## Forsaken Village
- [ ] Bell Door (back of the boss arena) is locked without the Bell Shard and opens with it; you arrive at the village edge.
- [ ] Walking off the left edge of the village returns you to the Bell Door.
- [ ] Rest at the Village Gate Candle; die in the village: you respawn there. Rest only in the Yard, die in the village: you respawn in the Yard.
- [ ] Rooftop climb is possible; the corridor gate cannot be raised from the outskirts, can be from inside, and stays open.
- [ ] Ember Acolytes keep distance and throw wax; parry it (glint), or dodge through it.
- [ ] Bell-Bearers ring before attacking; the slam can be parried, the red chain swing cannot.
- [ ] The chapel door says the build ends here.

## Drowned Catacombs, Drowned Canon, map
- [ ] Chapel door leads down to the catacombs; the left edge leads back.
- [ ] Wading is slower; the shaft is crossable on the broken pillar; falling in kills.
- [ ] The cracked wall under Canon's Rest breaks after three hits and stays broken.
- [ ] Canon: lash glint parry -> riposte; three-shot fan; bubbles mark where it surfaces; phase 2 floor wave can be jumped.
- [ ] Map (M / touchpad / L3, or pause menu): shows explored parts only, your position, candles (lit after resting), bosses (crossed after defeat); pan and zoom work; closing resumes the game.

## Prologue ending
- [ ] After the Drowned Canon dies, a pillar of light rises a few seconds later.
- [ ] Walking into it lifts you, the screen fades to white, and you wake in daylight (Vaelmoor, Awake).
- [ ] "PROLOGUE COMPLETE" appears; the Waking Stone can be read; the road gate says the next build continues.
- [ ] Quit and Continue: you load in the daylight area. Going back to the catacombs, the light is still there.

## Build
- [ ] Windows .exe launches from a folder with no Godot installed.
- [ ] Holds ~60 FPS (F3) with all enemies active.
- [ ] Gamepad works without configuration.
- [ ] Alt-tab / window resize keeps crisp pixels.

## After the prologue (new)
- [ ] East edge of Vaelmoor, Awake -> the road; west edge of the road -> back.
- [ ] Ommen at the First Light Candle: four visits give four different pages; the third gives his name. Standing at the candle vs next to him: Interact rests vs talks as expected.
- [ ] Wenna: intro once, greeting afterwards, shop opens; buy each item; try buying with too few embers and with a full stack; leave with Cancel.
- [ ] Walk the whole road: pikemen (thrust parryable, low sweep not - jump it), crows, the Oathguard in the ford, the Mimic on the bank (does the breath of ash read as a tell?), chests, both candles.
- [ ] Sir Orren: all five attacks readable? Is phase 2 fair? Do the banner crows feel like an opening or a nuisance? Crest + embers on victory; Ommen's new line afterwards.
- [ ] Fast travel to the Wayside / Camp candle from another area; die on the road -> respawn at the last road candle.

## Gear (new)
- [ ] Find Hobb and Ilse (Vaelmoor, Awake and Pilgrim's Rest). Talk, then the station opens; Cancel leaves.
- [ ] Buy Forge Scrap / Hollow Resin from Wenna; upgrade a weapon, an armour and the vials; check the numbers change on the Equipment tab and in play.
- [ ] Take armour off (Equipment tab): you should look bare, run faster and take much more damage. Put it back on.
- [ ] Forge each new weapon (carry the relic where one is required) and play with it: rapier, greatsword, hammer, lance, sabre. Do thrusts feel fair? Is the greatsword too slow, the lance too long?
- [ ] Save, quit, load: weapons, armour, levels, worn/naked state and vial level all return.

## Hollowmere Manor (new)
- [ ] Talk to Ommen four times (Awake / Wayside / Camp): he gives the Hollowmere Sigil on page four.
- [ ] Pack -> Hollowmere Sigil -> "Travel to Hollowmere". Arrive in the front hall. Use it again (or the door by the start): you return to the exact spot.
- [ ] Try it during a boss fight: it should refuse.
- [ ] Walk the manor: Ommen, Hobb, Ilse, Wenna, Aldous; climb to the balcony (chest + ledger); rest at the candle; fast travel to and from it.
- [ ] Save in the manor, quit, load: you are in the manor and the sigil still returns you to the field.

