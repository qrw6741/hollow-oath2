class_name Deeds
extends RefCounted
## Achievements ("deeds"). Each is a small data entry with a check; state is a world flag
## `deed_<id>` so saves need no new field. Deeds.check_all() is cheap and is called when
## something relevant happens (kill, boss, errand, level, status, item).

const DEFS := {
	&"first_blood": {"title": "First Blood", "desc": "Slay your first creature."},
	&"hundred_dead": {"title": "A Hundred Dead", "desc": "Slay 100 creatures."},
	&"warden_down": {"title": "Bell Silenced", "desc": "Defeat the Bell-Warden."},
	&"marshal_down": {"title": "The Oath Broken", "desc": "Defeat the Hollow Marshal."},
	&"cellarer_down": {"title": "Below the House", "desc": "Defeat the Cellarer."},
	&"sexton_down": {"title": "Grave Business", "desc": "Defeat the Sexton."},
	&"cinder_down": {"title": "The Censer Goes Dark", "desc": "Defeat Mother Cinder."},
	&"ashfall_down": {"title": "Rest at Last", "desc": "Defeat the optional Ser Ashfall."},
	&"abbot_down": {"title": "The Book Closed", "desc": "Defeat the Salt Abbot."},
	&"gaoler_down": {"title": "Unchained", "desc": "Defeat Gaoler Vess."},
	&"brand_down": {"title": "Furnace Out", "desc": "Defeat Foundrymaster Brand."},
	&"regent_down": {"title": "Long Live Nobody", "desc": "Defeat the Hollow Regent."},
	&"ringer_down": {"title": "Silence in the Tower", "desc": "Defeat the Last Ringer."},
	&"gardens_down": {"title": "Thorns Cut", "desc": "Defeat Elsbet, the Thornmother."},
	&"orrery_down": {"title": "Time Called", "desc": "Defeat Calloway, the Orrerist."},
	&"basilica_down": {"title": "Amen", "desc": "Defeat Bishop Anselm."},
	&"king_down": {"title": "Long Live No One", "desc": "Defeat the Crownless King."},
	&"x_ossuary_king_veyl": {"title": "Veyl Falls", "desc": "Defeat Veyl, King of the Ossuary."},
	&"x_chandler_ulme": {"title": "Ulme Falls", "desc": "Defeat Chandler Ulme, Lord of Wax."},
	&"x_chancellor_vorne": {"title": "Vorne Falls", "desc": "Defeat Chancellor Vorne."},
	&"x_mother_sylve": {"title": "Sylve Falls", "desc": "Defeat Mother Sylve, the Last Tree."},
	&"x_auctioneer_mordant": {"title": "Mordant Falls", "desc": "Defeat The Auctioneer Mordant."},
	&"x_admiral_sorrel": {"title": "Sorrel Falls", "desc": "Defeat Admiral Sorrel of the Drowned Fleet."},
	&"x_glasswright_orm": {"title": "Orm Falls", "desc": "Defeat Glasswright Orm."},
	&"x_vowsmith_anaxe": {"title": "Anaxe Falls", "desc": "Defeat The Vowsmith Anaxe."},
	&"x_prioress_silence": {"title": "Silence Falls", "desc": "Defeat Prioress Silence."},
	&"x_pale_sovereign": {"title": "Sovereign Falls", "desc": "Defeat The Pale Sovereign."},
	&"x_the_oath_eternal": {"title": "Oath Falls", "desc": "Defeat The Oath Eternal."},
	&"giants_25": {"title": "Giant Killer", "desc": "Defeat 25 different bosses."},
	&"secrets": {"title": "Seeker", "desc": "Find 4 hidden places."},
	&"all_arts": {"title": "Every Art", "desc": "Learn every art."},
	&"elite_ten": {"title": "Giant Slayer", "desc": "Slay 10 elite foes."},
	&"errands": {"title": "Good Neighbour", "desc": "Finish every errand."},
	&"bestiary_half": {"title": "Student of the Dead", "desc": "Meet half the creatures in the Bestiary."},
	&"bestiary_full": {"title": "Naturalist", "desc": "Meet every creature in the Bestiary."},
	&"level_10": {"title": "Kindled", "desc": "Reach level 10."},
	&"all_status": {"title": "Every Affliction", "desc": "Trigger bleed, poison, burning and frost on foes."},
	&"gallery": {"title": "Open Gallery", "desc": "Open the Gallery with its key."},
	&"ending": {"title": "The Oath Decided", "desc": "Reach an ending at the Oath Gate."},
	&"survive_night": {"title": "Night Walker", "desc": "Reach dawn after a night on the road."},
}
const ORDER: Array[StringName] = [
	&"first_blood", &"hundred_dead", &"warden_down", &"marshal_down", &"cellarer_down", &"sexton_down", &"cinder_down", &"ashfall_down", &"abbot_down", &"gaoler_down", &"brand_down", &"regent_down", &"ringer_down", &"gardens_down", &"orrery_down", &"basilica_down", &"king_down", &"x_ossuary_king_veyl", &"x_chandler_ulme", &"x_chancellor_vorne", &"x_mother_sylve", &"x_auctioneer_mordant", &"x_admiral_sorrel", &"x_glasswright_orm", &"x_vowsmith_anaxe", &"x_prioress_silence", &"x_pale_sovereign", &"x_the_oath_eternal", &"giants_25", &"secrets", &"all_arts", &"elite_ten",
	&"errands", &"bestiary_half", &"bestiary_full", &"level_10", &"all_status", &"gallery", &"survive_night", &"ending",
]


static func has(id: StringName) -> bool:
	return bool(GameState.get_flag(StringName("deed_" + String(id)), false))


static func count() -> int:
	var n := 0
	for id in ORDER:
		if has(id):
			n += 1
	return n


static func _boss(id: String) -> bool:
	return bool(GameState.get_flag(StringName("boss_defeated_" + id), false))


static func _met(id: StringName) -> bool:
	match id:
		&"first_blood": return Bestiary.total_kills() >= 1
		&"hundred_dead": return Bestiary.total_kills() >= 100
		&"warden_down": return _boss("bell_warden")
		&"marshal_down": return _boss("hollow_marshal")
		&"cellarer_down": return _boss("cellarer")
		&"sexton_down": return _boss("gravewarden")
		&"cinder_down": return _boss("mother_cinder")
		&"ashfall_down": return _boss("ser_ashfall")
		&"abbot_down": return _boss("salt_abbot")
		&"gaoler_down": return _boss("gaoler_vess")
		&"brand_down": return _boss("foundrymaster_brand")
		&"regent_down": return _boss("hollow_regent")
		&"ringer_down": return _boss("last_ringer")
		&"gardens_down": return _boss("thornmother")
		&"orrery_down": return _boss("orrerist")
		&"basilica_down": return _boss("drowned_bishop")
		&"king_down": return _boss("crownless_king")
		&"x_ossuary_king_veyl": return _boss("ossuary_king_veyl")
		&"x_chandler_ulme": return _boss("chandler_ulme")
		&"x_chancellor_vorne": return _boss("chancellor_vorne")
		&"x_mother_sylve": return _boss("mother_sylve")
		&"x_auctioneer_mordant": return _boss("auctioneer_mordant")
		&"x_admiral_sorrel": return _boss("admiral_sorrel")
		&"x_glasswright_orm": return _boss("glasswright_orm")
		&"x_vowsmith_anaxe": return _boss("vowsmith_anaxe")
		&"x_prioress_silence": return _boss("prioress_silence")
		&"x_pale_sovereign": return _boss("pale_sovereign")
		&"x_the_oath_eternal": return _boss("the_oath_eternal")
		&"giants_25": return Expansion.bosses_defeated() >= 25
		&"secrets": return Secrets.count() >= Secrets.NEEDED_FOR_DEED
		&"all_arts": return Arts.learned_count() >= Arts.ORDER.size()
		&"elite_ten": return Bestiary.kills(&"gilded_penitent") + Bestiary.kills(&"oathguard_captain") + Bestiary.kills(&"pike_sergeant") >= 10
		&"errands":
			for q in Quests.ORDER:
				if Quests.state(q) != "done":
					return false
			return true
		&"bestiary_half": return Bestiary.total_seen() * 2 >= Bestiary.IDS.size()
		&"bestiary_full": return Bestiary.total_seen() >= Bestiary.IDS.size()
		&"level_10": return GameState.level() >= 10
		&"all_status":
			for k in StatusFx.KINDS:
				if not bool(GameState.get_flag(StringName("fx_" + String(k)), false)):
					return false
			return true
		&"gallery": return bool(GameState.get_flag(&"door_open_hollowmere_gallery", false)) or bool(GameState.get_flag(&"gallery_opened", false))
		&"ending": return Endings.chosen() != &""
		&"survive_night": return bool(GameState.get_flag(&"night_survived", false))
	return false


## Unlocks anything newly earned; returns the ids unlocked by this call.
static func check_all() -> Array:
	var got := []
	for id in ORDER:
		if not has(id) and _met(id):
			GameState.set_flag(StringName("deed_" + String(id)), true)
			Events.deed_unlocked.emit(id)
			got.append(id)
	return got


static func text() -> String:
	var out := PackedStringArray(["DEEDS    %d / %d" % [count(), ORDER.size()]])
	for id in ORDER:
		var d: Dictionary = DEFS[id]
		out.append("%s  %s\n   %s" % ["[x]" if has(id) else "[ ]", d.title, d.desc])
	return "\n".join(out)
