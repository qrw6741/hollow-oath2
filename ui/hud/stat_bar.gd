class_name StatBar
extends Control
## Resource bar with a delayed "damage trail" segment, Souls-style.

@export var fill_color := Palette.CRIMSON
@export var trail_color := Palette.GOLD
@export var back_color := Color(0.05, 0.04, 0.06, 0.85)
## Pixels per point of maximum (bars grow when the maximum grows).
@export var px_per_point := 1.0

var value := 100.0
var maximum := 100.0
var _trail := 100.0
var _trail_wait := 0.0


func set_values(v: float, m: float) -> void:
	if v < value:
		_trail_wait = 0.45
	else:
		_trail = maxf(_trail, v)
	value = v
	maximum = m
	custom_minimum_size.x = m * px_per_point + 4
	size.x = custom_minimum_size.x
	queue_redraw()


func _process(delta: float) -> void:
	if _trail_wait > 0.0:
		_trail_wait -= delta
	elif _trail > value:
		_trail = maxf(value, _trail - maximum * 0.9 * delta)
		queue_redraw()
	if _trail < value:
		_trail = value


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Palette.INK)
	draw_rect(Rect2(1, 1, w - 2, h - 2), back_color)
	var inner := w - 4
	var tr := clampf(_trail / maxf(maximum, 1.0), 0.0, 1.0)
	var vr := clampf(value / maxf(maximum, 1.0), 0.0, 1.0)
	if tr > vr:
		draw_rect(Rect2(2, 2, inner * tr, h - 4), trail_color)
	draw_rect(Rect2(2, 2, inner * vr, h - 4), fill_color)
	draw_rect(Rect2(2, 2, inner * vr, 1), fill_color.lightened(0.25))
	# Frame and ornamental end caps.
	draw_rect(Rect2(0, 0, w, h), Color(Palette.STONE_LIGHT, 0.9), false, 1.0)
	for x in [0.0, w]:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, h / 2.0), Vector2(x, h / 2.0 - 3), Vector2(x + 3, h / 2.0), Vector2(x, h / 2.0 + 3)]), Palette.GOLD)
