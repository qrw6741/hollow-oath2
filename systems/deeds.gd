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
	&"errands": {"title": "Good Neighbour", "desc": "Finish every errand."},
	&"bestiary_half": {"title": "Student of the Dead", "desc": "Meet half the creatures in the Bestiary."},
	&"bestiary_full": {"title": "Naturalist", "desc": "Meet every creature in the Bestiary."},
	&"level_10": {"title": "Kindled", "desc": "Reach level 10."},
	&"all_status": {"title": "Every Affliction", "desc": "Trigger bleed, poison, burning and frost on foes."},
	&"gallery": {"title": "Open Gallery", "desc": "Open the Gallery with its key."},
	&"survive_night": {"title": "Night Walker", "desc": "Reach dawn after a night on the road."},
}
const ORDER: Array[StringName] = [
	&"first_blood", &"hundred_dead", &"warden_down", &"marshal_down", &"cellarer_down", &"sexton_down",
	&"errands", &"bestiary_half", &"bestiary_full", &"level_10", &"all_status", &"gallery", &"survive_night",
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
