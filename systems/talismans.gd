class_name Talismans
extends RefCounted
## Talismans: unique charms dropped by bosses (always, once) and by strong (elite) enemies
## (a chance). Wear up to SLOTS of them from the TALISMANS tab for permanent buffs. They are
## ordinary key-kind items; what is worn lives in the world flag `tal_eq` (an Array of ids), so
## there is no save-format change. Effects are looked up by name through Boosts.

const SLOTS := 3
const ELITE_DROP_CHANCE := 0.12
const EFFECT_LABELS := {
	"damage": "Damage", "damage_taken": "Damage taken", "max_health": "Max health", "stamina_regen": "Stamina regen",
	"run_speed": "Run speed", "ember_gain": "Embers from kills", "flask_heal": "Vial healing", "focus_gain": "Focus gain",
	"weapon_status": "Weapon status", "status_resist": "Status resist", "parry_focus": "Focus per parry",
}


static func owned(id: StringName) -> bool:
	return GameState.item_count(id) > 0


static func title(id: StringName) -> String:
	return String(TalismanData.DEFS[id].title) if TalismanData.DEFS.has(id) else ""


static func effects_of(id: StringName) -> Dictionary:
	return TalismanData.DEFS[id].effects if TalismanData.DEFS.has(id) else {}


## "Damage +8%, Damage taken -5%" style text for a set of effects.
static func describe(effects: Dictionary) -> String:
	var parts := PackedStringArray()
	for k in effects:
		var v: float = float(effects[k])
		var label: String = EFFECT_LABELS.get(k, k)
		if k == "parry_focus":
			parts.append("%s +%d" % [label, roundi(v)])
		elif k == "status_resist":
			parts.append("%s +%d%%" % [label, roundi(v * 100.0)])
		else:
			parts.append("%s %s%d%%" % [label, "+" if v >= 1.0 else "-", roundi(absf(v - 1.0) * 100.0)])
	return ", ".join(parts)


static func equipped() -> Array:
	var out := []
	var raw = GameState.get_flag(&"tal_eq", [])
	if raw is Array:
		for id in raw:
			if TalismanData.DEFS.has(StringName(id)) and owned(StringName(id)) and not out.has(StringName(id)):
				out.append(StringName(id))
	return out


static func is_worn(id: StringName) -> bool:
	return equipped().has(id)


static func _save(list: Array) -> void:
	var raw := []
	for id in list:
		raw.append(String(id))
	GameState.set_flag(&"tal_eq", raw)
	Events.loadout_changed.emit()


## Wears or removes a talisman. Returns {"ok", "msg"}.
static func toggle(id: StringName) -> Dictionary:
	if not TalismanData.DEFS.has(id) or not owned(id):
		return {"ok": false, "msg": "You do not have that."}
	var cur := equipped()
	if cur.has(id):
		cur.erase(id)
		_save(cur)
		return {"ok": true, "msg": "Removed %s." % title(id)}
	if cur.size() >= SLOTS:
		return {"ok": false, "msg": "All %d slots are full. Remove one first." % SLOTS}
	cur.append(id)
	_save(cur)
	Audio.sfx(&"relic_equip", -4.0)
	return {"ok": true, "msg": "Wearing %s." % title(id)}


## Called when an enemy dies: bosses always drop theirs (once), elites sometimes drop one from the pool.
static func roll_drop(enemy: Node, data: EnemyData) -> void:
	var boss_id = enemy.get("boss_id")
	if boss_id != null and String(boss_id) != "":
		for id in TalismanData.IDS:
			if TalismanData.DEFS[id].source == StringName(boss_id) and not owned(id):
				_grant(id)
		return
	if data != null and data.elite and randf() < ELITE_DROP_CHANCE:
		var pool: Array = []
		for id in TalismanData.ELITE_POOL:
			if not owned(id):
				pool.append(id)
		if not pool.is_empty():
			_grant(pool[randi() % pool.size()])


static func _grant(id: StringName) -> void:
	if GameState.add_item(id, 1) > 0:
		Events.banner_requested.emit("TALISMAN  %s" % title(id).to_upper())
