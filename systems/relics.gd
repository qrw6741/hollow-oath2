class_name Relics
extends RefCounted
## Passive trinkets. A relic is an ordinary key-kind item (so it can be found, dropped or
## given as a reward); wear up to SLOTS of them from the Relics tab. What is worn lives in the
## world flag `relics_eq` (an Array of ids; no save-format change). Effects are multipliers
## looked up by name with Relics.mult(effect), so adding a relic = a data entry + an item.
##
##  focus_gain     x focus gained from hits, crits and parries
##  weapon_status  x status buildup of your weapon's hits
##  status_resist  + resistance to every status (0.15 = 15%)
##  ember_gain     x embers from kills
##  flask_heal     x healing from Ember Vials
##  parry_focus    + extra focus on a successful parry

const SLOTS := 2
const DEFS := {
	&"relic_locket": {"title": "Hollow Locket", "desc": "Focus builds 25% faster.", "effect": "focus_gain", "value": 1.25},
	&"relic_thorn": {"title": "Widow's Thorn", "desc": "Your weapon's status builds 40% faster.", "effect": "weapon_status", "value": 1.4},
	&"relic_knot": {"title": "Penitent's Knot", "desc": "Resist 15% of every status buildup.", "effect": "status_resist", "value": 0.15},
	&"relic_coin": {"title": "Gravedigger's Coin", "desc": "Foes pay 20% more embers.", "effect": "ember_gain", "value": 1.2},
	&"relic_candle": {"title": "Candle Stub", "desc": "Ember Vials heal 20% more.", "effect": "flask_heal", "value": 1.2},
	&"relic_riposte": {"title": "Duellist's Glove", "desc": "A parry gives 10 extra focus.", "effect": "parry_focus", "value": 10.0},
	&"relic_shackle": {"title": "Gaoler's Shackle", "desc": "Resist 30% of every status buildup.", "effect": "status_resist", "value": 0.3},
	&"relic_slag": {"title": "Foundry Ladle", "desc": "Ember Vials heal 40% more.", "effect": "flask_heal", "value": 1.4},
	&"relic_regent": {"title": "Hollow Crown", "desc": "A parry gives 20 extra focus.", "effect": "parry_focus", "value": 20.0},
}
const IDS: Array[StringName] = [&"relic_locket", &"relic_thorn", &"relic_knot", &"relic_coin", &"relic_candle", &"relic_riposte", &"relic_shackle", &"relic_slag", &"relic_regent"]


static func owned(id: StringName) -> bool:
	return GameState.item_count(id) > 0


static func equipped() -> Array:
	var out := []
	var raw = GameState.get_flag(&"relics_eq", [])
	if raw is Array:
		for id in raw:
			if DEFS.has(StringName(id)) and owned(StringName(id)):
				out.append(StringName(id))
	return out


static func is_worn(id: StringName) -> bool:
	return equipped().has(id)


## Wears or removes a relic. Returns {"ok", "msg"}.
static func toggle(id: StringName) -> Dictionary:
	if not DEFS.has(id) or not owned(id):
		return {"ok": false, "msg": "You do not have that."}
	var cur := equipped()
	if cur.has(id):
		cur.erase(id)
		_save(cur)
		return {"ok": true, "msg": "Removed %s." % DEFS[id].title}
	if cur.size() >= SLOTS:
		return {"ok": false, "msg": "Both slots are full. Remove one first."}
	cur.append(id)
	_save(cur)
	Audio.sfx(&"relic_equip", -4.0)
	return {"ok": true, "msg": "Wearing %s." % DEFS[id].title}


static func _save(list: Array) -> void:
	GameState.set_flag(&"relics_eq", list.map(func(i): return String(i)))
	Events.loadout_changed.emit()


## The product (or, for additive effects, the sum) of every worn relic's value for an effect.
static func mult(effect: String) -> float:
	var additive := effect in ["status_resist", "parry_focus"]
	var v := 0.0 if additive else 1.0
	for id in equipped():
		var d: Dictionary = DEFS[id]
		if d.effect == effect:
			v = v + float(d.value) if additive else v * float(d.value)
	return v
