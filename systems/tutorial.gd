class_name Tutorial
extends RefCounted
## One-time tips. Each shows once per save (flag "tip_<id>") and can be switched off in
## Settings. Text may use {skill}, {travel}, {parry} which the HUD swaps for the bound keys.

const TIPS := {
	&"focus": {"title": "Focus", "text": "Hits, crits and parries fill your focus bar. Press {skill} to spend it on your weapon's skill."},
	&"status": {"title": "Status effects", "text": "Bleed, poison, burning and frost build up on a target and trigger at 100. Armour can resist them."},
	&"travel": {"title": "The Manor", "text": "Press {travel} to travel from anywhere, as long as no enemy is near and you are not in a boss fight."},
	&"night": {"title": "Night falls", "text": "Different, nastier things walk the road after dark. Rest at a candle if the night gets too long."},
	&"quest": {"title": "Errands", "text": "Open your pack and read the Journal tab to see what each errand needs."},
	&"parry": {"title": "Weapon parry", "text": "Parry windows depend on your weapon. A shield blocks if you keep {parry} held after the window."},
}


static func ids() -> Array:
	return TIPS.keys()


## Returns true (and records it) if this tip should be shown now.
static func take(id: StringName) -> bool:
	if not TIPS.has(id) or not Settings.tutorial_hints:
		return false
	var flag := StringName("tip_" + String(id))
	if GameState.get_flag(flag, false):
		return false
	GameState.set_flag(flag, true)
	return true
