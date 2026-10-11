@tool
class_name LevelEntry
extends Marker2D
## Where the player appears when arriving through a LevelExit whose target_entry matches.

@export var entry_id: StringName = &"entry"


func _ready() -> void:
	add_to_group(&"level_entries")


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2(0, -12), 5, Color(0.3, 0.6, 1.0, 0.6))
