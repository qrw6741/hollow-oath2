class_name Arts
extends RefCounted
## Arts: focus-powered abilities that belong to you, not your weapon. Each is learned from a
## boss and one is equipped at a time; it fires on the Art button (U / left trigger).
## State is world flags (no save-format change): `art_has_<id>` learned, `art_equipped` = id.
## An art's move is an AttackData (data/attacks/art_<id>.tres, made by tools/gen_arts.py).

const DEFS := {
	&"toll_of_mercy": {"title": "Toll of Mercy", "cost": 30.0, "boss": &"bell_warden", "kind": "attack",
		"desc": "A ringing blow that shoves back and staggers everything close. Learned from the Bell-Warden."},
	&"veil_step": {"title": "Veil Step", "cost": 25.0, "boss": &"hollow_marshal", "kind": "attack",
		"desc": "A fast, untouchable lunge: strike through danger. Learned from the Hollow Marshal."},
	&"gravebind": {"title": "Gravebind", "cost": 35.0, "boss": &"gravewarden", "kind": "attack",
		"desc": "Cold from the grave: a short, wide sweep that builds frost. Learned from the Sexton."},
	&"ember_lance": {"title": "Ember Lance", "cost": 35.0, "boss": &"mother_cinder", "kind": "attack",
		"desc": "A bolt of the censer's fire that burns what it touches. Learned from Mother Cinder."},
	&"mending_glow": {"title": "Mending Glow", "cost": 45.0, "boss": &"drowned_canon", "kind": "heal", "heal": 0.3,
		"desc": "The light that carried you out of the catacombs: restores 30% of your health. Learned from the Drowned Canon."},
	&"fire_meteor": {"title": "Fire Meteor", "cost": 55.0, "boss": &"ember_elder", "kind": "meteor",
		"desc": "Breathe a blazing meteor that arcs ahead of you and bursts in a wide fire. Learned from the Burning Elder."},
	&"tidecall": {"title": "Tidecall", "cost": 40.0, "boss": &"salt_abbot", "kind": "attack",
		"desc": "Calls a low wave along the floor that frosts and floods. Learned from the Salt Abbot."},
}
const ORDER: Array[StringName] = [&"toll_of_mercy", &"veil_step", &"gravebind", &"ember_lance", &"mending_glow", &"tidecall", &"fire_meteor"]


static func def(id: StringName) -> Dictionary:
	return DEFS.get(id, {})


static func title(id: StringName) -> String:
	return String(def(id).get("title", ""))


static func cost(id: StringName) -> float:
	return float(def(id).get("cost", 30.0))


static func attack(id: StringName) -> AttackData:
	return load("res://data/attacks/art_%s.tres" % id) as AttackData


## Learned = flagged, or its boss has fallen (which flags it for good, so New Game+ keeps it).
static func unlocked(id: StringName) -> bool:
	var f := StringName("art_has_" + String(id))
	if bool(GameState.get_flag(f, false)):
		return true
	var d := def(id)
	if not d.is_empty() and bool(GameState.get_flag(StringName("boss_defeated_" + String(d.boss)), false)):
		GameState.set_flag(f, true)
		return true
	return false


static func learned_count() -> int:
	var n := 0
	for id in ORDER:
		if unlocked(id):
			n += 1
	return n


static func equipped() -> StringName:
	var id := StringName(String(GameState.get_flag(&"art_equipped", "")))
	return id if id != &"" and DEFS.has(id) and unlocked(id) else &""


static func equip(id: StringName) -> bool:
	if id != &"" and not (DEFS.has(id) and unlocked(id)):
		return false
	GameState.set_flag(&"art_equipped", String(id))
	Events.art_changed.emit(id)
	return true


## When the first art is learned, equip it so the new button does something at once.
static func auto_equip() -> void:
	if equipped() == &"":
		for id in ORDER:
			if unlocked(id):
				equip(id)
				return
