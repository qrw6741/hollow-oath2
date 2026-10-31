class_name Progress
extends RefCounted
## One simple answer to "where do I go next?": the story's main bosses in order. The first one not
## yet defeated is the goal. Side areas and optional bosses are never required. World flags only.

const GOALS := [
	{"boss": &"bell_warden", "name": "the Bell-Warden", "area": "The Penitent's Yard"},
	{"boss": &"drowned_canon", "name": "the Drowned Canon", "area": "The Drowned Catacombs"},
	{"boss": &"hollow_marshal", "name": "the Hollow Marshal", "area": "The Vaelmoor Road"},
	{"boss": &"salt_abbot", "name": "the Salt Abbot", "area": "The Sunken Reliquary (down the stair in the Ashen Chapel)"},
	{"boss": &"hollow_regent", "name": "the Hollow Regent", "area": "The Hollow Keep (through the Reliquary's far door)"},
	{"boss": &"last_ringer", "name": "the Last Ringer", "area": "The Drowned Belfry (on from the Keep)"},
	{"boss": &"thornmother", "name": "the Thornmother", "area": "The Bleeding Gardens"},
	{"boss": &"orrerist", "name": "the Orrerist", "area": "The Iron Orrery"},
	{"boss": &"drowned_bishop", "name": "the Drowned Bishop", "area": "The Sunken Basilica"},
	{"boss": &"crownless_king", "name": "the Crownless King", "area": "The Crownless Citadel"},
	{"boss": &"ossuary_king_veyl", "name": "Veyl", "area": "The Weeping Ossuary (the Descent: walk right out of the Crownless Citadel)"},
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
	{"boss": &"verse_mother_ilse", "name": "Verse-Mother Ilse", "area": "The Cinder Choir (through the Hollow Heart's Last Door)"},
	{"boss": &"the_lantern_mother", "name": "the Lantern-Mother", "area": "The Lantern Marsh"},
	{"boss": &"the_unnamed_archon", "name": "the Unnamed Archon", "area": "The Undercrypt of Names"},
	{"boss": &"the_unkept_promise", "name": "the Unkept Promise", "area": "The Wakeless Court"},
]


## The next main boss on the road, as {"name", "area", "index"}; empty once the Descent is done.
## Anything before the furthest boss you have already beaten counts as done (you may have skipped
## it, or your save may be older than its flag), so the line never sends you backwards.
static func next_goal() -> Dictionary:
	var last := -1
	for i in GOALS.size():
		if bool(GameState.get_flag(StringName("boss_defeated_" + String(GOALS[i].boss)), false)):
			last = i
	if last + 1 >= GOALS.size():
		return {}
	var g: Dictionary = GOALS[last + 1]
	return {"name": g.name, "area": g.area, "index": last + 1}


static func text() -> String:
	var g := next_goal()
	if g.is_empty():
		return "Every road is walked. The Oath is laid down."
	return "Onward: defeat %s in %s." % [g.name, g.area]
