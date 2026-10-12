class_name Manor
extends RefCounted
## Hollowmere Manor, the old haunted house where the road's important people gather, and the
## Hollowmere Sigil that reaches it. Using the sigil anywhere saves where you stood and carries
## you to the manor's front hall; using it in the manor carries you back to that exact spot.
## It is a reusable key and is never consumed.

const PATH := "res://world/levels/hollowmere_manor.tscn"
const FROM_FLAG := &"sigil_from"
const SIGIL := &"hollow_sigil"


static func in_manor() -> bool:
	return GameState.level_path == PATH


## {"ok": bool, "msg": String}: whether the oath lets the player leave right now.
static func can_travel(player: Player, need_sigil := true) -> Dictionary:
	if player == null or player.is_dead():
		return {"ok": false, "msg": "Not now."}
	if need_sigil and GameState.item_count(SIGIL) <= 0:
		return {"ok": false, "msg": "You have no sigil."}
	var tree := player.get_tree()
	for b in tree.get_nodes_in_group(&"bosses"):
		if b.get("active") == true and not b.is_dead():
			return {"ok": false, "msg": "The oath will not let you leave this fight."}
	return {"ok": true, "msg": ""}


## [param by_door]: the manor's own door always lets you leave, sigil or not.
static func travel(player: Player, by_door := false) -> Dictionary:
	var c := can_travel(player, not by_door)
	if not c.ok:
		return c
	if in_manor():
		var from: Dictionary = GameState.get_flag(FROM_FLAG, {})
		var path := String(from.get("level", ""))
		if path == "" or not path.begins_with("res://world/levels/") or not ResourceLoader.exists(path):
			path = GameState.checkpoint_level_path()
			GameState.pending_spawn_level = ""
		else:
			GameState.pending_spawn_level = path
			GameState.pending_spawn = Vector2(float(from.get("x", 0.0)), float(from.get("y", 0.0)))
		GameState.level_entry = &""
		Events.teleport_requested.emit(path, &"")
		return {"ok": true, "msg": "Back to the road."}
	GameState.set_flag(FROM_FLAG, {"level": GameState.level_path, "x": player.global_position.x, "y": player.global_position.y})
	Events.teleport_requested.emit(PATH, &"arrival")
	return {"ok": true, "msg": "Hollowmere."}
