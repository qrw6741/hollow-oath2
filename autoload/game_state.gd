extends Node
## Run-time session state: which save slot is active, last rested checkpoint,
## play time, world flags, and the death -> respawn flow.
## [method to_dict] / [method apply_dict] are the only bridge to the save file;
## SaveSystem owns files, GameState owns what goes in them.

const RESPAWN_DELAY := 2.6
const DEFAULT_LEVEL_PATH := "res://world/levels/test_arena.tscn"

## True while a game session (not the main menu) is running.
var in_game := false
## Active save slot (1-based). 0 = no slot: the session is never autosaved (tests, dev runs).
var current_slot := 0

var level_path := DEFAULT_LEVEL_PATH
var level_name := ""
var has_checkpoint := false
var checkpoint_id: StringName = &""
var respawn_position := Vector2.ZERO
var deaths := 0
var play_time := 0.0
## Persistent world flags (boss defeated, shortcut opened, NPC met...). Values must be JSON-safe.
var flags := {}

## Incremented whenever the session is replaced, so stale timers (a pending respawn
## from a previous session) can recognise themselves and do nothing.
var session_id := 0
var _respawn_pending := false


func _ready() -> void:
	Events.player_died.connect(_on_player_died)
	Events.checkpoint_rested.connect(_on_checkpoint_rested)


func _process(delta: float) -> void:
	if in_game:
		# Hit-stop slows time_scale; play time should still track real time.
		play_time += delta / maxf(Engine.time_scale, 0.01)


func _on_checkpoint_rested(id: StringName, pos: Vector2) -> void:
	has_checkpoint = true
	checkpoint_id = id
	respawn_position = pos


func _on_player_died() -> void:
	if _respawn_pending:
		return
	_respawn_pending = true
	deaths += 1
	var sid := session_id
	await get_tree().create_timer(RESPAWN_DELAY, false).timeout
	if sid != session_id:
		return  # The session ended (quit to menu / new game) while we waited.
	_respawn_pending = false
	Events.respawn_requested.emit()


# ------------------------------------------------------------------ flags

func set_flag(flag: StringName, value: Variant = true) -> void:
	flags[String(flag)] = value


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(String(flag), default)


# ------------------------------------------------------------------ sessions

## Clears everything. Also used by tests.
func reset() -> void:
	in_game = false
	current_slot = 0
	level_path = DEFAULT_LEVEL_PATH
	level_name = ""
	has_checkpoint = false
	checkpoint_id = &""
	respawn_position = Vector2.ZERO
	deaths = 0
	play_time = 0.0
	flags = {}
	session_id += 1
	_respawn_pending = false


func new_game(slot: int) -> void:
	reset()
	current_slot = slot


## Serialisable snapshot of durable state. No transient combat state, ever.
func to_dict() -> Dictionary:
	return {
		"play_time": play_time,
		"deaths": deaths,
		"level_path": level_path,
		"level_name": level_name,
		"has_checkpoint": has_checkpoint,
		"checkpoint_id": String(checkpoint_id),
		"respawn_position": [respawn_position.x, respawn_position.y],
		"flags": flags.duplicate(true),
	}


## Loads a dictionary produced by SaveSystem (already validated/normalised).
func apply_dict(d: Dictionary, slot: int) -> void:
	reset()
	current_slot = slot
	play_time = float(d.get("play_time", 0.0))
	deaths = int(d.get("deaths", 0))
	level_path = String(d.get("level_path", DEFAULT_LEVEL_PATH))
	level_name = String(d.get("level_name", ""))
	has_checkpoint = bool(d.get("has_checkpoint", false))
	checkpoint_id = StringName(d.get("checkpoint_id", ""))
	var p: Array = d.get("respawn_position", [0.0, 0.0])
	respawn_position = Vector2(float(p[0]), float(p[1]))
	flags = (d.get("flags", {}) as Dictionary).duplicate(true)
