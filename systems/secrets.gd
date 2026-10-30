class_name Secrets
extends RefCounted
## Hidden places (illusory walls and floors, breakable walls). A found secret is a world flag
## `secret_<id>`, so saves need no new field. Finding enough of them earns a deed.

const NEEDED_FOR_DEED := 4


static func is_found(id: StringName) -> bool:
	return bool(GameState.get_flag(StringName("secret_" + String(id)), false))


static func record(id: StringName) -> void:
	if is_found(id):
		return
	GameState.set_flag(StringName("secret_" + String(id)), true)
	Events.banner_requested.emit("A SECRET")
	Audio.sfx(&"relic_equip", -2.0)
	Deeds.check_all()


static func record_silent(id: StringName) -> void:
	GameState.set_flag(StringName("secret_" + String(id)), true)
	Deeds.check_all()


static func count() -> int:
	var n := 0
	for k in GameState.flags:
		if String(k).begins_with("secret_") and bool(GameState.flags[k]):
			n += 1
	return n
