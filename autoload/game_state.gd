extends Node
## Run-time world state: last rested checkpoint and the death -> respawn flow.
## Milestone 5 will extend this with a versioned save file (see docs/ARCHITECTURE.md).

const RESPAWN_DELAY := 2.6

var has_checkpoint := false
var checkpoint_id: StringName = &""
var respawn_position := Vector2.ZERO
var deaths := 0
var _respawn_pending := false


func _ready() -> void:
	Events.player_died.connect(_on_player_died)
	Events.checkpoint_rested.connect(_on_checkpoint_rested)


func _on_checkpoint_rested(id: StringName, pos: Vector2) -> void:
	has_checkpoint = true
	checkpoint_id = id
	respawn_position = pos


func _on_player_died() -> void:
	if _respawn_pending:
		return
	_respawn_pending = true
	deaths += 1
	await get_tree().create_timer(RESPAWN_DELAY, false).timeout
	_respawn_pending = false
	Events.respawn_requested.emit()


func reset() -> void:
	has_checkpoint = false
	checkpoint_id = &""
	respawn_position = Vector2.ZERO
	deaths = 0
	_respawn_pending = false
