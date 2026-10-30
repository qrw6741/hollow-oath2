class_name Weapons
extends RefCounted
## Registry and rules for weapons. Order of IDS = order in the equip list.

const IDS: Array[StringName] = [&"oathblade", &"twin_blades", &"sword_and_shield", &"fists",
	&"wayfarers_rapier", &"kingsfall_greatsword", &"toll_hammer", &"marshals_lance", &"tide_sabre", &"cinderbrand", &"ashfall_pike"]
const DIR := "res://data/weapons/"
## Each upgrade level adds this fraction of the weapon's base damage.
const LEVEL_BONUS := 0.10

static var _cache := {}


static func get_weapon(id: StringName) -> WeaponData:
	if not IDS.has(id):
		return null
	if not _cache.has(id):
		_cache[id] = load(DIR + String(id) + ".tres") as WeaponData
	return _cache[id]


static func is_valid_id(id: String) -> bool:
	return IDS.has(StringName(id))


## Damage multiplier of a weapon at an upgrade level.
static func level_mult(level: int) -> float:
	return 1.0 + LEVEL_BONUS * clampi(level, 0, Forge.MAX_LEVEL)
