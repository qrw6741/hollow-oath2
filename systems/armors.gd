class_name Armors
extends RefCounted
## Registry and rules for armour. The four starting armours share their id with the preset
## that begins with them (so old saves and the icon ids keep working). NAKED is not an item:
## it is what you wear when you take everything off.

const IDS: Array[StringName] = [&"sworn_knight", &"duelist", &"bulwark", &"unsworn",
	&"pilgrim_coat", &"penitent_shroud", &"canons_mail", &"marshal_plate"]
const DIR := "res://data/armors/"
const NONE: StringName = &"none"
## Wearing nothing: quick and fragile.
const NAKED_DAMAGE := 1.35
const NAKED_SPEED := 1.12
## Each upgrade level reduces damage taken by this fraction of the base multiplier.
const LEVEL_REDUCTION := 0.03

static var _cache := {}


static func get_armor(id: StringName) -> ArmorData:
	if not IDS.has(id):
		return null
	if not _cache.has(id):
		_cache[id] = load(DIR + String(id) + ".tres") as ArmorData
	return _cache[id]


## Status resistances worn: the armour's own plus 2% per upgrade level on each it resists.
static func resist_of(id: StringName, level := 0) -> Dictionary:
	var a := get_armor(id)
	var out := {}
	if a == null:
		return out
	for k in a.resist:
		var v := float(a.resist[k])
		out[String(k)] = minf(v + level * 0.02, 0.9) if v > 0.0 else v
	return out


static func is_valid_id(id: String) -> bool:
	return IDS.has(StringName(id))


## Damage multiplier of an armour at an upgrade level (id NONE = naked).
static func damage_mult(id: StringName, level: int) -> float:
	var a := get_armor(id)
	if a == null:
		return NAKED_DAMAGE
	return a.damage_taken_mult * (1.0 - LEVEL_REDUCTION * clampi(level, 0, Forge.MAX_LEVEL))


static func speed_mult(id: StringName) -> float:
	var a := get_armor(id)
	return NAKED_SPEED if a == null else a.run_speed_mult


static func dodge_add(id: StringName) -> float:
	var a := get_armor(id)
	return 0.0 if a == null else a.dodge_stamina_add
