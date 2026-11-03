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
## Passed to enemies that keep a saved per-instance flag (e.g. a slain Mimic).
@export var spawn_id: StringName = &""
## When this enemy walks the world: always, only by day, or only at night (see DayNight).
@export_enum("Always:0", "Day only:1", "Night only:2") var when := 0

## Long levels stream their enemies: the foe is only built while the player is within [member wake_range]
## (px, horizontally) and put away again when they are far behind. A killed foe stays dead until the world resets.
@export var stream := false
@export var wake_range := 1500.0
@export var sleep_range := 2300.0

var enemy: EnemyBase
var _dead := false
var _poll := 0


func _ready() -> void:
	add_to_group(&"enemy_spawners")
	if not Engine.is_editor_hint():
		spawn.call_deferred()
		if when != 0:
			Events.daynight_changed.connect(_on_daynight)


func _physics_process(_delta: float) -> void:
	if not stream or Engine.is_editor_hint():
		return
	_poll -= 1
	if _poll > 0:
		return
	_poll = 20
	var p := get_tree().get_first_node_in_group(&"player") as Node2D
	if p == null:
		return
	var dx := absf(p.global_position.x - global_position.x)
	if is_instance_valid(enemy):
		if dx > sleep_range and enemy.state in [EnemyBase.State.IDLE, EnemyBase.State.PATROL, EnemyBase.State.RETURN] and not enemy.is_dead():
			enemy.queue_free()
			enemy = null
	elif not _dead and dx < wake_range:
		_make()


func _in_season() -> bool:
	return when == 0 or (when == 2) == DayNight.is_night()


func _on_daynight(_night: bool) -> void:
	if _in_season():
		if not is_instance_valid(enemy):
			spawn()
	elif is_instance_valid(enemy) and enemy.state in [EnemyBase.State.IDLE, EnemyBase.State.PATROL, EnemyBase.State.RETURN]:
		GameFeel.spark(enemy.global_position + Vector2(0, -16), Palette.DUST, 10)
		enemy.queue_free()


func spawn() -> void:
	if enemy_scene == null:
		push_warning("EnemySpawner %s has no scene" % name)
		return
	if is_instance_valid(enemy):
		enemy.queue_free()
	enemy = null
	_dead = false
	if not _in_season():
		return
	if stream:
		var p := get_tree().get_first_node_in_group(&"player") as Node2D
		if p == null or absf(p.global_position.x - global_position.x) >= wake_range:
			return
	_make()


func _make() -> void:
	if not _in_season():
		return
	enemy = enemy_scene.instantiate() as EnemyBase
	if data_override:
		enemy.data = data_override
	enemy.patrol_distance = patrol_distance
	enemy.start_facing = start_facing
	enemy.position = position
	if spawn_id != &"" and &"spawn_id" in enemy:
		enemy.set(&"spawn_id", spawn_id)
	enemy.died.connect(func(_e): _dead = true)
	get_parent().add_child(enemy)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2(0, -12), 6, Color(0.8, 0.2, 0.2, 0.6))
		draw_line(Vector2(-patrol_distance, 0), Vector2(patrol_distance, 0), Color(0.8, 0.2, 0.2, 0.6), 1.0)
