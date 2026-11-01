class_name ChainedElder
extends Area2D
## The old man in the basement: lying on the grass in chains. Press Interact to wake him ([signal woken]).
## While [member glow] rises his mouth, eyes and spine shine white; [member shout] opens the mouth wide.
## Origin = floor point under him. TEMPORARY ART: drawn in code.

signal woken

var glow := 0.0       ## 0..1: the light in the mouth, eyes and spine
var shout := 0.0      ## 0..1: the mouth opens (a scream)
var sitting := 0.0    ## 0 lying, 1 sitting up
var shake := 0.0
var _player_inside: Player
var _t := 0.0
var _used := false


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(90, 40)
	cs.shape = r
	cs.position = Vector2(0, -20)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	z_index = 2


func _on_enter(b: Node) -> void:
	if b is Player and not _used:
		_player_inside = b
		Events.interact_prompt_shown.emit("Wake the old man")


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if not _used and _player_inside and Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		_used = true
		Events.interact_prompt_hidden.emit()
		woken.emit()


func _draw() -> void:
	var sh := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	var skin := Color("d2b08e")
	var skin_d := Color("a98568")
	var rag := Color("5e5043")
	var rag_d := Color("3f352c")
	var hair := Color("ece8e0")
	var hair_d := Color("b8b4ac")
	var chain := Color("7a7a86")
	var iron := Color("4a4a54")
	var rise := sitting * 20.0
	# grass flattened under him
	draw_colored_polygon(PackedVector2Array([Vector2(-46, 1), Vector2(-40, -3), Vector2(40, -3), Vector2(48, 1)]), Color(0.1, 0.22, 0.08, 0.6))
	# legs: thin, bare shins and bound ankles
	draw_line(Vector2(8, -6) + sh, Vector2(36, -2), rag_d, 7.0)
	draw_line(Vector2(34, -3) + sh, Vector2(42, -1), skin_d, 4.0)
	draw_line(Vector2(6, -8) + sh, Vector2(32, -5), rag, 7.0)
	draw_line(Vector2(30, -6) + sh, Vector2(39, -4), skin, 4.0)
	draw_rect(Rect2(33, -8, 3, 7), iron)   # ankle shackle
	# torso in a tattered robe, propped on one arm when sitting
	var chest := Vector2(-14, -10 - rise * 0.6) + sh
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -4) + sh, Vector2(-22, -14 - rise) + sh, Vector2(-8, -19 - rise) + sh, Vector2(10, -14) + sh, Vector2(12, -4) + sh]), rag)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -19 - rise) + sh, Vector2(10, -14) + sh, Vector2(12, -9) + sh, Vector2(-4, -13 - rise * 0.5) + sh]), rag_d)
	draw_line(Vector2(-2, -4) + sh, Vector2(14, -2), rag_d, 1.2)   # a torn hem
	# arms: one reaching out in the chain, one braced
	var hand_a := Vector2(-4, -2) + sh + Vector2(0, -rise * 0.1)
	draw_line(chest + Vector2(10, 0), hand_a, skin, 3.4)
	draw_circle(hand_a, 2.3, skin_d)
	draw_circle(hand_a + Vector2(0, -0.5), 3.4, Color(iron, 0.0))
	draw_arc(hand_a, 3.4, 0, TAU, 8, iron, 1.4)   # wrist shackle
	var hand_b := Vector2(-30, -2) + sh
	draw_line(chest + Vector2(-8, 2), hand_b, skin_d, 3.0)
	draw_circle(hand_b, 2.2, skin_d)
	# head: bald crown, hollow cheeks, a long white beard and brows
	var hp := Vector2(-28, -22 - rise) + sh
	draw_circle(hp, 8.5, skin)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-6, -3), hp + Vector2(-9, 4), hp + Vector2(-3, 8), hp + Vector2(2, 2)]), skin_d)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-8, 1), hp + Vector2(-9, 10), hp + Vector2(-5, 20), hp + Vector2(0, 14), hp + Vector2(5, 8), hp + Vector2(6, 2)]), hair)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-5, 8), hp + Vector2(-5, 20), hp + Vector2(0, 14)]), hair_d)
	draw_colored_polygon(PackedVector2Array([hp + Vector2(-8, -3), hp + Vector2(-9, 3), hp + Vector2(-6, -1)]), hair)
	draw_line(hp + Vector2(0, -4.5), hp + Vector2(6, -3.5), hair, 1.8)        # brow
	draw_line(hp + Vector2(1, 0), hp + Vector2(3, 3), skin_d, 1.2)             # nose
	var eye_col := Color(0.15, 0.1, 0.1).lerp(Color(1.0, 1.0, 0.9), glow)
	var eye_open := 0.4 + minf(sitting * 1.6, 1.0) * 0.9 + glow * 1.2
	draw_circle(hp + Vector2(2, -1.5), eye_open, eye_col)
	draw_circle(hp + Vector2(6.5, -1.5), eye_open * 0.9, eye_col)
	var mouth := 0.8 + shout * 7.0
	draw_colored_polygon(PackedVector2Array([hp + Vector2(0, 5), hp + Vector2(5.5, 5), hp + Vector2(5, 5 + mouth), hp + Vector2(1, 5 + mouth)]), Color(1.0, 0.95, 0.8) if glow > 0.3 else Color("2a1210"))
	# chains from the shackles into the grass
	for pr in [[hand_a, Vector2(10, 2)], [hand_b, Vector2(-44, 2)], [Vector2(34, -4) + sh, Vector2(52, 2)]]:
		var from: Vector2 = pr[0]
		var to: Vector2 = pr[1]
		for i in 7:
			var k := float(i) / 6.0
			var pt: Vector2 = from.lerp(to, k) + Vector2(0, sin(k * PI) * 3.0)
			draw_circle(pt, 1.6, chain)
			draw_circle(pt, 0.8, iron)
		draw_rect(Rect2(to.x - 2, to.y - 1, 4, 3), iron)
	# the light: spine, eyes, mouth
	if glow > 0.01:
		var spine_a := Vector2(-22, -14 - rise * 0.9) + sh
		var spine_b := Vector2(10, -10 - rise * 0.2) + sh
		draw_line(spine_a, spine_b, Color(1, 1, 0.9, glow), 2.0 + glow * 3.0)
		draw_line(spine_a, spine_b, Color(1.0, 0.8, 0.4, glow * 0.4), 8.0 + glow * 8.0)
		for src in [hp + Vector2(2, -1.5), hp + Vector2(6.5, -1.5), hp + Vector2(3, 7)]:
			draw_line(src, src + Vector2(0, -160.0 * glow), Color(1.0, 0.95, 0.8, glow * 0.7), 1.5 + glow * 4.0)
			draw_circle(src, 4.0 + glow * 10.0, Color(1.0, 0.9, 0.6, glow * 0.35))
		draw_line(spine_a + Vector2(0, -2), spine_a + Vector2(0, -120.0 * glow), Color(1.0, 0.9, 0.6, glow * 0.6), 2.0 + glow * 5.0)
