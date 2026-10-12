@tool
class_name GraveyardProps
extends Node2D
## TEMPORARY ART (procedural): a mid-distance of leaning headstones, crosses, bare trees and
## an iron fence, drawn dark against the dusk. Parallax layer decoration only.

@export var width := 3400.0:
	set(v): width = v; queue_redraw()
@export var base_y := 262.0:
	set(v): base_y = v; queue_redraw()
@export var seed_value := 5:
	set(v): seed_value = v; queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var col := Color("141320")
	var fog := Color(0.45, 0.4, 0.58, 0.18)
	draw_rect(Rect2(-100, base_y, width + 200, 400), col)
	var x := 20.0
	while x < width:
		var k := rng.randi_range(0, 4)
		var h := rng.randf_range(14.0, 30.0)
		var lean := rng.randf_range(-0.12, 0.12)
		match k:
			0, 1:
				_stone(x, h, lean, col)
			2:
				_cross(x, h + 8.0, lean, col)
			3:
				_tree(x, rng, col)
			_:
				_fence(x, col)
		x += rng.randf_range(40.0, 110.0)
	draw_rect(Rect2(-100, base_y - 6, width + 200, 20), fog)


func _stone(x: float, h: float, lean: float, col: Color) -> void:
	var t := Transform2D(lean, Vector2(x, base_y))
	var pts := PackedVector2Array([Vector2(-6, 0), Vector2(-6, -h + 5), Vector2(-3, -h), Vector2(3, -h), Vector2(6, -h + 5), Vector2(6, 0)])
	var out := PackedVector2Array()
	for p in pts:
		out.append(t * p)
	draw_colored_polygon(out, col)


func _cross(x: float, h: float, lean: float, col: Color) -> void:
	var t := Transform2D(lean, Vector2(x, base_y))
	draw_line(t * Vector2(0, 0), t * Vector2(0, -h), col, 3.0)
	draw_line(t * Vector2(-6, -h * 0.7), t * Vector2(6, -h * 0.7), col, 3.0)


func _tree(x: float, rng: RandomNumberGenerator, col: Color) -> void:
	var h := rng.randf_range(50.0, 86.0)
	draw_line(Vector2(x, base_y), Vector2(x, base_y - h), col, 4.0)
	var n := rng.randi_range(3, 5)
	for i in n:
		var y := base_y - h * (0.35 + 0.65 * float(i) / n)
		var dir := -1.0 if i % 2 == 0 else 1.0
		var l := rng.randf_range(12.0, 26.0)
		draw_line(Vector2(x, y), Vector2(x + dir * l, y - l * 0.6), col, 2.0)
		draw_line(Vector2(x + dir * l, y - l * 0.6), Vector2(x + dir * l * 1.4, y - l * 1.1), col, 1.2)


func _fence(x: float, col: Color) -> void:
	for i in 6:
		var px := x + i * 8.0
		draw_line(Vector2(px, base_y), Vector2(px, base_y - 24.0), col, 1.6)
		draw_colored_polygon(PackedVector2Array([Vector2(px - 2, base_y - 24), Vector2(px, base_y - 29), Vector2(px + 2, base_y - 24)]), col)
	draw_line(Vector2(x - 2, base_y - 8), Vector2(x + 46, base_y - 8), col, 1.4)
