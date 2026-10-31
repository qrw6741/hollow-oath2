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
	&"relic_clapper": {"title": "Bell Clapper", "desc": "Foes pay 35% more embers.", "effect": "ember_gain", "value": 1.35},
	&"relic_briar": {"title": "Briar Locket", "desc": "Focus builds 40% faster.", "effect": "focus_gain", "value": 1.4},
	&"relic_gear": {"title": "Orrery Gear", "desc": "Your weapon's status builds 50% faster.", "effect": "weapon_status", "value": 1.5},
	&"relic_chalice": {"title": "Drowned Chalice", "desc": "Ember Vials heal 60% more.", "effect": "flask_heal", "value": 1.6},
	&"relic_oathbreaker": {"title": "Oathbreaker's Ring", "desc": "A parry gives 30 extra focus.", "effect": "parry_focus", "value": 30.0},
	&"relic_regent": {"title": "Hollow Crown", "desc": "A parry gives 20 extra focus.", "effect": "parry_focus", "value": 20.0},
	&"relic_x_ossuary_king_veyl": {"title": "Veyl's Knucklebone", "desc": "Focus builds 50% faster.", "effect": "focus_gain", "value": 1.5},
	&"relic_x_chandler_ulme": {"title": "Ulme's Drip-Candle", "desc": "Your weapon's status builds 70% faster.", "effect": "weapon_status", "value": 1.7},
	&"relic_x_chancellor_vorne": {"title": "Vorne's Seal", "desc": "Resist 45% of every status buildup.", "effect": "status_resist", "value": 0.45},
	&"relic_x_mother_sylve": {"title": "Sylve's Heartwood", "desc": "Foes pay 70% more embers.", "effect": "ember_gain", "value": 1.7},
	&"relic_x_auctioneer_mordant": {"title": "Mordant's Ledger", "desc": "Ember Vials heal 70% more.", "effect": "flask_heal", "value": 1.7},
	&"relic_x_admiral_sorrel": {"title": "Sorrel's Compass", "desc": "A parry gives 40 extra focus.", "effect": "parry_focus", "value": 40.0},
	&"relic_x_glasswright_orm": {"title": "Orm's Eyepiece", "desc": "Focus builds 80% faster.", "effect": "focus_gain", "value": 1.8},
	&"relic_x_vowsmith_anaxe": {"title": "Anaxe's Hammer-Charm", "desc": "Your weapon's status builds 60% faster.", "effect": "weapon_status", "value": 1.6},
	&"relic_x_prioress_silence": {"title": "Silence's Veil-Pin", "desc": "Resist 40% of every status buildup.", "effect": "status_resist", "value": 0.4},
	&"relic_x_pale_sovereign": {"title": "The Sovereign's Pale Crown", "desc": "Foes pay 60% more embers.", "effect": "ember_gain", "value": 1.6},
	&"relic_x_the_oath_eternal": {"title": "Wend's Oath-Knot", "desc": "Ember Vials heal 100% more.", "effect": "flask_heal", "value": 2.0},
	&"relic_x_verse_mother_ilse": {"title": "Ilse's Tuning-Fork", "desc": "A parry gives 35 extra focus.", "effect": "parry_focus", "value": 35.0},
	&"relic_x_the_lantern_mother": {"title": "The Lantern-Mother's Wick", "desc": "Focus builds 70% faster.", "effect": "focus_gain", "value": 1.7},
	&"relic_x_the_unnamed_archon": {"title": "The Archon's Borrowed Name", "desc": "Your weapon's status builds 90% faster.", "effect": "weapon_status", "value": 1.9},
	&"relic_x_the_unkept_promise": {"title": "The Unkept Seal", "desc": "Resist 35% of every status buildup.", "effect": "status_resist", "value": 0.35},
}
const IDS: Array[StringName] = [&"relic_locket", &"relic_thorn", &"relic_knot", &"relic_coin", &"relic_candle", &"relic_riposte", &"relic_shackle", &"relic_slag", &"relic_regent", &"relic_clapper", &"relic_briar", &"relic_gear", &"relic_chalice", &"relic_oathbreaker", &"relic_x_ossuary_king_veyl", &"relic_x_chandler_ulme", &"relic_x_chancellor_vorne", &"relic_x_mother_sylve", &"relic_x_auctioneer_mordant", &"relic_x_admiral_sorrel", &"relic_x_glasswright_orm", &"relic_x_vowsmith_anaxe", &"relic_x_prioress_silence", &"relic_x_pale_sovereign", &"relic_x_the_oath_eternal", &"relic_x_verse_mother_ilse", &"relic_x_the_lantern_mother", &"relic_x_the_unnamed_archon", &"relic_x_the_unkept_promise"]


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
