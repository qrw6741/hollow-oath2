class_name WeaponStats
extends RefCounted
## Turns a WeaponData's attack chain into numbers a player can read on the equipment
## screen. Damage includes the Strength bonus passed in.


## Every hit of the light combo, in order (follows next_in_combo).
static func light_chain(w: WeaponData) -> Array[AttackData]:
	var out: Array[AttackData] = []
	var a := w.light_combo_start if w else null
	var guard := 0
	while a and guard < 8 and not out.has(a):
		out.append(a)
		a = a.next_in_combo
		guard += 1
	return out


static func dmg(a: AttackData, bonus: float, mult := 1.0) -> int:
	return roundi(a.damage * mult * bonus) if a else 0


## "Fast / Medium / Slow" from the wind-up of the first light attack.
static func speed_label(w: WeaponData) -> String:
	var chain := light_chain(w)
	if chain.is_empty():
		return "-"
	var su := chain[0].startup_frames
	if su <= 7:
		return "Fast"
	if su <= 10:
		return "Medium"
	return "Slow"


## "Short / Medium / Long" from how far the first light hit reaches in front of the body.
static func reach_label(w: WeaponData) -> String:
	var chain := light_chain(w)
	if chain.is_empty():
		return "-"
	var a := chain[0]
	var reach := a.hitbox_offset.x + a.hitbox_size.x / 2.0
	if reach < 28.0:
		return "Short"
	if reach < 40.0:
		return "Medium"
	return "Long"


## A full summary used by the equipment screen and tests.
static func summary(w: WeaponData, bonus: float) -> Dictionary:
	var chain := light_chain(w)
	var light: Array[int] = []
	var light_total := 0
	var stamina := 0.0
	var poise := 0.0
	for a in chain:
		var d := dmg(a, bonus)
		light.append(d)
		light_total += d
		stamina = maxf(stamina, a.stamina_cost)
		poise = maxf(poise, a.poise_damage)
	return {
		"name": w.display_name if w else "",
		"light": light,
		"light_total": light_total,
		"heavy": dmg(w.heavy, bonus) if w else 0,
		"heavy_stamina": w.heavy.stamina_cost if w and w.heavy else 0.0,
		"aerial": dmg(w.aerial, bonus) if w else 0,
		"riposte": dmg(w.riposte, bonus, w.riposte_multiplier) if w else 0,
		"stamina": stamina,
		"poise": poise,
		"speed": speed_label(w),
		"reach": reach_label(w),
	}
