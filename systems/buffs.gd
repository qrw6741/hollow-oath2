class_name Buffs
extends RefCounted
## Timed potion buffs. Runtime only: they run down while you play (not while paused), are
## cleared on death and when a game is started or loaded, and are never saved. The effects
## are read through Boosts. A potion is an item with ItemData.Effect.BUFF listed in DEFS.

const DEFS := {
	&"potion_might": {"title": "Might", "duration": 240.0, "effects": {"damage": 1.2}},
	&"potion_ward": {"title": "Ward", "duration": 240.0, "effects": {"damage_taken": 0.8}},
	&"potion_vigor": {"title": "Vigor", "duration": 300.0, "effects": {"max_health": 1.25}},
	&"potion_swift": {"title": "Swiftfoot", "duration": 180.0, "effects": {"run_speed": 1.15, "stamina_regen": 1.5}},
	&"potion_greed": {"title": "Embergreed", "duration": 300.0, "effects": {"ember_gain": 1.5}},
	&"potion_resolve": {"title": "Resolve", "duration": 240.0, "effects": {"status_resist": 0.5}},
	&"potion_focus": {"title": "Focus", "duration": 240.0, "effects": {"focus_gain": 1.5, "parry_focus": 8.0}},
}

static var active := {}     ## potion id -> seconds left


static func start(id: StringName) -> bool:
	if not DEFS.has(id):
		return false
	active[id] = float(DEFS[id].duration)
	Events.loadout_changed.emit()
	return true


static func is_active(id: StringName) -> bool:
	return active.has(id)


static func remaining(id: StringName) -> float:
	return float(active.get(id, 0.0))


static func clear() -> void:
	if active.is_empty():
		return
	active.clear()
	Events.loadout_changed.emit()


## Called every physics frame by the player.
static func tick(delta: float) -> void:
	if active.is_empty():
		return
	var ended := false
	for id in active.keys():
		active[id] = float(active[id]) - delta
		if float(active[id]) <= 0.0:
			active.erase(id)
			ended = true
	if ended:
		Events.loadout_changed.emit()


static func clock(seconds: float) -> String:
	var s := int(ceil(seconds))
	return "%d:%02d" % [s / 60, s % 60]
