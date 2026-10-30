@tool
class_name IllusoryWall
extends Area2D
## A false wall or floor: it looks like solid masonry but has no collision. Walking into it
## dissolves the illusion and counts as a found secret (world flag `secret_<id>`). Once found
## it stays faintly see-through. Origin = top-left. TEMPORARY ART.

@export var size := Vector2(16, 60):
	set(v): size = v; queue_redraw()
@export var secret_id: StringName = &"secret"
@export var floor_style := false:
	set(v): floor_style = v; queue_redraw()

var _fade := 0.0
var _found := false


func _ready() -> void:
	z_index = 2
	if Engine.is_editor_hint():
		return
	_found = Secrets.is_found(secret_id)
	_fade = 0.65 if _found else 0.0
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = size / 2.0
	add_child(cs)
	body_entered.connect(_on_enter)


func _on_enter(b: Node) -> void:
	if b is Player and not _found:
		_found = true
		Secrets.record(secret_id)
		GameFeel.spark(global_position + size / 2.0, Palette.DUST, 18)
		Audio.sfx_at(&"gate_open", global_position + size / 2.0, -6.0, 1.6)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var want := 0.65 if _found else 0.0
	if _fade != want:
		_fade = move_toward(_fade, want, delta * 2.5)
		queue_redraw()


func _draw() -> void:
	var a := 1.0 - _fade
	if a <= 0.02:
		return
	var base := Color(Palette.STONE_DARK, a)
	draw_rect(Rect2(Vector2.ZERO, size), base)
	var row_h := 8.0
	var y := 0.0
	var i := 0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(Palette.INK, a * 0.8), 1.0)
		var off := 6.0 if i % 2 == 0 else 14.0
		var x := off
		while x < size.x:
			draw_line(Vector2(x, y), Vector2(x, minf(y + row_h, size.y)), Color(Palette.INK, a * 0.8), 1.0)
			x += 16.0
		y += row_h
		i += 1
	draw_rect(Rect2(0, 0, size.x, 1), Color(Palette.STONE_LIGHT, a * 0.5))
