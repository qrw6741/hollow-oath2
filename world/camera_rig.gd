class_name CameraRig
extends Camera2D
## Follows the player with facing look-ahead and frame-rate independent smoothing.
## Screen shake is applied as an offset so it never fights the smoothing.

@export var follow_speed := 7.0
@export var lookahead := 36.0
@export var lookahead_speed := 3.0
@export var vertical_offset := -28.0

var _target: Node2D
var _look := 0.0
var _shake := 0.0
var _shake_time := 0.0
var _shake_dur := 0.0
var _noise := FastNoiseLite.new()
var _nt := 0.0


func _ready() -> void:
	_noise.frequency = 0.8
	Events.screen_shake_requested.connect(_on_shake)
	Events.player_spawned.connect(_on_target)
	Events.player_respawned.connect(_on_target)
	var lvl := get_tree().get_first_node_in_group(&"level") as Level
	if lvl:
		apply_bounds(lvl.bounds)


func apply_bounds(r: Rect2) -> void:
	limit_left = int(r.position.x)
	limit_top = int(r.position.y)
	limit_right = int(r.end.x)
	limit_bottom = int(r.end.y)


func _on_target(p: Node2D) -> void:
	_target = p
	var lvl := get_tree().get_first_node_in_group(&"level") as Level
	if lvl:
		apply_bounds(lvl.bounds)
	snap()


func snap() -> void:
	if _target:
		global_position = _desired()
		reset_smoothing()


func _desired() -> Vector2:
	return _target.global_position + Vector2(_look, vertical_offset)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var facing: int = _target.get(&"facing") if _target.get(&"facing") != null else 1
	_look = lerpf(_look, facing * lookahead, 1.0 - exp(-lookahead_speed * delta))
	global_position = global_position.lerp(_desired(), 1.0 - exp(-follow_speed * delta))
	_update_shake(delta)


func _on_shake(strength: float, duration: float) -> void:
	if strength >= _shake * maxf(0.0, 1.0 - _shake_time / maxf(_shake_dur, 0.001)):
		_shake = strength
		_shake_dur = duration
		_shake_time = 0.0


func _update_shake(delta: float) -> void:
	if _shake <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time += delta
	var k := 1.0 - _shake_time / _shake_dur
	if k <= 0.0:
		_shake = 0.0
		offset = Vector2.ZERO
		return
	_nt += delta * 60.0
	offset = Vector2(_noise.get_noise_2d(_nt, 0.0), _noise.get_noise_2d(0.0, _nt)) * _shake * k * 2.0
