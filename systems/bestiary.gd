class_name Bestiary
extends RefCounted
## What the player has met. State is in world flags (no save-format change):
##   bs_<id> = true once met       bk_<id> = how many were killed
## Entries grow with kills: name when met, lore after the first kill, weaknesses after three.

const IDS: Array[StringName] = [
	&"carrion_crow", &"gloam_moth", &"roadside_pikeman", &"hollow_penitent", &"ember_acolyte",
	&"oathguard", &"mimic", &"hollow_archer", &"candle_cantor", &"gilded_penitent",
	&"pike_sergeant", &"oathguard_captain", &"bell_bearer", &"drowned_canon",
	&"cellarer_grume", &"sexton_hale", &"mother_cinder", &"ser_ashfall", &"drowned_pilgrim", &"reliquary_lurker", &"salt_abbot", &"gaoler_vess", &"foundrymaster_brand", &"hollow_regent", &"last_ringer", &"crownless_king", &"drowned_bishop", &"orrerist", &"thornmother", &"bell_warden", &"hollow_marshal",
]
const LORE_AT := 1
const WEAK_AT := 3


static func data(id: StringName) -> EnemyData:
	var path := "res://data/enemies/%s.tres" % id
	return load(path) as EnemyData if ResourceLoader.exists(path) else null


static func seen(id: StringName) -> bool:
	return bool(GameState.get_flag(StringName("bs_" + String(id)), false))


static func kills(id: StringName) -> int:
	return int(GameState.get_flag(StringName("bk_" + String(id)), 0))


static func record_seen(d: EnemyData) -> void:
	if d == null or d.id == &"" or seen(d.id):
		return
	GameState.set_flag(StringName("bs_" + String(d.id)), true)
	Events.bestiary_changed.emit(d.id)


static func record_kill(d: EnemyData) -> void:
	if d == null or d.id == &"":
		return
	GameState.set_flag(StringName("bs_" + String(d.id)), true)
	GameState.set_flag(StringName("bk_" + String(d.id)), kills(d.id) + 1)
	Events.bestiary_changed.emit(d.id)


static func total_seen() -> int:
	var n := 0
	for id in IDS:
		if seen(id):
			n += 1
	return n


static func total_kills() -> int:
	var n := 0
	for id in IDS:
		n += kills(id)
	return n


## The entry text for one creature, hiding what has not been earned yet.
static func entry_text(id: StringName) -> String:
	var d := data(id)
	if d == null:
		return "???"
	if not seen(id):
		return "???"
	var k := kills(id)
	var t := "%s%s    slain: %d\n" % [d.display_name, "  (elite)" if d.elite else "", k]
	if k >= LORE_AT:
		t += "   " + d.lore + "\n"
	else:
		t += "   Defeat one to learn more.\n"
	if k >= WEAK_AT:
		var bits := PackedStringArray()
		for kind in StatusFx.KINDS:
			var r := float(d.status_resist.get(String(kind), 0.0))
			if r <= -0.2:
				bits.append("weak to %s" % StatusFx.name_of(kind))
			elif r >= 0.5:
				bits.append("resists %s" % StatusFx.name_of(kind))
		t += "   %s. Pays %d embers.\n" % [", ".join(bits) if not bits.is_empty() else "No notable weakness", d.ember_reward]
	else:
		t += "   (%d more kills reveal its weaknesses)\n" % (WEAK_AT - k)
	return t


static func text() -> String:
	var out := PackedStringArray(["BESTIARY    met %d / %d" % [total_seen(), IDS.size()]])
	var unknown := 0
	for id in IDS:
		if not seen(id):
			unknown += 1
			continue
		if unknown > 0:
			out.append("??? x%d" % unknown)
			unknown = 0
		out.append(entry_text(id))
	if unknown > 0:
		out.append("??? x%d" % unknown)
	return "\n".join(out)
