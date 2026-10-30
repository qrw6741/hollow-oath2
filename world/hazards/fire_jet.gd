@tool
class_name FireJet
extends Area2D
## A cracked brazier-pipe that vents flame on a rhythm: a pilot flicker, then a bright warning
## (sparks, a glow), then a column of fire. Burns the player and enemies alike; dodge i-frames do
## not protect, so time the run. Origin = bottom centre; the column grows upward.
## TEMPORARY ART.

@export var column := Vector2(14, 56)
@export var damage := 18.0
@export var period := 3.0
@export var warn_time := 0.8
@export var burst_time := 0.5
## Seconds into the cycle at start, so neighbouring jets can alternate.
@export var phase := 0.0
@export var burn_amount := 35.0

var _t := 0.0
var _cooldowns := {}
var _was_bursting := false


func _ready() -> void:
	add_to_group(&"hazards")
	_t = phase
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 8 | 16
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = column
	cs.shape = r
	cs.position = Vector2(0, -column.y / 2.0)
	add_child(cs)


func is_bursting() -> bool:
	return fmod(_t, period) >= period - burst_time


func is_warning() -> bool:
	var m := fmod(_t, period)
	return m >= period - burst_time - warn_time and m < period - burst_time


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if Engine.is_editor_hint():
		return
	for id in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	var b := is_bursting()
	if b and not _was_bursting:
		Audio.sfx_at(&"fx_burn", global_position, -4.0, 0.8)
	_was_bursting = b
	if not b:
		return
	for a in get_overlapping_areas():
		if a is Hurtbox and not _cooldowns.has(a.get_instance_id()):
			var hit := HitData.make(damage, self, Vector2(0, -160))
			hit.environmental = true
			hit.parryable = false
			hit.status = &"burn"
			hit.status_amount = burn_amount
			if (a as Hurtbox).receive_hit(hit) == HitData.Result.HIT:
				_cooldowns[a.get_instance_id()] = 0.6


func _draw() -> void:
	draw_rect(Rect2(-5, -3, 10, 3), Palette.STEEL_OXIDE)
	draw_rect(Rect2(-3, -4, 6, 1.5), Palette.INK)
	var flick := 1.0 + 0.4 * sin(_t * 18.0)
	draw_circle(Vector2(0, -5), 1.2 * flick, Color(1.0, 0.55, 0.15, 0.8))
	if is_warning():
		var m := fmod(_t, period) - (period - burst_time - warn_time)
		var k := m / warn_time
		draw_circle(Vector2(0, -6), 3.0 + k * 5.0, Color(1.0, 0.5, 0.15, 0.25 + 0.3 * k))
		for i in 4:
			var sy := -6.0 - fmod(m * 40.0 + i * 9.0, 20.0)
			draw_circle(Vector2(sin(m * 20.0 + i) * 3.0, sy), 0.9, Color(1.0, 0.8, 0.4, 0.8))
	elif is_bursting():
		var m2 := fmod(_t, period) - (period - burst_time)
		var h := column.y * clampf(m2 / 0.12, 0.0, 1.0) * clampf((burst_time - m2) / 0.15 + 0.4, 0.0, 1.0)
		var w := column.x
		draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0, -2), Vector2(-w / 3.0, -h * 0.7), Vector2(0, -h), Vector2(w / 3.0, -h * 0.7), Vector2(w / 2.0, -2)]), Color(1.0, 0.35, 0.1, 0.85))
		draw_colored_polygon(PackedVector2Array([Vector2(-w / 4.0, -2), Vector2(0, -h * 0.75), Vector2(w / 4.0, -2)]), Color(1.0, 0.85, 0.4, 0.95))
