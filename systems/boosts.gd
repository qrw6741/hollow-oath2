class_name Boosts
extends RefCounted
## One place that adds up the permanent talisman effects and the timed potion effects.
## Multiplicative effects default to 1.0, additive ones (status_resist, parry_focus) to 0.0.
## Relic effects are separate (Relics.mult) and are multiplied in by the callers.

const ADDITIVE := ["status_resist", "parry_focus"]


static func _sources() -> Array:
	var out := []
	for id in Talismans.equipped():
		out.append(Talismans.effects_of(id))
	for id in Buffs.active:
		if Buffs.DEFS.has(id):
			out.append(Buffs.DEFS[id].effects)
	return out


static func mult(effect: String) -> float:
	var v := 1.0
	for d in _sources():
		if d.has(effect):
			v *= float(d[effect])
	return v


static func add(effect: String) -> float:
	var v := 0.0
	for d in _sources():
		if d.has(effect):
			v += float(d[effect])
	return v
