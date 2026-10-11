extends Node
## Impact presentation: hit-stop, hit sparks and damage numbers.
## Kept separate from combat logic so feel can be tuned without touching rules.

const HitSpark := preload("res://fx/hit_spark.gd")
const DamageNumber := preload("res://fx/damage_number.gd")

const HIT_STOP_SCALE := 0.05

var _hit_stop_token := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Briefly slows the game on impact. A newer request supersedes an older one,
## so overlapping hits never stack into a long freeze.
func hit_stop(duration: float) -> void:
	if not Settings.hit_stop or duration <= 0.0:
		return
	_hit_stop_token += 1
	var token := _hit_stop_token
	Engine.time_scale = HIT_STOP_SCALE
	# ignore_time_scale = true so the timer runs in unscaled time.
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == _hit_stop_token:
		Engine.time_scale = 1.0


func shake(strength: float, duration := 0.18) -> void:
	if Settings.screen_shake <= 0.0:
		return
	Events.screen_shake_requested.emit(strength * Settings.screen_shake, duration)


func spark(at: Vector2, color: Color, amount := 10, direction := 0) -> void:
	var fx := HitSpark.new()
	fx.setup(color, amount, direction)
	_fx_parent().add_child(fx)
	fx.global_position = at


func damage_number(at: Vector2, amount: float, critical := false) -> void:
	var n := DamageNumber.new()
	n.setup(amount, critical)
	_fx_parent().add_child(n)
	n.global_position = at


func _fx_parent() -> Node:
	var layer := get_tree().get_first_node_in_group(&"fx_layer")
	return layer if layer else get_tree().root


## Clears any active hit-stop immediately (used on scene changes / tests).
func reset() -> void:
	_hit_stop_token += 1
	Engine.time_scale = 1.0
