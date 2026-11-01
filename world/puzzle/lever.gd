class_name Lever
extends Area2D
## A lever. Press Interact to throw it. A permanent lever stays thrown (saved); a timed one springs back
## after [member seconds], so two far-apart timed levers make a run. Switch id = [member lever_id].
## Origin = feet. TEMPORARY ART.

@export var lever_id: StringName = &"lever"
@export var seconds := 0.0
@export var display_name := "lever"

var _player_inside: Player
var _t := 0.0


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(34, 44)
	cs.shape = r
	cs.position = Vector2(0, -22)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	z_index = 2


func _on_enter(b: Node) -> void:
	if b is Player:
		_player_inside = b
		Events.interact_prompt_shown.emit("Throw the %s" % display_name)


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _player_inside and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact() and not Puzzle.is_on(lever_id):
		Puzzle.set_on(lever_id, seconds)
		Audio.sfx_at(&"door_open", global_position, -4.0, 1.5)
		GameFeel.spark(global_position + Vector2(0, -24), Color(0.7, 0.5, 1.0), 8)
		Events.banner_requested.emit("The %s locks into place" % display_name if seconds <= 0.0 else "%s: you have %d seconds" % [display_name.capitalize(), int(seconds)])


func _draw() -> void:
	var on := Puzzle.is_on(lever_id) if not Engine.is_editor_hint() else false
	draw_rect(Rect2(-9, -8, 18, 8), Palette.STONE_DARK)
	draw_rect(Rect2(-9, -8, 18, 2), Palette.STONE)
	var ang := deg_to_rad(40.0 if on else -40.0)
	var tip := Vector2(0, -8) + Vector2.from_angle(ang - PI / 2.0) * 26.0
	draw_line(Vector2(0, -8), tip, Palette.STEEL_OXIDE, 3.0)
	draw_circle(tip, 3.6, Color(0.6, 0.35, 1.0) if on else Palette.CRIMSON_BRIGHT)
	if seconds > 0.0 and on:
		var left := clampf((float(Puzzle._timed.get(lever_id, 0)) - Time.get_ticks_msec()) / (seconds * 1000.0), 0.0, 1.0)
		draw_rect(Rect2(-12, -40, 24.0 * left, 3), Color(0.7, 0.5, 1.0))
