@tool
class_name EnemySpawner
extends Marker2D
## Places an enemy and re-creates it whenever the world resets
## (player rests at a checkpoint or respawns after death).
## Bosses will use a variant that checks GameState for a persistent "defeated" flag.

@export var enemy_scene: PackedScene
@export var data_override: EnemyData
@export var patrol_distance := 56.0
@export_enum("Left:-1", "Right:1") var start_facing := -1

var enemy: EnemyBase


func _ready() -> void:
	add_to_group(&"enemy_spawners")
	if not Engine.is_editor_hint():
		spawn.call_deferred()


func spawn() -> void:
	if enemy_scene == null:
		push_warning("EnemySpawner %s has no scene" % name)
		return
	if is_instance_valid(enemy):
		enemy.queue_free()
	enemy = enemy_scene.instantiate() as EnemyBase
	if data_override:
		enemy.data = data_override
	enemy.patrol_distance = patrol_distance
	enemy.start_facing = start_facing
	enemy.position = position
	get_parent().add_child(enemy)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2(0, -12), 6, Color(0.8, 0.2, 0.2, 0.6))
		draw_line(Vector2(-patrol_distance, 0), Vector2(patrol_distance, 0), Color(0.8, 0.2, 0.2, 0.6), 1.0)
