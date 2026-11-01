# Controls

| Action | Keyboard / Mouse | Gamepad (Xbox layout) |
|---|---|---|
| Move | A / D or ← / → | Left stick / D-pad |
| Jump (hold = higher) | Space | A |
| Light attack (3-hit combo; in air: falling cut) | J or Left mouse | X |
| Heavy attack | K or Right mouse | Y |
| Dodge roll (i-frames) | L or Shift | B |
| Parry | I or Q | LB |
| Heal (Ember Vial) | R | RB |
| Interact / Rest at candle | E | D-pad up |
| Weapon skill (costs focus) | O | Right trigger (RT) |
| Art (your equipped art, costs focus; a weapon with a jutsu casts that instead) | U | Left trigger (LT) |
| Equipped Art even while a jutsu weapon is in hand | H | Back paddle (if your pad has one) |
| Travel to / from Hollowmere | T | Xbox: View-share button (Misc) |
| Inventory (pack) | Tab | Create / Select |
| Use quick item | F | R3 (press right stick) |
| Map | M | Touchpad (PS) / L3 |
| Pause | Esc | Start |
| Debug overlay | F3 | — |

## PlayStation 5 / DualSense (and other controllers)
Plug in or pair the pad and press any button: on-screen prompts switch to controller icons automatically (and back to keys when you touch the keyboard or mouse).

| Action | DualSense | Xbox-style |
|---|---|---|
| Move | Left stick / D-pad | same |
| Jump | Cross | A |
| Light attack | Square | X |
| Heavy attack | Triangle | Y |
| Dodge roll | Circle | B |
| Parry | L1 | LB |
| Heal | R1 | RB |
| Interact / rest | D-pad up | D-pad up |
| Map | Touchpad | L3 |
| Pause | Options | Menu |
| Pack | Create (Share) | View |
| Quick item | R3 | RS click |
| Menus: select / back | Cross / Circle | A / B |

Settings has *Controller icons* (Auto / PlayStation / Xbox, in case Auto guesses wrong) and *Controller vibration* (short rumble on hits and parries).

## Combat depth
- **Focus** (blue bar under your vials): fills when you land hits (+6, +10 on a critical) and parry (+16); a rest at a candle refills it. Your weapon's **skill** (O / RT) spends focus: the rapier's Riposte Lunge, the hammer's Ground Slam, the greatsword's Kingsfall, and so on - see the Equipment tab for each weapon's skill and cost.
- **Status effects**: hits fill a meter; at 100 it triggers. *Bleed* bursts for a share of health. *Poison* and *burning* tick for several seconds. *Frost* slows. Weapons inflict them (rapier and sabre bleed, lance and hammer frost, greatsword burning); armour resists them; some enemies are immune or weak. Bosses are immune. Rings over your head and under your vials show buildup and what is active.
- **Weapon-specific parry**: the parry window differs by weapon (greatsword longer, rapier tighter - Equipment tab, "Parry window"). With **sword and shield**, hold Parry past the window to keep a guard up that blocks 75% of frontal damage for stamina.
- **Hollowmere travel (T)**: with the Hollowmere Sigil, T takes you to the manor from anywhere and brings you back to the exact spot. It refuses for 5 seconds after any blow dealt or taken, while a hunting enemy is within 360 px, and during any boss fight.
- **Errands and Journal**: the people of the road and manor now give small errands (Journal tab of the pack, switch tabs with LB / RB or Q / R). Time of day on the road turns from daylight to dusk to night over about 14 minutes of play; different enemies walk at night.

## Menus
Arrow keys / D-pad / stick move the selection, **Enter** or **A** selects, **Esc** or **B** goes back; the mouse works too. Overwriting or deleting a save, and quitting to the main menu from the pause menu, ask you to press the button a second time ("Sure?") within 3 seconds.

## Combat notes
- Your preset changes what the attack buttons do: sword combo, twin-blade flurry, shield bash chain, or the Unsworn's fist combo (light = jab/cross/hook/uppercut, heavy = haymaker). Timings differ per preset; the parry button raises the shield for the Bulwark.
- **Stamina** is spent by attacks, dodges and parries. You can act while any stamina remains; emptying the bar delays regeneration.
- **Combos**: press light attack again any time during a swing — the next hit comes out when the current swing allows it. Light → heavy also chains.
- **Dodge cancel**: the end of most attacks can be cancelled into a roll; the start cannot.
- **Parry**: an 8-frame (~0.13 s) window. Watch for the **crimson glint** on the enemy's blade — it appears just before the blow lands. A successful parry kneels the enemy (gold diamond above its head). Press light attack next to it for a **riposte**.
- **Healing**: 3 Ember Vials, refilled at an Oath Candle. The vial takes effect partway through the animation; getting hit first wastes the time but not the vial.
- **Resting** at an Oath Candle restores everything, sets your respawn point and revives enemies.

## Remapping
**Talking and shopping:** stand next to a character and press Interact (E / Dpad-up) to talk; Interact / Confirm / Light attack moves the conversation on, Cancel skips it. In a shop, Confirm buys one of the selected item; Cancel leaves.

**Equipment:** open the pack (Tab / Create), choose the Weapon or Armour slot and press Confirm to pick a different one. In the armour list, "Take off all armour" is the first entry. Blacksmith and Vial-Keeper: talk (Interact), then Confirm to upgrade the highlighted row; L1/R1 (Parry/Heal) switches the smith's tabs; Cancel leaves.

Rebind any action in **Settings → Controls**: pick the keyboard or controller cell and press the new key/button (Esc cancels). Using a binding another action had swaps them. *Reset controls to defaults* restores everything. Bindings are saved to `user://input.cfg`; defaults live in `autoload/input_config.gd`.


## Menus added later
- **Inventory (Tab)**: ten tabs, switch with Parry / Heal: Gear, Items, Weapons, Journal, Bestiary, Deeds, Relics, Arts, Talismans, Alchemy. In Relics, press a row to wear or remove (two slots). In Talismans, press a row to wear or remove (three slots); bosses always leave one and elite foes sometimes do. In Alchemy, press a recipe to brew a potion from carried materials; drink potions from the Items tab (or set one as the quick item) for a timed buff shown at the top left.
- **Shop**: BUY / SELL tabs, switch with Parry / Heal. Confirm trades one.
- **Forge**: WEAPONS / ARMOUR tabs (Parry / Heal); the Infusion button under the description cycles the weapon's status.
- **Oath Gate** (end of the Vaelmoor Road, after the Marshal): Interact to choose an ending. After an ending, Interact twice to begin New Game+.
- **Settings > Game**: Colourblind status colours, Tutorial tips.

- **Arts**: each boss teaches one. Equip one on the ARTS tab of the pack; the Art button (U / LT) casts it for its focus cost. Toll of Mercy (Bell-Warden), Veil Step (Marshal), Gravebind (Sexton), Ember Lance (Mother Cinder), Mending Glow (Drowned Canon), Tidecall (Salt Abbot).
- **Secrets**: some walls and floors are only paint. Walk into suspicious masonry; cracked walls can be struck.
- **The Trial Ring**: after you choose an ending, a door in Hollowmere Manor opens it. The left stone starts the Boss Rush, the right one the Gauntlet.

- **Jutsu (weapon technique)**: some special weapons carry their own technique. While one is equipped, the Art button (U / LT) casts it instead of your equipped Art. The Nightreaper's is **Amaterasu** (50 focus): black flames burst from the floor on both sides of you and burn whatever stands in them for about 4 seconds.

- **Lower Hell puzzles**: levers (Interact), rune stones (Interact, in the order a tablet gives; a wrong stone puts all out) and timed levers that spring back. Gates open when their puzzle is solved and stay open.
- **Fire Meteor** (learned from the Burning Elder): an Art; cast with the Art button, or **H** if your weapon has its own jutsu.
- **Dev tab**: One-hit kills, **Weapon damage** and **Jutsu damage** multipliers (x0.1 to x100).
