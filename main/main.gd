extends Node
## Persistent game root. Holds the camera, HUD, pause menu and FX layer,
## and swaps level scenes in and out of [code]World[/code].

@export var start_level: PackedScene

@onready var world: Node2D = $World


func _ready() -> void:
	if start_level:
		load_level(start_level)


func load_level(scene: PackedScene) -> Level:
	GameFeel.reset()
	for c in world.get_children():
		if c is Level:
			c.queue_free()
	var lvl := scene.instantiate() as Level
	world.add_child(lvl)
	world.move_child(lvl, 0)
	return lvl


func current_level() -> Level:
	for c in world.get_children():
		if c is Level and not c.is_queued_for_deletion():
			return c
	return null
