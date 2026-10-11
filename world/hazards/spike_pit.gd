@tool
class_name SpikePit
extends Area2D
## Environmental hazard: rusted penitent spikes. Hurts anything with a Hurtbox
## (player and enemies) and throws it upward. Dodge i-frames do not protect;
## post-hit invulnerability does, so a single fall is one hit.
## Origin = bottom-left; spikes grow upward by 10px over [member width].

@export var width := 48.0:
	set(v):
		width = maxf(8.0, v)
		_rebuild()
@export var damage := 20.0
@export var launch := Vector2(0, -330)

const REHIT_FRAMES := 30

var _shape: CollisionShape2D
var _cooldowns := {}


func _ready() -> void:
	add_to_group(&"hazards")
	collision_layer = 0
	collision_mask = 8 | 16   # player_hurtbox | enemy_hurtbox
	monitoring = true
	monitorable = false
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = get_node_or_null(^"Shape") as CollisionShape2D
		if _shape == null:
			_shape = CollisionShape2D.new()
			_shape.name = &"Shape"
			add_child(_shape)
	var r := RectangleShape2D.new()
	r.size = Vector2(width, 8)
	_shape.shape = r
	_shape.position = Vector2(width * 0.5, -4)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for id in _cooldowns.keys():
		_cooldowns[id] -= 1
		if _cooldowns[id] <= 0:
			_cooldowns.erase(id)
	for a in get_overlapping_areas():
		if a is Hurtbox and not _cooldowns.has(a.get_instance_id()):
			var hit := HitData.make(damage, self, launch)
			hit.environmental = true
			hit.parryable = false
			if (a as Hurtbox).receive_hit(hit) == HitData.Result.HIT:
				_cooldowns[a.get_instance_id()] = REHIT_FRAMES


func _draw() -> void:
	var x := 0.0
	var i := 0
	while x < width:
		var h := 9.0 if i % 2 == 0 else 7.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 3, -h), Vector2(x + 6, 0)]), Palette.RUST)
		draw_line(Vector2(x + 3, -h), Vector2(x + 4.5, -h * 0.4), Palette.STEEL_OXIDE, 1.0)
		x += 6.0
		i += 1
	draw_rect(Rect2(0, -2, width, 2), Color(Palette.CRIMSON, 0.6))
