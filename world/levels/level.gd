class_name Level
extends Node2D
## Base script for every playable room/region scene.
## Spawns the player, owns camera bounds, and resets the room on rest/respawn.
## Milestone 8 extends this with room transitions and map registration.

@export var level_id: StringName = &"level"
@export var display_name := ""
## Defaults to the standard player scene when left empty.
@export var player_scene: PackedScene
## Camera limits in world pixels.
@export var bounds := Rect2(0, 0, 1920, 540)
## Looping music / ambience for this level (file in assets/audio/music/).
@export var music: StringName = &"yard"
@export var music_pitch := 1.0
## Where this level sits on the world map (map units = level pixels). Connected levels
## are placed so that their doors line up.
@export var map_origin := Vector2.ZERO
## Fallback spawn if no checkpoint has been rested at.
@export var default_spawn := Vector2(96, 470)

const PLAYER_SCENE_PATH := "res://actors/player/player.tscn"

var player: Player
var _explore_tick := 0


func _ready() -> void:
	add_to_group(&"level")
	if player_scene == null:
		player_scene = load(PLAYER_SCENE_PATH)
	player = player_scene.instantiate() as Player
	player.preset = Presets.get_preset(GameState.preset_id)
	player.position = spawn_position()
	add_child(player)
	_spawn_remnant()
	Audio.music(music, 1.2, music_pitch)
	Events.respawn_requested.connect(_on_respawn_requested)
	Events.checkpoint_rested.connect(_on_checkpoint_rested)
	if display_name != "":
		Events.banner_requested.emit.call_deferred(display_name)


func reset_enemies() -> void:
	for s in get_tree().get_nodes_in_group(&"enemy_spawners"):
		if is_ancestor_of(s):
			s.spawn()


func _on_checkpoint_rested(_id: StringName, _pos: Vector2) -> void:
	reset_enemies()


## Where the player appears when this level loads: the entry marker named by
## GameState.level_entry (arriving through an exit), else the last candle if it is in
## this level, else default_spawn.
func spawn_position() -> Vector2:
	if GameState.pending_spawn_level != "" and GameState.pending_spawn_level == scene_file_path:
		GameState.pending_spawn_level = ""
		return GameState.pending_spawn
	if GameState.level_entry != &"":
		var e := find_entry(GameState.level_entry)
		if e:
			return e.global_position
	if GameState.has_checkpoint and GameState.checkpoint_level_path() == scene_file_path:
		return GameState.respawn_position
	return default_spawn


func find_entry(id: StringName) -> Node2D:
	for e in get_tree().get_nodes_in_group(&"level_entries"):
		if is_ancestor_of(e) and e.get("entry_id") == id:
			return e
	return null


func _on_respawn_requested() -> void:
	GameState.level_entry = &""
	# The last candle is in another level: Main reloads that level and respawns there.
	if GameState.has_checkpoint and GameState.checkpoint_level_path() != scene_file_path:
		Events.level_change_requested.emit(GameState.checkpoint_level_path(), &"", true)
		return
	reset_enemies()
	var pos := GameState.respawn_position if GameState.has_checkpoint else default_spawn
	player.respawn_at(pos)
	_spawn_remnant()


## Places the recoverable stain of lost embers if it belongs to this level.
func _spawn_remnant() -> void:
	for r in get_tree().get_nodes_in_group(&"ember_remnant"):
		r.queue_free()
	var d: Dictionary = GameState.ember_drop
	if d.is_empty() or String(d.get("level_id", "")) != String(level_id):
		return
	var rem := EmberRemnant.new()
	rem.amount = int(d.get("amount", 0))
	rem.position = Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	add_child(rem)


## Reveals the map around the player a few times a second.
func _physics_process(_delta: float) -> void:
	_explore_tick += 1
	if _explore_tick % 8 != 0 or player == null or not is_instance_valid(player):
		return
	GameState.explore(String(level_id), WorldMap.cells_around(player.global_position, WorldMap.REVEAL_RADIUS))
