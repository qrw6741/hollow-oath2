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
| Inventory (pack) | Tab | Create / Select |
| Use quick item | F | R3 (press right stick) |
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
| Pause | Options | Menu |
| Pack | Create (Share) | View |
| Quick item | R3 | RS click |
| Menus: select / back | Cross / Circle | A / B |

Settings has *Controller icons* (Auto / PlayStation / Xbox, in case Auto guesses wrong) and *Controller vibration* (short rumble on hits and parries).

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
Bindings are defined in `autoload/input_config.gd` and can be rebound at runtime via `InputConfig.rebind()` (saved to `user://input.cfg`). A remapping menu is planned for Milestone 10.
