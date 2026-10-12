@tool
class_name ManorDoor
extends Area2D
## The door in Hollowmere's front hall that undoes the Hollowmere Sigil: Interact to step back
## to where you left. Origin = bottom centre. TEMPORARY ART (procedural).

var _player_inside: Player
var _t := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 32
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(40, 64)
	cs.shape = r
	cs.position = Vector2(0, -32)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(b: Node) -> void:
	if b is Player:
		_player_inside = b
		Events.interact_prompt_shown.emit("Step back through")


func _on_exit(b: Node) -> void:
	if b == _player_inside:
		_player_inside = null
		Events.interact_prompt_hidden.emit()


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if Engine.is_editor_hint() or _player_inside == null:
		return
	if Input.is_action_just_pressed(&"interact") and _player_inside.can_interact():
		var res := Manor.travel(_player_inside, true)
		if res.ok:
			Events.interact_prompt_hidden.emit()


func _draw() -> void:
	var glow := 0.6 + 0.4 * sin(_t * 1.6)
	draw_circle(Vector2(0, -34), 34.0, Color(0.7, 0.55, 0.95, 0.05 * glow))
	# Pointed arch
	var pts := PackedVector2Array([Vector2(-17, 0), Vector2(-17, -44), Vector2(-9, -58), Vector2(0, -64), Vector2(9, -58), Vector2(17, -44), Vector2(17, 0)])
	draw_colored_polygon(pts, Color(0.05, 0.04, 0.08))
	var out := pts.duplicate()
	out.append(pts[0])
	draw_polyline(out, Color("5c4630"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 0), Vector2(-12, -42), Vector2(0, -57), Vector2(12, -42), Vector2(12, 0)]), Color(0.55, 0.4, 0.8, 0.18 + 0.1 * glow))
	# A sigil mark hanging in the doorway
	draw_circle(Vector2(0, -30), 5.0, Color(0.72, 0.55, 0.9, 0.5 + 0.3 * glow))
	draw_line(Vector2(0, -34), Vector2(0, -26), Color(1, 1, 1, 0.5), 1.0)
	draw_line(Vector2(-3, -30), Vector2(3, -30), Color(1, 1, 1, 0.5), 1.0)
