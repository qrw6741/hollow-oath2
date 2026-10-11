@tool
class_name RuinsSilhouette
extends Node2D
## Procedural gothic skyline (spires, broken arches, dead trees) for parallax
## layers. One script, many looks: change seed, colour, height and density.
## TEMPORARY ART until hand-painted region backgrounds (Milestone 5).

@export var width := 2400.0:
	set(v): width = v; queue_redraw()
@export var base_y := 300.0:
	set(v): base_y = v; queue_redraw()
@export var max_height := 160.0:
	set(v): max_height = v; queue_redraw()
@export var color := Color("1b1820"):
	set(v): color = v; queue_redraw()
@export var window_color := Color(0, 0, 0, 0):
	set(v): window_color = v; queue_redraw()
@export var seed_value := 3:
	set(v): seed_value = v; queue_redraw()
@export var spacing := 70.0:
	set(v): spacing = maxf(10.0, v); queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# Ground mass.
	draw_rect(Rect2(-200, base_y, width + 400, 400), color)
	var x := -100.0
	while x < width + 100.0:
		var kind := rng.randi_range(0, 9)
		var h := rng.randf_range(0.3, 1.0) * max_height
		var w := rng.randf_range(18.0, 46.0)
		if kind <= 4:
			_spire(x, w, h, rng)
		elif kind <= 6:
			_arch(x, w * 1.6, h * 0.55)
		elif kind <= 8:
			_tree(x, h * 0.5, rng)
		x += spacing * rng.randf_range(0.6, 1.4)


func _spire(x: float, w: float, h: float, rng: RandomNumberGenerator) -> void:
	var top := base_y - h
	draw_rect(Rect2(x, top + h * 0.25, w, h * 0.75 + 1), color)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 2, top + h * 0.25 + 1), Vector2(x + w * 0.5, top - h * 0.35), Vector2(x + w + 2, top + h * 0.25 + 1)]), color)
	# Flanking pinnacles.
	for side in [x - 4.0, x + w]:
		draw_rect(Rect2(side, top + h * 0.4, 4, h * 0.6), color)
		draw_colored_polygon(PackedVector2Array([Vector2(side, top + h * 0.4), Vector2(side + 2, top + h * 0.25), Vector2(side + 4, top + h * 0.4)]), color)
	if window_color.a > 0.0:
		var wy := top + h * 0.4
		draw_rect(Rect2(x + w * 0.5 - 2, wy, 4, 8), window_color)
		draw_circle(Vector2(x + w * 0.5, wy), 2.0, window_color)
		if rng.randf() < 0.5:
			draw_circle(Vector2(x + w * 0.5, top + h * 0.15 + 4), 3.0, window_color)


func _arch(x: float, w: float, h: float) -> void:
	var top := base_y - h
	draw_rect(Rect2(x, top, 6, h + 1), color)
	draw_rect(Rect2(x + w - 6, top + h * 0.3, 6, h * 0.7 + 1), color)  # broken side
	draw_arc(Vector2(x + w * 0.5, top), w * 0.5 - 3, PI, PI * 1.6, 10, color, 6.0)


func _tree(x: float, h: float, rng: RandomNumberGenerator) -> void:
	var top := Vector2(x, base_y - h)
	draw_line(Vector2(x, base_y), top, color, 3.0)
	for i in 4:
		var y := base_y - h * rng.randf_range(0.4, 0.95)
		var dir := -1.0 if i % 2 == 0 else 1.0
		draw_line(Vector2(x, y), Vector2(x + dir * rng.randf_range(8, 18), y - rng.randf_range(6, 14)), color, 1.5)
