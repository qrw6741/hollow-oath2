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
	r.size = Vector2(70, 60)   ## generous: you should not have to stand on the exact pixel
	cs.shape = r
	cs.position = Vector2(0, -30)
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
	if Near.player(self): queue_redraw()
	if _player_inside and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact() and not Puzzle.is_on(lever_id):
		throw()


## Throws the lever (also callable from tests). Reports how many of the gate's wards are now lit.
func throw() -> void:
	if Puzzle.is_on(lever_id):
		return
	Puzzle.set_on(lever_id, seconds)
	Audio.sfx_at(&"door_open", global_position, -4.0, 1.5)
	GameFeel.spark(global_position + Vector2(0, -24), Color(0.7, 0.5, 1.0), 8)
	GameFeel.shake(1.5, 0.25)
	var tail := ""
	for g in get_tree().get_nodes_in_group(&"puzzle_gates"):
		if String(lever_id) in g.requires and not g.is_open():
			tail = "  (%d of %d wards lit)" % [g.lit_count(), g.requires.size()]
			break
	if seconds <= 0.0:
		Events.banner_requested.emit("The %s locks into place%s" % [display_name, tail])
	else:
		Events.banner_requested.emit("%s: %d seconds%s" % [display_name.capitalize(), int(seconds), tail])


func _draw() -> void:
	var on := Puzzle.is_on(lever_id) if not Engine.is_editor_hint() else false
	var iron := Color("3a363c")
	# a worked-stone pedestal with an iron plate and a slot for the arm
	draw_rect(Rect2(-14, -12, 28, 12), Palette.STONE_DARK)
	draw_rect(Rect2(-14, -12, 28, 3), Palette.STONE)
	draw_rect(Rect2(-10, -26, 20, 14), Palette.STONE_DARK.lightened(0.04))
	draw_rect(Rect2(-8, -24, 16, 3), iron.lightened(0.15))
	draw_circle(Vector2(0, -22), 4.5, iron.lightened(0.1))
	# the arm
	var ang := deg_to_rad(42.0 if on else -42.0)
	var base := Vector2(0, -22)
	var tip := base + Vector2.from_angle(ang - PI / 2.0) * 30.0
	draw_line(base, tip, iron.lightened(0.18), 4.0)
	draw_line(base, tip, Palette.STEEL_OXIDE, 2.0)
	var knob := Color(0.7, 0.45, 1.0) if on else Color(0.85, 0.2, 0.2)
	draw_circle(tip, 5.0, knob.darkened(0.3))
	draw_circle(tip, 3.4, knob)
	if on:
		draw_circle(tip, 14.0 + sin(_t * 5.0), Color(0.6, 0.35, 1.0, 0.18))
	else:
		# a faint pulse tells you the lever is waiting
		draw_circle(tip, 9.0 + 2.0 * sin(_t * 3.0), Color(0.9, 0.2, 0.2, 0.10))
	if seconds > 0.0 and on:
		var left := clampf((float(Puzzle._timed.get(lever_id, 0)) - Puzzle.now_ms()) / (seconds * 1000.0), 0.0, 1.0)
		draw_rect(Rect2(-14, -46, 28, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-13, -45, 26.0 * left, 2), Color(0.7, 0.5, 1.0) if left > 0.3 else Color(1.0, 0.4, 0.3))
