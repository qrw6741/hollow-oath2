class_name RuneStone
extends Area2D
## One stone of a sequence puzzle. Touch the stones in the order a tablet gives (each shows a glyph).
## A wrong stone puts every stone out again. When the last is lit the switch [member seq_id] turns on
## for good. [member index] is this stone's place in the correct order (0 = first).
## Origin = feet. TEMPORARY ART.

@export var seq_id: StringName = &"runes"
@export var index := 0
@export var total := 3
## Glyph: 0 moon, 1 eye, 2 hand, 3 flame, 4 crown, 5 skull.
@export_range(0, 5) var glyph := 0

var lit := false
var _player_inside: Player
var _t := 0.0


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 56)
	cs.shape = r
	cs.position = Vector2(0, -28)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	add_to_group(&"rune_stones")
	z_index = 2


func _on_enter(b: Node) -> void:
	if b is Player and not Puzzle.is_on(seq_id):
		_player_inside = b
		Events.interact_prompt_shown.emit("Touch the stone")


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _physics_process(delta: float) -> void:
	_t += delta
	if Near.player(self): queue_redraw()
	if Puzzle.is_on(seq_id):
		lit = true
		return
	if Puzzle.progress(seq_id) == 0:
		lit = false
	if _player_inside and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		touch()


func touch() -> void:
	if Puzzle.is_on(seq_id):
		return
	var p := Puzzle.progress(seq_id)
	if index == p:
		lit = true
		Puzzle.set_progress(seq_id, p + 1)
		Audio.sfx_at(&"skill_cast", global_position, -6.0, 0.8 + 0.15 * p)
		GameFeel.rise(global_position + Vector2(0, -20), Color(0.6, 0.35, 1.0), 8, 10.0)
		if p + 1 >= total:
			Puzzle.set_on(seq_id)
			Events.banner_requested.emit("The stones hum, and go quiet")
	else:
		Puzzle.set_progress(seq_id, 0)
		Audio.sfx_at(&"fizzle", global_position, -2.0)
		GameFeel.spark(global_position + Vector2(0, -24), Color(1.0, 0.3, 0.2), 10)
		Events.banner_requested.emit("The stones go dark")
		for s in get_tree().get_nodes_in_group(&"rune_stones"):
			if s.seq_id == seq_id:
				s.lit = false


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-13, 0), Vector2(-11, -48), Vector2(0, -54), Vector2(11, -48), Vector2(13, 0)]), Palette.STONE_DARK)
	draw_line(Vector2(-11, -48), Vector2(0, -54), Palette.STONE, 1.0)
	var col := Color(0.65, 0.4, 1.0) if lit else Color(0.4, 0.34, 0.48)
	var c := Vector2(0, -28)
	match glyph:
		0:
			draw_arc(c, 8.0, 0.9, 5.4, 12, col, 2.0)
		1:
			draw_arc(c, 8.0, PI + 0.4, TAU - 0.4, 8, col, 1.6)
			draw_arc(c, 8.0, 0.4, PI - 0.4, 8, col, 1.6)
			draw_circle(c, 2.4, col)
		2:
			for i in 5:
				draw_line(c + Vector2(0, 6), c + Vector2(-8 + i * 4, -8 - (2 - absf(i - 2)) * 1.5), col, 1.6)
		3:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, 8), c + Vector2(-3, -2), c + Vector2(0, -10), c + Vector2(3, -2), c + Vector2(6, 8)]), col)
		4:
			draw_polyline(PackedVector2Array([c + Vector2(-8, 7), c + Vector2(-8, -4), c + Vector2(-4, 1), c + Vector2(0, -8), c + Vector2(4, 1), c + Vector2(8, -4), c + Vector2(8, 7), c + Vector2(-8, 7)]), col, 1.8)
		5:
			draw_arc(c + Vector2(0, -2), 7.0, PI, TAU, 8, col, 1.8)
			draw_line(c + Vector2(-7, -2), c + Vector2(-5, 6), col, 1.8)
			draw_line(c + Vector2(7, -2), c + Vector2(5, 6), col, 1.8)
			draw_line(c + Vector2(-5, 6), c + Vector2(5, 6), col, 1.8)
			draw_circle(c + Vector2(-3, -1), 1.6, col)
			draw_circle(c + Vector2(3, -1), 1.6, col)
	if lit:
		draw_circle(c, 14.0 + sin(_t * 4.0), Color(0.6, 0.35, 1.0, 0.15))
