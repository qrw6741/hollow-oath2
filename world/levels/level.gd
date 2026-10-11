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
## Fallback spawn if no checkpoint has been rested at.
@export var default_spawn := Vector2(96, 470)

const PLAYER_SCENE_PATH := "res://actors/player/player.tscn"

var player: Player


func _ready() -> void:
	add_to_group(&"level")
	if player_scene == null:
		player_scene = load(PLAYER_SCENE_PATH)
	player = player_scene.instantiate() as Player
	player.preset = Presets.get_preset(GameState.preset_id)
	player.position = GameState.respawn_position if GameState.has_checkpoint else default_spawn
	add_child(player)
	_spawn_remnant()
	Audio.music(music)
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


func _on_respawn_requested() -> void:
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
