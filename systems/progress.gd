class_name Progress
extends RefCounted
## One simple answer to "where do I go next?": the story's main bosses in order. The first one not
## yet defeated is the goal. Side areas and optional bosses are never required. World flags only.

const GOALS := [
	{"boss": &"bell_warden", "name": "the Bell-Warden", "area": "The Penitent's Yard"},
	{"boss": &"drowned_canon", "name": "the Drowned Canon", "area": "The Drowned Catacombs"},
	{"boss": &"hollow_marshal", "name": "the Hollow Marshal", "area": "The Vaelmoor Road"},
	{"boss": &"last_ringer", "name": "the Last Ringer", "area": "The Drowned Belfry"},
	{"boss": &"thornmother", "name": "the Thornmother", "area": "The Bleeding Gardens"},
	{"boss": &"orrerist", "name": "the Orrerist", "area": "The Iron Orrery"},
	{"boss": &"drowned_bishop", "name": "the Drowned Bishop", "area": "The Sunken Basilica"},
	{"boss": &"crownless_king", "name": "the Crownless King", "area": "The Crownless Citadel"},
	{"boss": &"ossuary_king_veyl", "name": "Veyl", "area": "The Weeping Ossuary"},
	{"boss": &"chandler_ulme", "name": "Ulme", "area": "The Tallow Mines"},
	{"boss": &"chancellor_vorne", "name": "Vorne", "area": "The Gilded Archive"},
	{"boss": &"mother_sylve", "name": "Sylve", "area": "The Sunless Orchard"},
	{"boss": &"auctioneer_mordant", "name": "Mordant", "area": "The Bone Market"},
	{"boss": &"admiral_sorrel", "name": "Sorrel", "area": "The Tidal Vaults"},
	{"boss": &"glasswright_orm", "name": "Orm", "area": "The Shattered Gallery"},
	{"boss": &"vowsmith_anaxe", "name": "Anaxe", "area": "The Forge of Vows"},
	{"boss": &"prioress_silence", "name": "Silence", "area": "The Hush Cloister"},
	{"boss": &"pale_sovereign", "name": "the Pale Sovereign", "area": "The Barrow of Kings"},
	{"boss": &"the_oath_eternal", "name": "the Oath Eternal", "area": "The Hollow Heart"},
]


## The first main boss still standing, as {"name", "area", "index"}; empty once the Descent is done.
static func next_goal() -> Dictionary:
	for i in GOALS.size():
		var g: Dictionary = GOALS[i]
		if not bool(GameState.get_flag(StringName("boss_defeated_" + String(g.boss)), false)):
			return {"name": g.name, "area": g.area, "index": i}
	return {}


static func text() -> String:
	var g := next_goal()
	if g.is_empty():
		return "Every road is walked. The Oath is laid down."
	return "Onward: defeat %s in %s." % [g.name, g.area]
