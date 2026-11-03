class_name Weapons
extends RefCounted
## Registry and rules for weapons. Order of IDS = order in the equip list.

const IDS: Array[StringName] = [&"oathblade", &"twin_blades", &"sword_and_shield", &"fists",
	&"wayfarers_rapier", &"kingsfall_greatsword", &"toll_hammer", &"marshals_lance", &"tide_sabre", &"cinderbrand", &"ashfall_pike",
	&"gravediggers_greataxe", &"veil_daggers", &"candle_catalyst", &"abbots_crozier", &"bone_cleaver", &"chandlers_maul", &"archivists_needle", &"thornwood_sabre", &"glasswrights_shards", &"vowbreaker", &"choirmasters_baton", &"lantern_hook", &"namebreaker", &"unkept_blade", &"nightreaper", &"long_katana"]
const DIR := "res://data/weapons/"
## Where each weapon can be found, shown on the WEAPONS tab while you do not own it.
const HINTS := {
	&"wayfarers_rapier": "A chest in the Hollowmere Cellar, beneath the Manor. Hobb can also forge it.",
	&"kingsfall_greatsword": "A chest in the Pilgrim's Graveyard. Hobb can also forge it.",
	&"toll_hammer": "Hobb forges it if you show him the Warden's bell shard (Bell-Warden).",
	&"marshals_lance": "Hobb forges it if you show him the Marshal's Crest (Hollow Marshal).",
	&"tide_sabre": "Hobb forges it if you show him the Canon's Seal (Drowned Canon).",
	&"cinderbrand": "Hobb forges it from Mother Cinder's heart.",
	&"ashfall_pike": "Hobb forges it from Ser Ashfall's seal.",
	&"gravediggers_greataxe": "Hidden behind an illusory wall in the Sunken Reliquary: look for a wall that gives way.",
	&"veil_daggers": "Hobb forges them from a Lurker's Fang (Reliquary Lurkers).",
	&"candle_catalyst": "Hobb forges it from a Cantor's Wick (Candle Cantors in the Reliquary).",
	&"abbots_crozier": "Hobb forges it from the Abbot's Signet (the Salt Abbot).",
	&"bone_cleaver": "A hidden chest in the Weeping Ossuary, past its king. The Descent begins beneath the Crownless Citadel.",
	&"chandlers_maul": "A hidden chest in the Tallow Mines, past the Chandler.",
	&"archivists_needle": "A hidden chest in the Gilded Archive, past the Chancellor.",
	&"thornwood_sabre": "A hidden chest in the Sunless Orchard, past the Last Tree.",
	&"glasswrights_shards": "A hidden chest in the Shattered Gallery, past the Glasswright.",
	&"vowbreaker": "A hidden chest in the Hollow Heart, past the Oath Eternal.",
	&"choirmasters_baton": "A hidden chest in the Cinder Choir, past Verse-Mother Ilse.",
	&"lantern_hook": "A hidden chest in the Lantern Marsh, past the Lantern-Mother.",
	&"namebreaker": "A hidden chest in the Undercrypt of Names, past the Unnamed Archon.",
	&"nightreaper": "Dropped by the Twin Lords, Ashkar and Veshti, at the end of the Ninth Hell.",
	&"unkept_blade": "A hidden chest in the Wakeless Court, past the Unkept Promise.",
	&"long_katana": "In a chest in a crow's nest above the Belfry Climb, far past the Gate-Fox in the Lower Hell. Look up; you will have to climb for it.",
}
## Each upgrade level adds this fraction of the weapon's base damage.
const LEVEL_BONUS := 0.10          ## per level up to +5
const LEVEL_BONUS_LATE := 0.06     ## per level from +6 to +24

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
	var l := clampi(level, 0, Forge.MAX_WEAPON)
	return 1.0 + LEVEL_BONUS * mini(l, 5) + LEVEL_BONUS_LATE * maxi(l - 5, 0)
