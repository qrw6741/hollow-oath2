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
| Pause | Esc | Start |
| Debug overlay | F3 | — |

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
